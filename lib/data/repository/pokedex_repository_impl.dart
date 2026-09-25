import '../../domain/models/ability_ref.dart';
import '../../domain/models/evolution.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/flavor_entry.dart';
import '../../domain/models/form_summary.dart';
import '../../domain/models/manifest.dart';
import '../../domain/models/move_detail.dart';
import '../../domain/models/move_entry.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../domain/models/refs.dart';
import '../../domain/models/species_info.dart';
import '../../domain/models/stat_block.dart';
import '../../domain/repositories/pokedex_repository.dart';
import '../database/pokedex_database.dart';

/// [PokedexRepository] 的 SQLite 实现：SQL 聚合在 DAO 内完成（单查询、
/// 无 N+1），本类只做编排（进化树组装、manifest 读取）。
///
/// 本文件位于 drift_dev 的 codegen 白名单内，须保持纯 Dart 依赖：
/// manifest 的 JSON 读取由外部（lib/core/di.dart）以回调注入。
class PokedexRepositoryImpl implements PokedexRepository {
  PokedexRepositoryImpl(
    this._db, {
    Future<Map<String, dynamic>> Function()? loadManifestJson,
  }) : _loadManifestJson =
            loadManifestJson ?? (() => throw StateError('未注入 manifest 读取器'));

  final PokedexDatabase _db;

  /// 返回 manifest.json 反序列化后的 JSON 对象。
  final Future<Map<String, dynamic>> Function() _loadManifestJson;

  PokedexDao get _pokedexDao => _db.pokedexDao;
  MoveDao get _moveDao => _db.moveDao;
  EvolutionDao get _evolutionDao => _db.evolutionDao;

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) =>
      _pokedexDao.queryPokemon(f, limit: limit, offset: offset);

  @override
  Future<int> countPokemon(FilterState f) => _pokedexDao.countPokemon(f);

  @override
  Future<List<FormSummary>> getForms(int speciesId) =>
      _pokedexDao.getForms(speciesId);

  @override
  Future<StatBlock> getFormStats(int formId) =>
      _pokedexDao.getFormStats(formId);

  @override
  Future<List<AbilityRef>> getFormAbilities(int formId) =>
      _pokedexDao.getFormAbilities(formId);

  @override
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) =>
      _pokedexDao.getFlavorTexts(speciesId);

  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) async {
    final chainId = await _evolutionDao.getEvolutionChainId(speciesId);
    if (chainId == null) return null;

    // 该链全部边 + 各边 to 端 species 的展示信息（每只 species 至少作为
    // 一条边的 to 端出现，含根自指行，因此展示信息完整）。
    final edges = await _evolutionDao.getChainEdges(chainId);
    if (edges.isEmpty) return null;

    final rootEdge = edges.firstWhere(
      (edge) => edge.isRootRow || edge.fromSpeciesId == edge.toSpeciesId,
    );

    // 节点注册表：每个 species 一个节点，children = 该节点的直接出边；
    // 中段物种（如蛹）由此获得编号/简中名/缩略图，UI 逐层查表重建层级。
    final outEdges = <int, List<EvolutionEdgeData>>{};
    for (final edge in edges) {
      final from = edge.fromSpeciesId;
      if (from == null || edge.isRootRow || from == edge.toSpeciesId) continue;
      outEdges.putIfAbsent(from, () => []).add(edge);
    }
    final memberIds = <int>{
      rootEdge.toSpeciesId,
      for (final edge in edges) edge.toSpeciesId,
    };
    final displayBySpecies = {
      for (final edge in edges) edge.toSpeciesId: edge,
    };
    EvolutionNode nodeOf(int speciesId) {
      final data = displayBySpecies[speciesId]!;
      return EvolutionNode(
        speciesId: speciesId,
        nationalDex: data.toNationalDex,
        nameZh: data.toNameZh,
        thumbAsset: data.toThumbAsset,
        children: [
          for (final edge in outEdges[speciesId] ?? const <EvolutionEdgeData>[])
            edge.toDomain(),
        ],
      );
    }

    final nodesBySpeciesId = {
      for (final id in memberIds) id: nodeOf(id),
    };

    return EvolutionTree(
      root: nodesBySpeciesId[rootEdge.toSpeciesId]!,
      nodesBySpeciesId: nodesBySpeciesId,
    );
  }

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) =>
      _pokedexDao.getFormVersionGroups(formId);

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) =>
      _moveDao.getLearnset(formId, versionGroup, methods: methods);

  @override
  Future<MoveDetail?> getMoveDetail(int moveId) =>
      _moveDao.getMoveDetail(moveId);

  @override
  Future<List<TypeRef>> getTypes() => _pokedexDao.getTypes();

  @override
  Future<List<GenerationRef>> getGenerations() => _pokedexDao.getGenerations();

  @override
  Future<List<PokedexRef>> getPokedexes() => _pokedexDao.getPokedexes();

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) =>
      _pokedexDao.getSpeciesInfo(speciesId);

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) =>
      _pokedexDao.getPokemonSummaries(speciesIds);

  @override
  Future<DataManifest> getManifest() async =>
      DataManifest.fromJson(await _loadManifestJson());
}
