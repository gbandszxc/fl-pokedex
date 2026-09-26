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

/// 内存版 PokedexRepository：70 条合成数据，实现 §7 搜索语义的
/// 简化版（编号正则 / 中文名与英文名包含 / 世代 / 属性 any-all /
/// 编号区间 / 特殊标签；地区归属不建模，选中任一地区即空结果）。
class FakePokedexRepository implements PokedexRepository {
  FakePokedexRepository({int count = 70}) {
    for (var dex = 1; dex <= count; dex++) {
      _all.add(_makeSummary(dex));
    }
  }

  final List<PokemonSummary> _all = [];

  /// 最近一次 queryPokemon / countPokemon 收到的 FilterState。
  FilterState? lastFilter;

  /// 全部查询记录（按时间序）。
  final List<FilterState> queryLog = [];

  static PokemonSummary _makeSummary(int dex) {
    final typeCycle = [
      const ['normal'],
      const ['fire'],
      const ['water'],
      const ['grass', 'poison'],
    ];
    final isPikachu = dex == 25;
    return PokemonSummary(
      speciesId: dex,
      nationalDex: dex,
      nameZh: isPikachu ? '皮卡丘' : '宝可梦${dex.toString().padLeft(3, '0')}',
      nameEn: isPikachu ? 'Pikachu' : 'Pokemon${dex.toString().padLeft(3, '0')}',
      nameJa: 'ポケモン$dex',
      typeIds: typeCycle[dex % 4],
      thumbAsset: null,
      generationId: ((dex - 1) ~/ 10) + 1,
      isLegendary: dex == 70,
      isMythical: dex == 69,
      isUltraBeast: false,
    );
  }

  List<PokemonSummary> _apply(FilterState f) {
    final query = f.query.trim();
    final numberMatch = RegExp(r'^#?\d{1,4}$').firstMatch(query);
    final number = numberMatch != null
        ? int.parse(query.replaceFirst('#', ''))
        : null;
    final lowerQuery = query.toLowerCase();

    bool matches(PokemonSummary p) {
      if (number != null) {
        if (p.nationalDex != number) {
          return false;
        }
      } else if (query.isNotEmpty) {
        final inZh = p.nameZh.contains(query);
        final inEn = p.nameEn.toLowerCase().contains(lowerQuery);
        if (!inZh && !inEn) {
          return false;
        }
      }
      if (f.generations.isNotEmpty && !f.generations.contains(p.generationId)) {
        return false;
      }
      if (f.typeIds.isNotEmpty) {
        final hit = f.typeMatchMode == TypeMatchMode.all
            ? f.typeIds.every(p.typeIds.contains)
            : f.typeIds.any(p.typeIds.contains);
        if (!hit) {
          return false;
        }
      }
      if (f.dexMin != null && p.nationalDex < f.dexMin!) {
        return false;
      }
      if (f.dexMax != null && p.nationalDex > f.dexMax!) {
        return false;
      }
      if (f.tags.isNotEmpty) {
        for (final tag in f.tags) {
          final hit = switch (tag) {
            SpecialTag.legendary => p.isLegendary,
            SpecialTag.mythical => p.isMythical,
            SpecialTag.ultraBeast => p.isUltraBeast,
            // mega / gmax / regional 不在 summary 上建模。
            _ => false,
          };
          if (!hit) {
            return false;
          }
        }
      }
      if (f.pokedexIds.isNotEmpty) {
        // 未建模地区归属：选中地区 → 无结果。
        return false;
      }
      return true;
    }

    final filtered = _all.where(matches).toList()
      ..sort((a, b) => a.nationalDex.compareTo(b.nationalDex));
    return filtered;
  }

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) async {
    lastFilter = f;
    queryLog.add(f);
    final filtered = _apply(f);
    if (offset >= filtered.length) {
      return const [];
    }
    final end = (offset + limit).clamp(offset, filtered.length);
    return filtered.sublist(offset, end);
  }

  @override
  Future<int> countPokemon(FilterState f) async {
    lastFilter = f;
    queryLog.add(f);
    return _apply(f).length;
  }

  @override
  Future<List<TypeRef>> getTypes() async => const [
        TypeRef(id: 'normal', nameZh: '一般'),
        TypeRef(id: 'fire', nameZh: '火'),
        TypeRef(id: 'water', nameZh: '水'),
        TypeRef(id: 'grass', nameZh: '草'),
        TypeRef(id: 'poison', nameZh: '毒'),
      ];

  @override
  Future<List<GenerationRef>> getGenerations() async => [
        for (var i = 1; i <= 9; i++)
          GenerationRef(id: i, identifier: 'generation-$i', region: '地区$i'),
      ];

  @override
  Future<List<PokedexRef>> getPokedexes() async => [
        const PokedexRef(id: 1, identifier: 'kanto', nameZh: '关都', generationId: 1),
        const PokedexRef(
          id: 2,
          identifier: 'kanto-updated',
          nameZh: '关都·修订',
          generationId: 1,
        ),
        const PokedexRef(id: 3, identifier: 'johto', nameZh: '城都', generationId: 2),
        const PokedexRef(id: 4, identifier: 'hoenn', nameZh: '丰缘', generationId: 3),
        const PokedexRef(
          id: 5,
          identifier: 'extended-sinnoh',
          nameZh: '神奥·扩展',
          generationId: 4,
        ),
      ];

  @override
  Future<DataManifest> getManifest() async => DataManifest(
        schemaVersion: 1,
        dataVersion: 'test',
        pokemonCount: _all.length,
        formCount: 0,
        moveCount: 0,
        abilityCount: 0,
        versionCount: 0,
        buildDate: '2026-01-01',
        upstreamRevision: const {},
        learnsetVersionGroups: const [],
        missingArtwork: const [],
      );

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
  Future<List<FlavorEntry>> getFormFlavorTexts(int formId) =>
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
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) =>
      throw UnimplementedError();
}

/// 内存版 FavoritesRepository：初始收藏 + 广播流推变更，记录 recents。
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({List<int> initialFavorites = const []}) {
    _favorites.addAll(initialFavorites);
  }

  final List<int> _favorites = [];
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
  required FakePokedexRepository pokedex,
  required FakeFavoritesRepository favorites,
}) =>
    [
      pokedexRepositoryProvider.overrideWithValue(pokedex),
      favoritesRepositoryProvider.overrideWithValue(favorites),
    ];
