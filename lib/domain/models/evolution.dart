import 'package:freezed_annotation/freezed_annotation.dart';

part 'evolution.freezed.dart';

/// 进化边（architecture.md §3，字段锁死）。
///
/// trigger / method 等字符串值为 DB snake_case 原样传递，不额外编码。
@freezed
class EvolutionEdge with _$EvolutionEdge {
  const factory EvolutionEdge({
    required int chainId,
    int? fromSpeciesId,
    required int toSpeciesId,
    required String trigger,
    int? minLevel,
    String? item,
    String? heldItem,
    String? knownMove,
    String? knownMoveType,
    String? location,
    String? timeOfDay,
    String? gender,
    int? minHappiness,
    int? minAffection,
    int? minBeauty,
    String? relativePhysicalStats,
    String? partySpecies,
    String? partyType,
    String? tradeSpecies,
    required bool needsRain,
    required bool turnUpsideDown,
  }) = _EvolutionEdge;
}

/// 进化树节点（architecture.md §3，字段锁死）。
@freezed
class EvolutionNode with _$EvolutionNode {
  const factory EvolutionNode({
    required int speciesId,
    required int nationalDex,
    required String nameZh,
    String? thumbAsset,
    required List<EvolutionEdge> children,
  }) = _EvolutionNode;
}

/// 进化树（architecture.md §3，字段锁死）。
@freezed
class EvolutionTree with _$EvolutionTree {
  const factory EvolutionTree({
    required EvolutionNode root,

    /// 全部成员节点注册表（键 = speciesId，含根与各中段/末段物种，
    /// 每个节点带编号/简中名/缩略图；children 为该节点直接出边）。
    /// UI 从 [root] 出发按 children 逐层查此表即可重建完整层级。
    required Map<int, EvolutionNode> nodesBySpeciesId,
  }) = _EvolutionTree;
}
