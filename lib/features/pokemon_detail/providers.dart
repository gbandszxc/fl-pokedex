import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/flavor_entry.dart';
import '../../domain/models/form_summary.dart';
import 'detail_data.dart';

/// species 不存在（数据里没有对应的全国图鉴条目）。
class SpeciesNotFoundException implements Exception {
  const SpeciesNotFoundException(this.speciesId);

  final int speciesId;

  @override
  String toString() => 'SpeciesNotFoundException($speciesId)';
}

/// species 级详情（architecture.md §5 命名锁死）。
///
/// species 基本字段取自列表查询：data-contract 约定 species.id 即
/// national_dex，故用编号区间 [id, id] 精确取该只，避免按名称检索。
final pokemonDetailProvider = FutureProvider.autoDispose
    .family<PokemonDetailData, int>((ref, speciesId) async {
  final repo = ref.watch(pokedexRepositoryProvider);
  final summaries = await repo.queryPokemon(
    FilterState(dexMin: speciesId, dexMax: speciesId),
    limit: 1,
    offset: 0,
  );
  if (summaries.isEmpty) {
    throw SpeciesNotFoundException(speciesId);
  }
  final summary = summaries.single;
  final forms = await repo.getForms(speciesId);
  if (forms.isEmpty) {
    // data-contract 保证每只 species 都有默认形态；缺失视为数据损坏。
    throw SpeciesNotFoundException(speciesId);
  }
  return PokemonDetailData(
    speciesId: summary.speciesId,
    nationalDex: summary.nationalDex,
    nameZhHans: summary.nameZh,
    nameEn: summary.nameEn,
    nameJa: summary.nameJa,
    generationId: summary.generationId,
    forms: forms,
  );
});

/// 当前选中形态（speciesId → formId）。
///
/// null 表示跟随默认形态；显式赋值后由
/// [resolveSelectedForm] 解析为具体形态。
final selectedFormIdProvider = StateProvider.autoDispose.family<int?, int>(
  (ref, speciesId) => null,
);

/// 形态级详情：种族值 / 特性按形态惰性取回；属性与立绘直接取自
/// [FormSummary]（仓储接口里只有它带这两样）。
///
/// family 参数用 FormSummary（freezed 值语义）而非裸 formId：
/// 仅凭 formId 无法解析属性与立绘路径。
final formDetailProvider = FutureProvider.autoDispose
    .family<FormDetailData, FormSummary>((ref, form) async {
  final repo = ref.watch(pokedexRepositoryProvider);
  final stats = await repo.getFormStats(form.formId);
  final abilities = await repo.getFormAbilities(form.formId);
  return FormDetailData(
    typeIds: form.typeIds,
    stats: stats,
    abilities: abilities,
    // forms.height / weight 列存在但仓储接口未暴露（architecture.md §4
    // 锁定），待接口扩展后在 ÷10 换算处填充。
    heightM: null,
    weightKg: null,
    artworkAsset: form.artworkAsset,
  );
});

/// species 全部语言的图鉴说明文本（图鉴说明 tab 用）。
final flavorTextsProvider = FutureProvider.autoDispose
    .family<List<FlavorEntry>, int>((ref, speciesId) {
  return ref.watch(pokedexRepositoryProvider).getFlavorTexts(speciesId);
});

/// 图鉴说明当前选中的版本（speciesId → versionId）。
///
/// null 表示跟随默认：最新一个含 zh_hans 的版本，否则最新版本；
/// 解析逻辑见 [resolveFlavorSelection]。
final flavorSelectionProvider = StateProvider.autoDispose.family<int?, int>(
  (ref, speciesId) => null,
);

/// 收藏中的 speciesId 流（architecture.md §5 中归 G 单元
/// favorites/providers.dart；为避免本单元被 G 阻塞先在此自建，
/// 若同名冲突由主会话裁决合并）。
final favoriteIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchFavoriteSpeciesIds();
});
