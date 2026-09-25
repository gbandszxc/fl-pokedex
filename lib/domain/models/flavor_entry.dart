import 'package:freezed_annotation/freezed_annotation.dart';

part 'flavor_entry.freezed.dart';

/// 图鉴说明条目（architecture.md §3，字段锁死）。
///
/// language ∈ zh_hans / zh_hant / en / ja。
@freezed
class FlavorEntry with _$FlavorEntry {
  const factory FlavorEntry({
    required int versionId,
    required String versionIdentifier,
    required String versionNameZh,
    required String versionNameEn,
    required int generationId,
    required String language,
    required String text,
  }) = _FlavorEntry;
}
