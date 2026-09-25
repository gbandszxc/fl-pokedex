import 'package:freezed_annotation/freezed_annotation.dart';

part 'move_detail.freezed.dart';

/// 招式详情（architecture.md §3，字段锁死）。
@freezed
class MoveDetail with _$MoveDetail {
  const factory MoveDetail({
    required int id,
    required String nameZh,
    required String nameEn,
    required String nameJa,
    required String typeId,
    required String damageClass,
    int? power,
    int? pp,
    int? accuracy,
    int? priority,
    int? effectChance,
    String? effectEn,
    String? flavorZh,
    required int generationId,
  }) = _MoveDetail;
}
