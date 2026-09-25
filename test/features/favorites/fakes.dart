import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/domain/models/ability_ref.dart';
import 'package:fl_pokedex/domain/models/evolution.dart';
import 'package:fl_pokedex/domain/models/filters.dart';
import 'package:fl_pokedex/domain/models/flavor_entry.dart';
import 'package:fl_pokedex/domain/models/form_summary.dart';
import 'package:fl_pokedex/domain/models/manifest.dart';
import 'package:fl_pokedex/domain/models/move_detail.dart';
import 'package:fl_pokedex/domain/models/move_entry.dart';
import 'package:fl_pokedex/domain/models/pokemon_summary.dart';
import 'package:fl_pokedex/domain/models/refs.dart';
import 'package:fl_pokedex/domain/models/species_info.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';
import 'package:fl_pokedex/domain/repositories/favorites_repository.dart';
import 'package:fl_pokedex/domain/repositories/pokedex_repository.dart';

/// 构造最小 [PokemonSummary]（测试数据工厂）。
PokemonSummary makeSummary({
  required int speciesId,
  String nameZh = '宝可梦',
  String nameEn = 'Pokemon',
  List<String> typeIds = const ['normal'],
}) {
  return PokemonSummary(
    speciesId: speciesId,
    nationalDex: speciesId,
    nameZh: nameZh,
    nameEn: nameEn,
    nameJa: 'ポケモン$speciesId',
    typeIds: typeIds,
    thumbAsset: null,
    generationId: 1,
    isLegendary: false,
    isMythical: false,
    isUltraBeast: false,
  );
}

/// 内存版 PokedexRepository：仅实现收藏页 / 设置页用到的
/// getPokemonSummaries（按入参顺序返回，缺失跳过）与 getManifest，
/// 其余方法抛 UnimplementedError。
class FakeSummariesPokedexRepository implements PokedexRepository {
  FakeSummariesPokedexRepository(
    Map<int, PokemonSummary> summaries, {
    DataManifest? manifest,
    Object? manifestError,
  })  : _summaries = Map.of(summaries),
        _manifest = manifest ?? _defaultManifest,
        _manifestError = manifestError;

  final Map<int, PokemonSummary> _summaries;
  final DataManifest _manifest;

  /// 非 null 时 getManifest 抛出该错误（模拟读取失败）。
  final Object? _manifestError;

  /// 每次调用收到的入参（按时间序）。
  final List<List<int>> summariesCalls = [];

  static DataManifest get _defaultManifest => const DataManifest(
        schemaVersion: 1,
        dataVersion: 'pokeapi@test',
        pokemonCount: 1025,
        formCount: 1351,
        moveCount: 937,
        abilityCount: 374,
        versionCount: 53,
        buildDate: '2026-09-25T10:00:00+00:00',
        upstreamRevision: {},
        learnsetVersionGroups: [],
        missingArtwork: [],
      );

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) async {
    summariesCalls.add(List<int>.of(speciesIds));
    return [
      for (final id in speciesIds)
        if (_summaries[id] != null) _summaries[id]!,
    ];
  }

  @override
  Future<DataManifest> getManifest() async {
    final error = _manifestError;
    if (error != null) {
      throw error;
    }
    return _manifest;
  }

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> countPokemon(FilterState f) => throw UnimplementedError();

  @override
  Future<List<FormSummary>> getForms(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<StatBlock> getFormStats(int formId) => throw UnimplementedError();

  @override
  Future<List<AbilityRef>> getFormAbilities(int formId) =>
      throw UnimplementedError();

  @override
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) =>
      throw UnimplementedError();

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) =>
      throw UnimplementedError();

  @override
  Future<MoveDetail?> getMoveDetail(int moveId) =>
      throw UnimplementedError();

  @override
  Future<List<TypeRef>> getTypes() => throw UnimplementedError();

  @override
  Future<List<GenerationRef>> getGenerations() => throw UnimplementedError();

  @override
  Future<List<PokedexRef>> getPokedexes() => throw UnimplementedError();

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) =>
      throw UnimplementedError();
}

/// 内存版 FavoritesRepository：初始收藏 / 最近浏览 + 广播流推变更。
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({
    List<int> initialFavorites = const [],
    List<int> initialRecents = const [],
  }) {
    _favorites.addAll(initialFavorites);
    recents.addAll(initialRecents);
  }

  final List<int> _favorites = [];

  /// 最近浏览（最新在尾部，语义与仓储一致）。
  final List<int> recents = [];

  final _favoriteChanges = StreamController<List<int>>.broadcast();
  final _recentChanges = StreamController<List<int>>.broadcast();

  /// 当前收藏（拷贝）。
  List<int> get favorites => List<int>.of(_favorites);

  void emitFavorites() {
    if (!_favoriteChanges.isClosed) {
      _favoriteChanges.add(List<int>.of(_favorites));
    }
  }

  void dispose() {
    _favoriteChanges.close();
    _recentChanges.close();
  }

  @override
  Stream<List<int>> watchFavoriteSpeciesIds() async* {
    yield List<int>.of(_favorites);
    yield* _favoriteChanges.stream;
  }

  @override
  Future<void> toggleFavorite(int speciesId) async {
    if (!_favorites.remove(speciesId)) {
      _favorites.add(speciesId);
    }
    emitFavorites();
  }

  @override
  Stream<List<int>> watchRecentSpeciesIds() async* {
    yield List<int>.of(recents);
    yield* _recentChanges.stream;
  }

  @override
  Future<void> addRecent(int speciesId) async {
    recents
      ..remove(speciesId)
      ..add(speciesId);
    if (!_recentChanges.isClosed) {
      _recentChanges.add(List<int>.of(recents));
    }
  }
}

/// 测试装配：用 Fake 覆盖 [pokedexRepositoryProvider] 与
/// [favoritesRepositoryProvider]。
List<Override> fakeRepositoryOverrides({
  required FakeSummariesPokedexRepository pokedex,
  required FakeFavoritesRepository favorites,
}) =>
    [
      pokedexRepositoryProvider.overrideWithValue(pokedex),
      favoritesRepositoryProvider.overrideWithValue(favorites),
    ];

/// 仅覆盖图鉴仓储（设置页等不依赖个人数据的场景）。
Override pokedexRepositoryOverride(FakeSummariesPokedexRepository pokedex) =>
    pokedexRepositoryProvider.overrideWithValue(pokedex);
