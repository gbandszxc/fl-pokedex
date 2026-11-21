/// 进化树纯逻辑（可单测）：形态级图遍历、52poke 风格横向阶梯树宽度估算、
/// 线性判定、纵向树展开、当前形态高亮解析以及进化边 → 条件文案的映射。
///
/// 文案原则（诚实显示）：有官方简中译名把握的标识符给中文；
/// 没有把握的一律英文美化（`sacred-ash` → `Sacred Ash`），禁止编造。
library;

import 'dart:math' as math;

import '../../domain/models/evolution.dart';
import '../../shared/widgets/type_badge.dart' show kTypeNamesZh;

/// 纵向树的一行（先序：根在前，逐层缩进）。
class EvolutionRow {
  const EvolutionRow({
    required this.node,
    required this.depth,
    required this.guides,
    this.edgeFromParent,
    this.indicateOtherRegion = false,
  });

  final EvolutionNode node;

  /// 根为 0，每往下一层 +1。
  final int depth;

  /// 到父节点的边（根为 null）。
  final EvolutionEdge? edgeFromParent;

  /// 同父兄弟边存在 `region != null` 指向同一 `toSpeciesId` 且自身无 region：
  /// 需额外标出「其他地区」，与地区限定进化形成对照（如 魔尼尼→魔墙人偶）。
  final bool indicateOtherRegion;

  /// 各层祖先（j = 0..depth-1，第 0 层为根、第 depth-1 层为父）的
  /// 导引竖线是否需要**延续穿过本行**：第 j 层祖先的子树在先序中
  /// 于本行之后还有未渲染节点。false 时该祖先的竖线到上一行即止
  /// （└ 端点语义，与 `tree` 命令的字符画一致）。
  final List<bool> guides;
}

/// 52poke 风格横向阶梯树布局常数（尺寸估算值，与 UI 渲染实宽严格闭环）。
const double kHorizontalNodeWidth = 132;
const double kHorizontalEdgeWidth = 96;
const double kHorizontalBranchSpineWidth = 20;

/// 宽屏充裕档横排布局常数。
const double kHorizontalNodeWidthRoomy = 140;
const double kHorizontalEdgeWidthRoomy = 112;
const double kHorizontalBranchSpineWidthRoomy = 24;

/// 多分支链启用横向阶梯树的最小本地宽度：避免窄手机竖屏下分支树过挤。
const double kHorizontalBranchMinWidth = 420;

/// 该节点的可用出边：目标在形态注册表内且未访问过（环路数据安全）。
List<EvolutionEdge> _childEdges(
  EvolutionTree tree,
  EvolutionNode node,
  Set<int> visitedFormIds,
) {
  final nodes = tree.effectiveNodesByFormId;
  return [
    for (final edge in node.children)
      if (!visitedFormIds.contains(edge.resolvedToFormId))
        if (nodes[edge.resolvedToFormId] != null) edge,
  ];
}

/// 预计算：先序展开中各 formId 的子树占用的行数（含自身行）。
Map<int, int> _subtreeRowCounts(EvolutionTree tree, EvolutionNode root) {
  final visited = <int>{};
  final counts = <int, int>{};
  final nodes = tree.effectiveNodesByFormId;

  int count(EvolutionNode node) {
    final formId = node.resolvedFormId;
    visited.add(formId);
    var total = 1;
    for (final edge in _childEdges(tree, node, visited)) {
      total += count(nodes[edge.resolvedToFormId]!);
    }
    counts[formId] = total;
    return total;
  }

  count(root);
  return counts;
}

/// 判断父节点出边列表 [siblings] 中的 [edge] 是否需要标注「其他地区」。
bool shouldIndicateOtherRegion(
  EvolutionEdge edge,
  Iterable<EvolutionEdge> siblings,
) {
  if (edge.region != null) return false;
  return siblings.any(
    (other) =>
        other.toSpeciesId == edge.toSpeciesId &&
        other.region != null &&
        other.resolvedToFormId != edge.resolvedToFormId,
  );
}

