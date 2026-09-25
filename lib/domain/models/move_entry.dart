import 'package:freezed_annotation/freezed_annotation.dart';

part 'move_entry.freezed.dart';

/// 招式学习集条目（architecture.md §3，字段锁死）。
///
/// [typeId] / [damageClass] / [method] 为 DB snake_case 原样传递。
@freezed
class MoveEntry with _$MoveEntry {
  const factory MoveEntry({
    required int moveId,
    required String nameZh,
    required String nameEn,
    required String typeId,
    required String damageClass,
    int? power,
    int? pp,
    int? accuracy,
    int? level,
    required String method,
    required String versionGroup,
  }) = _MoveEntry;
}
