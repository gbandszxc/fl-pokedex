/// 进化树纯逻辑（可单测）：compact 纵向展开、expanded 横向布局坐标计算，
/// 以及进化边 → 条件文案的映射。
///
/// 文案原则（诚实显示）：有官方简中译名把握的标识符给中文；
/// 没有把握的一律英文美化（`sacred-ash` → `Sacred Ash`），禁止编造。
library;

import '../../domain/models/evolution.dart';
import '../../shared/widgets/type_badge.dart' show kTypeNamesZh;

/// compact 纵向树的一行（先序：根在前，逐层缩进）。
class EvolutionRow {
  const EvolutionRow({
    required this.node,
    required this.depth,
    required this.guides,
    required this.isLastChild,
    this.edgeFromParent,
  });

  final EvolutionNode node;

  /// 根为 0，每往下一层 +1。
  final int depth;

  /// 到父节点的边（根为 null）。
  final EvolutionEdge? edgeFromParent;

  /// 各祖先层级（0..depth-2）的「是否末位子节点」标记；
  /// 末位子节点之下的竖线不再向下延伸（└ 语义）。
  final List<bool> guides;

  /// 本节点是否为其父节点的最后一个子节点（├ vs └）。
  final bool isLastChild;
}

/// 该节点的可用出边：目标在注册表内且未访问过（环路数据安全）。
List<EvolutionEdge> _childEdges(
  EvolutionTree tree,
  EvolutionNode node,
  Set<int> visited,
) =>
    [
      for (final edge in node.children)
        if (!visited.contains(edge.toSpeciesId))
          if (tree.nodesBySpeciesId[edge.toSpeciesId] != null) edge,
    ];

/// 先序展开整棵树，供 compact 纵向树逐行渲染。
List<EvolutionRow> flattenEvolutionTree(EvolutionTree tree) {
  final rows = <EvolutionRow>[];
  final visited = <int>{};

  void visit(
    EvolutionNode node,
    int depth,
    EvolutionEdge? edge,
    List<bool> guides,
    bool isLast,
  ) {
    if (!visited.add(node.speciesId)) return;
    rows.add(EvolutionRow(
      node: node,
      depth: depth,
      edgeFromParent: edge,
      guides: List.unmodifiable(guides),
      isLastChild: isLast,
    ));
    final childEdges = _childEdges(tree, node, visited);
    for (var i = 0; i < childEdges.length; i++) {
      final child = tree.nodesBySpeciesId[childEdges[i].toSpeciesId]!;
      visit(
        child,
        depth + 1,
        childEdges[i],
        [...guides, i == childEdges.length - 1],
        i == childEdges.length - 1,
      );
    }
  }

  visit(tree.root, 0, null, const <bool>[], true);
  return rows;
}

/// expanded 横向树中一个节点的摆放结果。
class EvolutionNodePlacement {
  const EvolutionNodePlacement({
    required this.node,
    required this.edgeFromParent,
    required this.x,
    required this.y,
  });

  final EvolutionNode node;

  /// 到父节点的边（根为 null，连接线据此绘制）。
  final EvolutionEdge? edgeFromParent;

  /// 画布坐标（节点卡片中心）。
  final double x;
  final double y;
}

/// expanded 横向树的完整画布。
class EvolutionCanvasLayout {
  const EvolutionCanvasLayout({
    required this.placements,
    required this.width,
    required this.height,
    required this.viewportHeight,
  });

  final List<EvolutionNodePlacement> placements;

  /// 画布全宽（InteractiveViewer 子节点的宽）。
  final double width;

  /// 画布全高（InteractiveViewer 子节点的高，可超出视口平移查看）。
  final double height;

  /// 外层视口高：按叶数在 320~420 内截断（design-ui.md §5）。
  final double viewportHeight;
}