/// 先序展开指定根节点 [root] 的整棵子树，供纵向树与时间线逐行渲染。
List<EvolutionRow> flattenEvolutionSubtree(
  EvolutionTree tree,
  EvolutionNode root,
) {
  final subtreeRows = _subtreeRowCounts(tree, root);
  final nodes = tree.effectiveNodesByFormId;
  final rows = <EvolutionRow>[];
  final visited = <int>{};

  void visit(
    EvolutionNode node,
    int depth,
    EvolutionEdge? edge,
    bool indicateOtherRegion,
    List<int> ancestorEnds,
  ) {
    final formId = node.resolvedFormId;
    if (!visited.add(formId)) return;
    final selfIndex = rows.length;
    final subtreeEnd = selfIndex + (subtreeRows[formId] ?? 1) - 1;
    rows.add(EvolutionRow(
      node: node,
      depth: depth,
      edgeFromParent: edge,
      indicateOtherRegion: indicateOtherRegion,
      guides: [for (final end in ancestorEnds) end > selfIndex],
    ));
    final childEdges = _childEdges(tree, node, visited);
    for (var i = 0; i < childEdges.length; i++) {
      final childEdge = childEdges[i];
      final child = nodes[childEdge.resolvedToFormId]!;
      visit(
        child,
        depth + 1,
        childEdge,
        shouldIndicateOtherRegion(childEdge, childEdges),
        [...ancestorEnds, subtreeEnd],
      );
    }
  }

  visit(root, 0, null, false, const <int>[]);
  return rows;
}

/// 先序展开整棵树（兼容单根入口，委托 [flattenEvolutionSubtree]）。
List<EvolutionRow> flattenEvolutionTree(EvolutionTree tree) =>
    flattenEvolutionSubtree(tree, tree.root);

/// 线性链横排默认估算常数（与既有单测契约保持一致）。
const double _kNodeMinWidth = 120;
const double _kArrowColumnWidth = 72;
const double _kRowPadding = 16;

/// 指定根节点 [root] 的子树是否为纯线性链（每个节点至多 1 个可用出边）。
bool isLinearEvolutionSubtree(EvolutionTree tree, EvolutionNode root) {
  final visited = <int>{};
  final nodes = tree.effectiveNodesByFormId;
  var node = root;
  while (visited.add(node.resolvedFormId)) {
    final edges = _childEdges(tree, node, visited);
    if (edges.length > 1) return false;
    if (edges.isEmpty) return true;
    node = nodes[edges.single.resolvedToFormId]!;
  }
  return true;
}

/// 整棵进化树是否为单根纯线性链。
bool isLinearEvolutionChain(EvolutionTree tree) =>
    tree.effectiveRoots.length == 1 &&
    isLinearEvolutionSubtree(tree, tree.effectiveRoots.first);

/// 线性链是否含任一分支或并行多根。
bool hasBranchingInForest(EvolutionTree tree) {
  for (final root in tree.effectiveRoots) {
    if (!isLinearEvolutionSubtree(tree, root)) return true;
  }
  return false;
}

/// 估算以 [root] 为根的子树在 52poke 横向阶梯树形态下的所需宽度。
double horizontalSubtreeWidth(
  EvolutionTree tree,
  EvolutionNode root, {
  double nodeWidth = kHorizontalNodeWidth,
  double edgeWidth = kHorizontalEdgeWidth,
  double branchSpineWidth = kHorizontalBranchSpineWidth,
}) {
  final nodes = tree.effectiveNodesByFormId;
  final visited = <int>{};

  double widthOf(EvolutionNode node) {
    final formId = node.resolvedFormId;
    if (!visited.add(formId)) return nodeWidth;
    final edges = _childEdges(tree, node, visited);
    if (edges.isEmpty) return nodeWidth;
    if (edges.length == 1) {
      final child = nodes[edges.single.resolvedToFormId]!;
      return nodeWidth + edgeWidth + widthOf(child);
    }
    var maxChild = 0.0;
    for (final edge in edges) {
      final child = nodes[edge.resolvedToFormId]!;
      maxChild = math.max(maxChild, widthOf(child));
    }
    return nodeWidth + branchSpineWidth + edgeWidth + maxChild;
  }

  return widthOf(root);
}

/// 估算整座进化森林（多根并行取最大行宽）在横向阶梯树形态下的所需宽度。
double horizontalForestWidth(
  EvolutionTree tree, {
  double nodeWidth = kHorizontalNodeWidth,
  double edgeWidth = kHorizontalEdgeWidth,
  double branchSpineWidth = kHorizontalBranchSpineWidth,
}) {
  var maxWidth = 0.0;
  for (final root in tree.effectiveRoots) {
    maxWidth = math.max(
      maxWidth,
      horizontalSubtreeWidth(
        tree,
        root,
        nodeWidth: nodeWidth,
        edgeWidth: edgeWidth,
        branchSpineWidth: branchSpineWidth,
      ),
    );
  }
  return maxWidth;
}

/// 线性链横排一行的估算宽度：
/// nodeCount × 卡最小宽 + (nodeCount - 1) × 箭头列宽 + 两侧 padding。
double linearChainRowWidth(
  int nodeCount, {
  double nodeMinWidth = _kNodeMinWidth,
  double arrowColumnWidth = _kArrowColumnWidth,
  double rowPadding = _kRowPadding,
}) {
  if (nodeCount < 2) return 0;
  return nodeCount * nodeMinWidth +
      (nodeCount - 1) * arrowColumnWidth +
      rowPadding * 2;
}

