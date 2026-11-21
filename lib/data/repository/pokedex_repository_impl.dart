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
  Future<List<FlavorEntry>> getFormFlavorTexts(int formId) =>
      _pokedexDao.getFormFlavorTexts(formId);

  /// 非地区形态多态分支进化中，默认形态自身在进化链中的官方形态副标题
  /// （forms.is_default=1 时 forms.form_name_zh 为种名，不带形态后缀，
  /// 当同链存在非地区兄弟形态时按此表补出，如「一击流 / 连击流」）。
  static const Map<int, String> _kDefaultEvolutionFormNameZh = {
    413: '草木蓑衣',
    678: '雄性的样子',
    710: '普通尺寸',
    711: '普通尺寸',
    745: '白昼的样子',
    849: '高调的样子',
    892: '一击流',
    902: '雄性的样子',
    916: '雄性的样子',
    925: '四只家庭',
    982: '两节形态',
  };

  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) async {
    final chainId = await _evolutionDao.getEvolutionChainId(speciesId);
    if (chainId == null) return null;

    // 该链全部边 + 各边 to 端形态的展示信息（含各根节点自指行）。
    final edges = await _evolutionDao.getChainEdges(chainId);
    if (edges.isEmpty) return null;

    final rootEdges = [
      for (final edge in edges)
        if (edge.isRootRow) edge,
    ];
    if (rootEdges.isEmpty) {
      rootEdges.add(edges.first);
    }

    // 形态级节点注册表：按 form_id 建边与索引，支持地区形态分叉及多根并行链。
    final outEdgesByForm = <int, List<EvolutionEdgeData>>{};
    for (final edge in edges) {
      final fromForm = edge.fromFormId ?? edge.fromSpeciesId;
      if (fromForm == null || edge.isRootRow || fromForm == edge.toFormId) {
        continue;
      }
      outEdgesByForm.putIfAbsent(fromForm, () => []).add(edge);
    }

    final displayByForm = {
      for (final edge in edges) edge.toFormId: edge,
    };
    final speciesWithNonRegionalAltForm = <int>{
      for (final edge in edges)
        if (!edge.toIsDefaultForm && !edge.toIsRegional) edge.toSpeciesId,
    };

    EvolutionNode nodeOf(int formId) {
      final data = displayByForm[formId]!;
      final formLabel = !data.toIsDefaultForm
          ? data.toFormNameZh
          : (speciesWithNonRegionalAltForm.contains(data.toSpeciesId)
              ? _kDefaultEvolutionFormNameZh[data.toSpeciesId]
              : null);
      return EvolutionNode(
        speciesId: data.toSpeciesId,
        formId: formId,
        nationalDex: data.toNationalDex,
        nameZh: data.toNameZh,
        formNameZh: formLabel,
        isDefaultForm: data.toIsDefaultForm,
        typeIds: data.toTypeIds,
        thumbAsset: data.toThumbAsset,
        children: [
          for (final edge
              in outEdgesByForm[formId] ?? const <EvolutionEdgeData>[])
            edge.toDomain(),
        ],
      );
    }

    final nodesByFormId = {
      for (final formId in displayByForm.keys) formId: nodeOf(formId),
    };
    final nodesBySpeciesId = <int, EvolutionNode>{};
    for (final node in nodesByFormId.values) {
      final prev = nodesBySpeciesId[node.speciesId];
      if (prev == null || (node.isDefaultForm && !prev.isDefaultForm)) {
        nodesBySpeciesId[node.speciesId] = node;
      }
    }
    final roots = [
      for (final rootEdge in rootEdges) nodesByFormId[rootEdge.toFormId]!,
    ];

    return EvolutionTree(
      root: roots.first,
      nodesBySpeciesId: nodesBySpeciesId,
      roots: roots,
      nodesByFormId: nodesByFormId,
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
  Future<List<int>> getAllSpeciesIds() => _pokedexDao.getAllSpeciesIds();

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) =>
      _pokedexDao.getPokemonSummaries(speciesIds);

  @override
  Future<DataManifest> getManifest() async =>
      DataManifest.fromJson(await _loadManifestJson());
}
