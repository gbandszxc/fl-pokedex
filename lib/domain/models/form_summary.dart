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

    /// 身高（米）= forms.height ÷ 10；上游缺失为 null。
    double? heightM,

    /// 体重（千克）= forms.weight ÷ 10；上游缺失为 null。
    double? weightKg,
  }) = _FormSummary;
}