/// 解析进化树中应高亮的 `formId`；若当前选中形态自身不可进化
/// （如关都大葱鸭 / 普通野蛮鲈鱼 / Mega 喷火龙当他形态或同物种另有分支时），
/// 返回 null（唯一默认形态可进化的 Mega/超极巨化回退高亮其默认形态）。
int? resolveHighlightedEvolutionFormId(
  EvolutionTree tree, {
  required int speciesId,
  int? selectedFormId,
}) {
  final nodes = tree.effectiveNodesByFormId;
  if (selectedFormId != null && nodes.containsKey(selectedFormId)) {
    return selectedFormId;
  }
  if (selectedFormId == null && nodes.containsKey(speciesId)) {
    return speciesId;
  }
  final candidates = [
    for (final node in nodes.values)
      if (node.speciesId == speciesId) node,
  ];
  if (candidates.length == 1 && candidates.single.isDefaultForm) {
    return candidates.single.resolvedFormId;
  }
  return null;
}

/// trigger → 简中（EvolutionEdge.trigger 原样为 snake_case）。
const Map<String, String> _kTriggerZh = {
  'level-up': '等级提升',
  'in-battle-level-up': '对战中升级',
  'trade': '通信交换',
  'use-item': '使用道具',
  'shed': '蜕壳',
  'spin': '旋转',
  'tower-of-darkness': '恶之塔修行',
  'tower-of-waters': '水之塔修行',
  'three-critical-hits': '一场战斗击中3次要害',
  'damage-location': '在特定地点受伤',
  'other': '特殊条件',
  'use-move': '多次使用招式',
  'agile-style-move': '以迅疾风格使用招式',
  'recoil-damage': '受到反作用力伤害',
  'take-damage': '累计受到伤害',
  'three-defeated-bisharp': '击败3只劈斩司令',
  'gimmighoul-coins': '收集索财灵的硬币',
  'meltan-candies': '使用美录坦糖果',
};

/// 进化道具有官方简中译名的可信映射（未收录走英文美化）。
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
  'prism-scale': '美丽鳞片',
  'reaper-cloth': '灵界之布',
  'sachet': '香袋',
  'whipped-dream': '泡沫奶油',
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
  'unremarkable-teacup': '凡作茶碗',
  'masterpiece-teacup': '杰作茶碗',
};

/// 进化要求招式的可信映射（未收录走英文美化）。
const Map<String, String> _kKnownMoveZh = {
  'mimic': '模仿',
  'ancient-power': '原始之力',
  'rollout': '滚动',
  'stomp': '践踏',
  'double-hit': '二连击',
  'taunt': '挑衅',
  'barb-barrage': '毒千针',
  'dragon-cheer': '龙声鼓舞',
  'dragon-pulse': '龙之波动',
  'hyper-drill': '强力钻',
  'twin-beam': '双光束',
};

/// 进化要求队伍成员的可信映射（未收录走英文美化）。
const Map<String, String> _kPartySpeciesZh = {
  'remoraid': '铁炮鱼',
};

/// 进化要求地点（有官方简中译名的可信映射）。
const Map<String, String> _kLocationZh = {
  'dusty-bowl': '沙尘洼地',
};

/// 进化限定地区（regions.identifier → 官方简中）。
const Map<String, String> _kRegionZh = {
  'alola': '阿罗拉地区',
  'galar': '伽勒尔地区',
  'hisui': '洗翠地区',
  'paldea': '帕底亚地区',
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
/// root 自指边（无 from 或 trigger=root）不产生条件；
/// [indicateOtherRegion] 为 true 且 `edge.region == null` 时追加「其他地区」。
List<String> evolutionConditionLabels(
  EvolutionEdge edge, {
  bool indicateOtherRegion = false,
}) {
  if ((edge.fromSpeciesId == null && edge.fromFormId == null) ||
      edge.trigger == 'root') {
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
      'dusk' => '黄昏',
      'full-moon' => '满月之夜',
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
    final locLabel =
        _kLocationZh[edge.location] ?? beautifyIdentifier(edge.location!);
    labels.add('地点 $locLabel');
  }
  if (edge.region != null) {
    labels.add(_kRegionZh[edge.region!] ?? beautifyIdentifier(edge.region!));
  } else if (indicateOtherRegion) {
    labels.add('其他地区');
  }
  if (edge.needsRain) {
    labels.add('雨天');
  }
  if (edge.turnUpsideDown) {
    labels.add('倒置主机升级');
  }
  return labels;
}
