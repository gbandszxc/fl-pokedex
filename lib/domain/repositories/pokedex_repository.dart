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

  /// 读 assets/database/manifest.json。
  Future<DataManifest> getManifest();
}
