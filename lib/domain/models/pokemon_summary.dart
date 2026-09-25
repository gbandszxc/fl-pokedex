import 'package:freezed_annotation/freezed_annotation.dart';

part 'pokemon_summary.freezed.dart';

/// 列表项摘要（architecture.md §3，字段锁死）。
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
  }) = _PokemonSummary;
}
