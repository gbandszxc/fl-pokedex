/// 进化树纯逻辑（可单测）：线性链判定、横排行宽估算（方案 B：画布
/// 形态已移除，改为「线性链横排 / 分支链纵向树」双形态）、compact
/// 纵向展开，以及进化边 → 条件文案的映射。
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

/// 线性链横排布局常数（尺寸/间距估算值，非 DESIGN token 管辖的
/// 颜色/圆角/时长/断点，沿用画布时期文件内 const 的命名风格）。
const double _kNodeMinWidth = 120;
const double _kArrowColumnWidth = 72;
const double _kRowPadding = 16;

/// 是否为线性进化链：从根出发，每个节点的可用出边（经 [_childEdges]
/// 的注册表过滤 + visited 防环语义）至多 1 条。
///
/// 空树（根无孩子）视为线性（true），空态由调用方另行处理；
/// 环路数据走到已访问节点时按链尾终止，与 [flattenEvolutionTree] 的
/// 防环行为一致。
bool isLinearEvolutionChain(EvolutionTree tree) {
  final visited = <int>{};
  var node = tree.root;
  while (visited.add(node.speciesId)) {
    final edges = _childEdges(tree, node, visited);
    if (edges.length > 1) return false;
    if (edges.isEmpty) return true;
    node = tree.nodesBySpeciesId[edges.single.toSpeciesId]!;
  }
  return true; // 环路兜底：回到已访问节点，视为链已终止。
}

/// 线性链横排一行的估算宽度：
/// nodeCount × 卡最小宽 + (nodeCount - 1) × 箭头列宽 + 两侧 padding。
///
/// nodeCount < 2 时返回 0（不足两节点不会使用横排形态）。
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
  // 以下为 PokeAPI 官方 trigger 枚举（数据库实际取值），译名依据：
  // use-move：使用特定招式若干次（火暴猴→弃世猴 20 次「恼怒」等），
  //   具体招式/次数数据未承载，不写入文案。
  // agile-style-move：以迅疾风格使用招式（《传说 阿尔宙斯》官方简中
  //   「迅疾/刚猛」风格，惊角鹿→诡角鹿）。
  // recoil-damage：洗翠巴斯库林→幽尾玄鱼累计受到反作用力伤害，
  //   「反作用力伤害」为官方简中用语；具体数值数据未承载。
  // take-damage：伽勒尔哭哭面具→死神板，从上次非濒死起累计受到
  //   伤害后经特定地点；数值/地点由其余条件或 location 展示。
  // three-defeated-bisharp：击败 3 只持有首领凭证的劈斩司令
  //   （劈斩司令为官方简中译名），数字 3 为 trigger 语义自带。
  // gimmighoul-coins：收集索财灵的硬币（官方简中道具名）后升级，
  //   具体枚数数据未承载。
  // meltan-candies：Pokémon GO 中使用美录坦糖果进化（官方糖果名）。
  'use-move': '多次使用招式',
  'agile-style-move': '以迅疾风格使用招式',
  'recoil-damage': '受到反作用力伤害',
  'take-damage': '累计受到伤害',
  'three-defeated-bisharp': '击败3只劈斩司令',
  'gimmighoul-coins': '收集索财灵的硬币',
  'meltan-candies': '使用美录坦糖果',
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
