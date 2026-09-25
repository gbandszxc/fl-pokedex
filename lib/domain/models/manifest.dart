import 'package:freezed_annotation/freezed_annotation.dart';

part 'manifest.freezed.dart';
part 'manifest.g.dart';

/// 数据清单（architecture.md §3，字段锁死；读 assets/database/manifest.json）。
@freezed
class DataManifest with _$DataManifest {
  const factory DataManifest({
    required int schemaVersion,
    required String dataVersion,
    required int pokemonCount,
    required int formCount,
    required int moveCount,
    required int abilityCount,
    required int versionCount,
    required String buildDate,
    required Map<String, dynamic> upstreamRevision,
    required List<String> learnsetVersionGroups,
    required List<int> missingArtwork,
  }) = _DataManifest;

  factory DataManifest.fromJson(Map<String, dynamic> json) =>
      _$DataManifestFromJson(json);
}
