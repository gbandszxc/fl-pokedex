import 'package:freezed_annotation/freezed_annotation.dart';

part 'filters.freezed.dart';

/// 特殊分类标签（architecture.md §3，枚举值与 DB 字符串值一致）。
enum SpecialTag { legendary, mythical, ultraBeast, mega, gmax, regional }

/// 双属性匹配模式（architecture.md §3）。
enum TypeMatchMode { any, all }

/// 列表筛选状态（architecture.md §3，字段锁死）。
@freezed
class FilterState with _$FilterState {
  const FilterState._();

  const factory FilterState({
    @Default('') String query,
    @Default(<int>{}) Set<int> generations,
    @Default(<String>{}) Set<String> typeIds,
    @Default(TypeMatchMode.any) TypeMatchMode typeMatchMode,
    @Default(<int>{}) Set<int> pokedexIds,
    int? dexMin,
    int? dexMax,
    @Default(<SpecialTag>{}) Set<SpecialTag> tags,
  }) = _FilterState;

  /// 是否完全没有筛选条件（query 为空白不算条件；typeMatchMode
  /// 仅在 typeIds 非空时才有意义，不单独计入）。
  bool get isEmpty =>
      query.trim().isEmpty &&
      generations.isEmpty &&
      typeIds.isEmpty &&
      pokedexIds.isEmpty &&
      dexMin == null &&
      dexMax == null &&
      tags.isEmpty;
}
