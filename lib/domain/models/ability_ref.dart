import 'package:freezed_annotation/freezed_annotation.dart';

part 'ability_ref.freezed.dart';

/// 特性引用（architecture.md §3，字段锁死）。
@freezed
class AbilityRef with _$AbilityRef {
  const factory AbilityRef({
    required int id,
    required String nameZh,
    required String nameEn,
    required bool isHidden,

    /// 官方简中说明（abilities.text_zh_hans，可空）。
    String? descriptionZh,

    /// 英文 short_effect（abilities.text_en，可空）。
    String? descriptionEn,
  }) = _AbilityRef;
}
