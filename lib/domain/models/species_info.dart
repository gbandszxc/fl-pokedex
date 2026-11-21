import 'package:freezed_annotation/freezed_annotation.dart';

import 'filters.dart';

part 'species_info.freezed.dart';

/// 物种基础信息（species 表的 genus 等列与物种检索标签；speciesId 与 nationalDex 同值）。
@freezed
class SpeciesInfo with _$SpeciesInfo {
  const factory SpeciesInfo({
    required int speciesId,
    required int nationalDex,
    required int generationId,

    /// 分类（如“种子宝可梦”；上游缺失为 null）。
    String? genusZh,
    String? genusEn,

    /// 物种检索标签（按 [SpecialTag.values] 排序；不含默认空值）。
    @Default(<SpecialTag>[]) List<SpecialTag> tags,
  }) = _SpeciesInfo;
}
