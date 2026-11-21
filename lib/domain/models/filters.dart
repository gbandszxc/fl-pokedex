import 'package:freezed_annotation/freezed_annotation.dart';

part 'filters.freezed.dart';

/// 特殊分类 / 检索标签（architecture.md §3，dbId 与 species_tags.tag_id 一致）。
enum SpecialTag {
  legendary,
  mythical,
  ultraBeast,
  paradox,
  pseudoLegendary,
  starter,
  fossil,
  baby,
  mega,
  gmax,
  regional,
}

/// [SpecialTag] 元数据：DB 键、筛选短名、详情展示名、形态分组与搜索同义词。
extension SpecialTagMeta on SpecialTag {
  /// 数据库 `species_tags.tag_id` 字符串值（snake_case）。
  String get dbId => switch (this) {
        SpecialTag.legendary => 'legendary',
        SpecialTag.mythical => 'mythical',
        SpecialTag.ultraBeast => 'ultra_beast',
        SpecialTag.paradox => 'paradox',
        SpecialTag.pseudoLegendary => 'pseudo_legendary',
        SpecialTag.starter => 'starter',
        SpecialTag.fossil => 'fossil',
        SpecialTag.baby => 'baby',
        SpecialTag.mega => 'mega',
        SpecialTag.gmax => 'gmax',
        SpecialTag.regional => 'regional',
      };

  static final Map<String, SpecialTag> _byDbId = {
    for (final tag in SpecialTag.values) tag.dbId: tag,
  };

  /// 从数据库 `tag_id` 解析标签；未知字符串返回 null。
  static SpecialTag? fromDbId(String id) => _byDbId[id];

  /// 筛选面板短标签。
  String get labelZh => switch (this) {
        SpecialTag.legendary => '传说',
        SpecialTag.mythical => '幻之',
        SpecialTag.ultraBeast => '究极异兽',
        SpecialTag.paradox => '悖谬',
        SpecialTag.pseudoLegendary => '准传说',
        SpecialTag.starter => '御三家',
        SpecialTag.fossil => '化石',
        SpecialTag.baby => '幼年',
        SpecialTag.mega => '超级进化',
        SpecialTag.gmax => '超极巨',
        SpecialTag.regional => '地区形态',
      };

  /// 详情页与搜索命中提示用名称。
  String get detailLabelZh => switch (this) {
        SpecialTag.legendary => '传说',
        SpecialTag.mythical => '幻之',
        SpecialTag.ultraBeast => '究极异兽',
        SpecialTag.paradox => '悖谬宝可梦',
        SpecialTag.pseudoLegendary => '准传说',
        SpecialTag.starter => '御三家',
        SpecialTag.fossil => '化石宝可梦',
        SpecialTag.baby => '幼年宝可梦',
        SpecialTag.mega => '超级进化',
        SpecialTag.gmax => '超极巨',
        SpecialTag.regional => '地区形态',
      };

  /// 是否属于特殊形态维度（否则属于群体与身份标签）。
  bool get isFormTag => switch (this) {
        SpecialTag.mega || SpecialTag.gmax || SpecialTag.regional => true,
        _ => false,
      };

  /// 纳入倒排索引检索的中文与常用同义词。
  List<String> get searchTerms => switch (this) {
        SpecialTag.legendary => const ['传说', '神兽', '传说宝可梦'],
        SpecialTag.mythical => const ['幻之', '幻兽', '幻之宝可梦'],
        SpecialTag.ultraBeast => const ['究极异兽', 'ub'],
        SpecialTag.paradox => const ['悖谬', '悖谬宝可梦', '古代种', '未来种'],
        SpecialTag.pseudoLegendary => const ['准神', '准传说', '大器晚成'],
        SpecialTag.starter => const ['御三家', '最初的伙伴', '初始宝可梦'],
        SpecialTag.fossil => const ['化石', '化石宝可梦', '古代化石'],
        SpecialTag.baby => const ['幼年', '幼年宝可梦', '宝宝'],
        SpecialTag.mega => const ['超级进化', 'mega', '百万进化'],
        SpecialTag.gmax => const ['超极巨', '超极巨化', '极巨化'],
        SpecialTag.regional => const ['地区形态', '地区样子'],
      };
}

/// 双属性匹配模式（architecture.md §3）。
enum TypeMatchMode { any, all }

/// 列表筛选状态（architecture.md §3）。
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
    String? genus,
  }) = _FilterState;

  /// 是否完全没有筛选条件（query / genus 为空白不算条件；typeMatchMode
  /// 仅在 typeIds 非空时才有意义，不单独计入）。
  bool get isEmpty =>
      query.trim().isEmpty &&
      generations.isEmpty &&
      typeIds.isEmpty &&
      pokedexIds.isEmpty &&
      dexMin == null &&
      dexMax == null &&
      tags.isEmpty &&
      (genus == null || genus!.trim().isEmpty);
}
