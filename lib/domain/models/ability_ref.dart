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
  }) = _AbilityRef;
}
