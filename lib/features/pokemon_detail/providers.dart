import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/di.dart';
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
/// 名称与存在性走 `getPokemonSummaries([id])`（缺失 id 跳过 → 空列表可判
/// 不存在）；编号 / 世代 / 分类走 `getSpeciesInfo`。均为按 id 的正式接口。
final pokemonDetailProvider = FutureProvider.autoDispose
    .family<PokemonDetailData, int>((ref, speciesId) async {
  final repo = ref.watch(pokedexRepositoryProvider);
  final summaries = await repo.getPokemonSummaries([speciesId]);
  if (summaries.isEmpty) {
    throw SpeciesNotFoundException(speciesId);
  }
  final summary = summaries.single;
  final info = await repo.getSpeciesInfo(speciesId);
  final forms = await repo.getForms(speciesId);
  if (forms.isEmpty) {
    // data-contract 保证每只 species 都有默认形态；缺失视为数据损坏。
    throw SpeciesNotFoundException(speciesId);
  }
  return PokemonDetailData(
    speciesId: summary.speciesId,
    nationalDex: info.nationalDex,
    nameZhHans: summary.nameZh,
    nameEn: summary.nameEn,
    nameJa: summary.nameJa,
    genusZh: info.genusZh,
    genusEn: info.genusEn,
    generationId: info.generationId,
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

/// 形态级详情：种族值 / 特性按形态惰性取回；属性、立绘与身高体重直接
/// 取自 [FormSummary]（C2 起它携带这三样）。
///
/// family 参数用 FormSummary（freezed 值语义）而非裸 formId：
/// 仅凭 formId 无法解析属性、立绘与身高体重。
final formDetailProvider = FutureProvider.autoDispose
    .family<FormDetailData, FormSummary>((ref, form) async {
  final repo = ref.watch(pokedexRepositoryProvider);
  final stats = await repo.getFormStats(form.formId);
  final abilities = await repo.getFormAbilities(form.formId);
  return FormDetailData(
    typeIds: form.typeIds,
    stats: stats,
    abilities: abilities,
    // 上游缺失或为 0 视为无数据（UI 显示 —）。
    heightM: (form.heightM != null && form.heightM! > 0) ? form.heightM : null,
    weightKg: (form.weightKg != null && form.weightKg! > 0) ? form.weightKg : null,
    artworkAsset: form.artworkAsset,
  );
});

/// species 全部语言的图鉴说明文本（图鉴说明 tab 用）。
final flavorTextsProvider = FutureProvider.autoDispose
    .family<List<FlavorEntry>, int>((ref, speciesId) {
  return ref.watch(pokedexRepositoryProvider).getFlavorTexts(speciesId);
});

/// 地区形态专属图鉴说明文本（formId family；空列表时 UI 回退
/// [flavorTextsProvider] 的 species 级文本）。
final formFlavorTextsProvider = FutureProvider.autoDispose
    .family<List<FlavorEntry>, int>((ref, formId) {
  return ref.watch(pokedexRepositoryProvider).getFormFlavorTexts(formId);
});

/// 图鉴说明当前选中的版本（speciesId → versionId）。
///
/// null 表示跟随默认：最新一个含 zh_hans 的版本，否则最新版本；
/// 解析逻辑见 [resolveFlavorSelection]。
final flavorSelectionProvider = StateProvider.autoDispose.family<int?, int>(
  (ref, speciesId) => null,
);

/// 全部 species 的 id 序列（national_dex 升序，architecture.md §4
/// `getAllSpeciesIds`）。详情页上一只/下一只切换用：取当前 id 的相邻项。
///
/// 不用 autoDispose：全序列 ~1k 个 int，缓存后多次切换免重复查询。
final speciesDexOrderProvider = FutureProvider<List<int>>((ref) {
  return ref.watch(pokedexRepositoryProvider).getAllSpeciesIds();
});

/// 收藏中的 speciesId 流（architecture.md §5 中归 G 单元
/// favorites/providers.dart；为避免本单元被 G 阻塞先在此自建，
/// 若同名冲突由主会话裁决合并）。
final favoriteIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchFavoriteSpeciesIds();
});
