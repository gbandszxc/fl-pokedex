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
  Future<List<PokedexRef>> getPokedexes() async => const [
        // 模拟真实 DB 形态（assets/database/pokedex.db）：同名多条、
        // 白名单外的子图鉴（岛图鉴）、与裸名兜底行（旧版白名单缺陷）。
        PokedexRef(id: 2, identifier: 'kanto', nameZh: '关都图鉴', generationId: 1),
        PokedexRef(
          id: 3,
          identifier: 'original-johto',
          nameZh: '城都图鉴',
          generationId: 2,
        ),
        PokedexRef(
          id: 7,
          identifier: 'updated-johto',
          nameZh: '城都图鉴',
          generationId: 2,
        ),
        PokedexRef(id: 4, identifier: 'hoenn', nameZh: '丰缘图鉴', generationId: 3),
        PokedexRef(
          id: 5,
          identifier: 'original-sinnoh',
          nameZh: '神奥图鉴',
          generationId: 4,
        ),
        PokedexRef(
          id: 6,
          identifier: 'extended-sinnoh',
          nameZh: '神奥图鉴',
          generationId: 4,
        ),
        PokedexRef(
          id: 8,
          identifier: 'original-unova',
          nameZh: '合众图鉴',
          generationId: 5,
        ),
        PokedexRef(
          id: 12,
          identifier: 'kalos-central',
          nameZh: '卡洛斯图鉴',
          generationId: 6,
        ),
        PokedexRef(
          id: 13,
          identifier: 'kalos-coastal',
          nameZh: '卡洛斯图鉴',
          generationId: 6,
        ),
        PokedexRef(
          id: 14,
          identifier: 'kalos-mountain',
          nameZh: '卡洛斯图鉴',
          generationId: 6,
        ),
        PokedexRef(
          id: 16,
          identifier: 'original-alola',
          nameZh: '阿罗拉图鉴',
          generationId: 7,
        ),
        // 岛图鉴子图鉴：不在地区分组白名单内。
        PokedexRef(
          id: 17,
          identifier: 'original-melemele',
          nameZh: '阿罗拉图鉴',
          generationId: 7,
        ),
        PokedexRef(id: 27, identifier: 'galar', nameZh: '伽勒尔图鉴', generationId: 8),
        PokedexRef(id: 30, identifier: 'hisui', nameZh: '洗翠图鉴', generationId: 8),
        PokedexRef(id: 31, identifier: 'paldea', nameZh: '帕底亚图鉴', generationId: 9),
        // 裸名行：旧版白名单曾匹配的形态，DB 中并不存在，
        // 留在 fixture 里验证白名单不再被它命中。
        PokedexRef(id: 99, identifier: 'johto', nameZh: '城都（裸名）', generationId: 2),
      ];

  @override
  Future<List<int>> getAllSpeciesIds() async =>
      // 合成数据 _all 按编号生成；排序保证 national_dex 升序契约。
      [
        for (final summary in _all) summary.speciesId,
      ]..sort();

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
