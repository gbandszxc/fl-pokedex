import '../models/ability_ref.dart';
import '../models/evolution.dart';
import '../models/filters.dart';
import '../models/flavor_entry.dart';
import '../models/form_summary.dart';
import '../models/manifest.dart';
import '../models/move_detail.dart';
import '../models/move_entry.dart';
import '../models/pokemon_summary.dart';
import '../models/refs.dart';
import '../models/species_info.dart';
import '../models/stat_block.dart';

/// 图鉴数据仓储（architecture.md §4，签名逐字锁死）。
abstract class PokedexRepository {
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  });

  Future<int> countPokemon(FilterState f);

  Future<List<FormSummary>> getForms(int speciesId);

  Future<StatBlock> getFormStats(int formId);

  Future<List<AbilityRef>> getFormAbilities(int formId);

  /// zh 优先排序在 UI 做。
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId);

  /// 无进化链返回 null。
  Future<EvolutionTree?> getEvolutionTree(int speciesId);

  /// 该形态有学习集的组，新→旧。
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId);

  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  });

  Future<MoveDetail?> getMoveDetail(int moveId);

  Future<List<TypeRef>> getTypes();

  Future<List<GenerationRef>> getGenerations();

  Future<List<PokedexRef>> getPokedexes();

  /// species 基础信息（编号/世代/分类）。
  Future<SpeciesInfo> getSpeciesInfo(int speciesId);

  /// 按一批 speciesId 取列表摘要（收藏/最近浏览用）：单条 SQL IN 查询，
  /// 结果按入参顺序返回，缺失的 id 跳过。
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds);

  /// 读 assets/database/manifest.json。
  Future<DataManifest> getManifest();
}