/// expanded 横向树布局（design-ui.md §5）：
/// x = 深度 × (节点宽 + 列距)；子树高后序分配（叶 = 1 行，
/// 内部节点 = Σ子树行），节点在其子树行区间内垂直居中。
EvolutionCanvasLayout layoutEvolutionCanvas(
  EvolutionTree tree, {
  double nodeWidth = 120,
  double columnGap = 80,
  double rowHeight = 136,
  double padding = 16,
  double minViewportHeight = 320,
  double maxViewportHeight = 420,
}) {
  final placements = <EvolutionNodePlacement>[];
  final visited = <int>{};
  var leafRows = 0;
  var maxDepth = 0;

  /// 后序摆放 [node]，返回 (子树占用行高， 节点中心 y)。
  (double, double) place(
    EvolutionNode node,
    int depth,
    EvolutionEdge? edge,
    double top,
  ) {
    visited.add(node.speciesId);
    if (depth > maxDepth) maxDepth = depth;
    final x = padding + depth * (nodeWidth + columnGap) + nodeWidth / 2;
    final childEdges = _childEdges(tree, node, visited);
    if (childEdges.isEmpty) {
      leafRows++;
      final y = top + rowHeight / 2;
      placements
          .add(EvolutionNodePlacement(node: node, edgeFromParent: edge, x: x, y: y));
      return (rowHeight, y);
    }
    var offset = top;
    double firstY = 0;
    double lastY = 0;
    for (var i = 0; i < childEdges.length; i++) {
      final child = tree.nodesBySpeciesId[childEdges[i].toSpeciesId]!;
      final (childHeight, childCenterY) =
          place(child, depth + 1, childEdges[i], offset);
      offset += childHeight; // 内部节点子树高 = Σ子树行高
      if (i == 0) firstY = childCenterY;
      lastY = childCenterY;
    }
    // 节点在其子树行区间内垂直居中：取首末子节点中心的中点。
    final y = (firstY + lastY) / 2;
    placements
        .add(EvolutionNodePlacement(node: node, edgeFromParent: edge, x: x, y: y));
    return (offset - top, y);
  }

  place(tree.root, 0, null, padding);

  final width = padding * 2 + (maxDepth + 1) * nodeWidth + maxDepth * columnGap;
  final contentHeight = padding * 2 + leafRows * rowHeight;
  return EvolutionCanvasLayout(
    placements: placements,
    width: width,
    height: contentHeight,
    viewportHeight:
        contentHeight.clamp(minViewportHeight, maxViewportHeight),
  );
}

/// trigger → 简中（EvolutionEdge.trigger 原样为 snake_case）。
const Map<String, String> _kTriggerZh = {
  'level-up': '等级提升',
  'trade': '通信交换',
  'use-item': '使用道具',
  'shed': '蜕壳',
  'spin': '旋转',
  'tower-of-darkness': '恶之塔修行',
  'tower-of-waters': '水之塔修行',
  'three-critical-hits': '一场战斗击中3次要害',
  'damage-location': '在特定地点受伤',
  'other': '特殊条件',
};

/// 进化道具有官方简中译名的可信映射（39 项；未收录走英文美化）。
const Map<String, String> _kItemZh = {
  'fire-stone': '火之石',
  'water-stone': '水之石',
  'thunder-stone': '雷之石',
  'leaf-stone': '叶之石',
  'moon-stone': '月之石',
  'sun-stone': '日之石',
  'shiny-stone': '光之石',
  'dusk-stone': '暗之石',
  'dawn-stone': '觉醒之石',
  'ice-stone': '冰之石',
  'oval-stone': '浑圆之石',
  'kings-rock': '王者之证',
  'metal-coat': '金属膜',
  'dragon-scale': '龙之鳞片',
  'deep-sea-tooth': '深海之牙',
  'deep-sea-scale': '深海鳞片',
  'up-grade': '升级数据',
  'dubious-disc': '可疑修补数据',
  'protector': '护具',
  'electirizer': '电力增幅器',
  'magmarizer': '熔岩增幅器',
  'razor-claw': '锐利之爪',
  'razor-fang': '锐利之牙',
  'sweet-apple': '甜苹果',
  'tart-apple': '酸苹果',
  'cracked-pot': '破裂的茶壶',
  'chipped-pot': '缺损的茶壶',
  'galarica-cuff': '伽勒豆蔻手环',
  'galarica-wreath': '伽勒豆蔻花环',
  'black-augurite': '黑奇石',
  'peat-block': '泥炭块',
  'linking-cord': '联系绳',
  'auspicious-armor': '祥辉之铠',
  'malicious-armor': '咒骸之铠',
  'leaders-crest': '首领的证明',
  'syrupy-apple': '蜜露苹果',
  'metal-alloy': '金属合金',
  'scroll-of-darkness': '恶之挂轴',
  'scroll-of-waters': '水之挂轴',
};

