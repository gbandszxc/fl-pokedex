import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_summary.freezed.dart';

/// 列表项摘要（architecture.md §3）。
@freezed
class PokemonSummary with _$PokemonSummary {
  const factory PokemonSummary({
    required int speciesId,
    required int nationalDex,
    required String nameZh,
    required String nameEn,
    required String nameJa,
    required List<String> typeIds,
    String? thumbAsset,
    required int generationId,
    required bool isLegendary,
    required bool isMythical,
    required bool isUltraBeast,

    /// 搜索或跨形态筛选的轻量命中原因提示（如「别名：比雕」「形态：超级喷火龙Ｘ」）。
    String? matchHint,
  }) = _PokemonSummary;
}
