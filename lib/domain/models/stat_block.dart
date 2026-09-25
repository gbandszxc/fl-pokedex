import 'package:freezed_annotation/freezed_annotation.dart';

part 'stat_block.freezed.dart';

/// 六项种族值 + 总和（architecture.md §3，字段锁死）。
@freezed
class StatBlock with _$StatBlock {
  const StatBlock._();

  const factory StatBlock({
    required int hp,
    required int attack,
    required int defense,
    required int specialAttack,
    required int specialDefense,
    required int speed,
  }) = _StatBlock;

  int get total =>
      hp + attack + defense + specialAttack + specialDefense + speed;
}
