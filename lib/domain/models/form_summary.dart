import 'package:freezed_annotation/freezed_annotation.dart';

part 'form_summary.freezed.dart';

/// 形态摘要（architecture.md §3，字段锁死）。
@freezed
class FormSummary with _$FormSummary {
  const factory FormSummary({
    required int formId,
    required int speciesId,
    String? formIdentifier,
    required String formNameZh,
    required String formNameEn,
    required bool isDefault,
    required bool isMega,
    required bool isGmax,
    required bool isRegional,
    String? artworkAsset,
    required List<String> typeIds,
  }) = _FormSummary;
}