/// 进化要求招式的可信映射（6 项；未收录走英文美化）。
const Map<String, String> _kKnownMoveZh = {
  'mimic': '模仿',
  'ancient-power': '原始之力',
  'rollout': '滚动',
  'stomp': '践踏',
  'double-hit': '二连击',
  'taunt': '挑衅',
};

/// 进化要求队伍成员的可信映射（未收录走英文美化）。
const Map<String, String> _kPartySpeciesZh = {
  'remoraid': '铁炮鱼',
};

/// 标识符英文美化：`sacred-ash` → `Sacred Ash`。
String beautifyIdentifier(String identifier) => identifier
    .split('-')
    .map((part) => part.isEmpty
        ? part
        : '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

String _itemLabel(String item) => _kItemZh[item] ?? beautifyIdentifier(item);

/// EvolutionEdge → 条件 chip 文案列表（诚实显示）。
///
/// root 自指边（无 from 或 trigger=root）不产生条件。
List<String> evolutionConditionLabels(EvolutionEdge edge) {
  if (edge.fromSpeciesId == null || edge.trigger == 'root') {
    return const <String>[];
  }
  final labels = <String>[];

  // trigger：use-item 的边由「使用{道具}」承载语义，不重复展示 trigger。
  final useItemCovered = edge.trigger == 'use-item' && edge.item != null;
  if (!useItemCovered) {
    labels.add(_kTriggerZh[edge.trigger] ?? beautifyIdentifier(edge.trigger));
  }

  if (edge.item != null) {
    labels.add(edge.trigger == 'use-item'
        ? '使用${_itemLabel(edge.item!)}'
        : '道具 ${_itemLabel(edge.item!)}');
  }
  if (edge.heldItem != null) {
    labels.add('携带${_itemLabel(edge.heldItem!)}交换');
  }
  if (edge.minLevel != null) {
    labels.add('Lv.${edge.minLevel}');
  }
  if (edge.timeOfDay != null) {
    labels.add(switch (edge.timeOfDay!) {
      'day' => '白天',
      'night' => '夜晚',
      _ => edge.timeOfDay!,
    });
  }
  if (edge.gender != null) {
    labels.add(switch (edge.gender!) {
      'female' => '只限雌性',
      'male' => '只限雄性',
      _ => edge.gender!,
    });
  }
  if (edge.minHappiness != null) {
    labels.add('亲密度 ≥${edge.minHappiness}');
  }
  if (edge.minAffection != null) {
    labels.add('友好度 ≥${edge.minAffection}');
  }
  if (edge.minBeauty != null) {
    labels.add('美丽 ≥${edge.minBeauty}');
  }
  if (edge.relativePhysicalStats != null) {
    labels.add(switch (edge.relativePhysicalStats!) {
      'greater' => '攻击高于防御',
      'less' => '攻击低于防御',
      'equal' => '攻击与防御相等',
      _ => edge.relativePhysicalStats!,
    });
  }
  if (edge.knownMove != null) {
    final mapped = _kKnownMoveZh[edge.knownMove];
    labels.add(mapped != null
        ? '学会$mapped'
        : '学会 ${beautifyIdentifier(edge.knownMove!)}');
  }
  if (edge.knownMoveType != null) {
    final typeId = edge.knownMoveType!;
    labels.add('学会${kTypeNamesZh[typeId] ?? beautifyIdentifier(typeId)}属性招式');
  }
  if (edge.partySpecies != null) {
    labels.add(
        '队伍中有${_kPartySpeciesZh[edge.partySpecies] ?? beautifyIdentifier(edge.partySpecies!)}');
  }
  if (edge.partyType != null) {
    labels.add(
        '队伍中有${kTypeNamesZh[edge.partyType!] ?? beautifyIdentifier(edge.partyType!)}属性宝可梦');
  }
  if (edge.tradeSpecies != null) {
    labels.add(
        '与${_kPartySpeciesZh[edge.tradeSpecies] ?? beautifyIdentifier(edge.tradeSpecies!)}交换');
  }
  if (edge.location != null) {
    labels.add('地点 ${beautifyIdentifier(edge.location!)}');
  }
  if (edge.needsRain) {
    labels.add('雨天');
  }
  if (edge.turnUpsideDown) {
    labels.add('倒置主机升级');
  }
  return labels;
}
