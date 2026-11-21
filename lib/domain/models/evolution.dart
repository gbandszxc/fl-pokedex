import 'package:freezed_annotation/freezed_annotation.dart';

part 'evolution.freezed.dart';

/// 进化边（architecture.md §3，字段锁死）。
///
/// trigger / method 等字符串值为 DB snake_case 原样传递，不额外编码。
@freezed
class EvolutionEdge with _$EvolutionEdge {
  const EvolutionEdge._();

  const factory EvolutionEdge({
    required int chainId,
    int? fromSpeciesId,
    required int toSpeciesId,
    int? fromFormId,
    int? toFormId,
    required String trigger,
    int? minLevel,
    String? item,
    String? heldItem,
    String? knownMove,
    String? knownMoveType,
    String? location,
    String? region,
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

  int? get resolvedFromFormId => fromFormId ?? fromSpeciesId;

  int get resolvedToFormId => toFormId ?? toSpeciesId;
}

/// 进化树节点（architecture.md §3，字段锁死）。
@freezed
class EvolutionNode with _$EvolutionNode {
  const EvolutionNode._();

  const factory EvolutionNode({
    required int speciesId,
    int? formId,
    required int nationalDex,
    required String nameZh,
    String? formNameZh,
    @Default(true) bool isDefaultForm,
    @Default(<String>[]) List<String> typeIds,
    String? thumbAsset,
    required List<EvolutionEdge> children,
  }) = _EvolutionNode;

  int get resolvedFormId => formId ?? speciesId;
}

/// 进化树（architecture.md §3，字段锁死）。
@freezed
class EvolutionTree with _$EvolutionTree {
  const EvolutionTree._();

  const factory EvolutionTree({
    required EvolutionNode root,

    /// 全部成员节点注册表（键 = speciesId，含根与各中段/末段物种，
    /// 每个节点带编号/简中名/缩略图；children 为该节点直接出边）。
    required Map<int, EvolutionNode> nodesBySpeciesId,

    /// 并行进化线全部根节点（单根链为 [root]；呆呆兽/喵喵等多形态并行线含多个根）。
    @Default(<EvolutionNode>[]) List<EvolutionNode> roots,

    /// 形态级节点注册表（键 = formId）。
    @Default(<int, EvolutionNode>{}) Map<int, EvolutionNode> nodesByFormId,
  }) = _EvolutionTree;

  List<EvolutionNode> get effectiveRoots =>
      roots.isNotEmpty ? roots : <EvolutionNode>[root];

  Map<int, EvolutionNode> get effectiveNodesByFormId =>
      nodesByFormId.isNotEmpty ? nodesByFormId : nodesBySpeciesId;

  bool get hasAnyEvolution =>
      effectiveRoots.any((node) => node.children.isNotEmpty);
}
