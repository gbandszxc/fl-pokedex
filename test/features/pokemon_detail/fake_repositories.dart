import 'dart:async';

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

/// 妙蛙种子 fixture：
/// - 3 形态：默认（草/毒，种族值 45/49/49/65/65/45，总和 318）、
///   超级（80/82/83/100/100/80，总和 525）、地区形态；
/// - 2 版本图鉴说明：gen1「红」= 简中，gen9「朱」= 仅英文
///   （默认应选中最新含简中的版本，即 gen1）。
class FakePokedexRepository implements PokedexRepository {
  /// 非 null 时 queryPokemon 抛出该错误（整页失败态测试用）。
  Object? queryError;

  final _kSpeciesId = 1;

  final summaries = <PokemonSummary>[
    PokemonSummary(
      speciesId: 1,
      nationalDex: 1,
      nameZh: '妙蛙种子',
      nameEn: 'Bulbasaur',
      nameJa: 'フシギダネ',
      typeIds: ['grass', 'poison'],
      thumbAsset: 'assets/pokemon/thumb/1.webp',
      generationId: 1,
      isLegendary: false,
      isMythical: false,
      isUltraBeast: false,
    ),
  ];

  final forms = <FormSummary>[
    FormSummary(
      formId: 1,
      speciesId: 1,
      formIdentifier: null,
      formNameZh: '妙蛙种子',
      formNameEn: 'Bulbasaur',
      isDefault: true,
      isMega: false,
      isGmax: false,
      isRegional: false,
      artworkAsset: 'assets/pokemon/full/1.webp',
      typeIds: ['grass', 'poison'],
    ),
    FormSummary(
      formId: 10033,
      speciesId: 1,
      formIdentifier: 'mega',
      formNameZh: '超级妙蛙花',
      formNameEn: 'Venusaur Mega',
      isDefault: false,
      isMega: true,
      isGmax: false,
      isRegional: false,
      artworkAsset: null,
      typeIds: ['grass', 'poison'],
    ),
    FormSummary(
      formId: 10195,
      speciesId: 1,
      formIdentifier: 'regional',
      formNameZh: '帕底亚的妙蛙种子',
      formNameEn: 'Bulbasaur Paldea',
      isDefault: false,
      isMega: false,
      isGmax: false,
      isRegional: true,
      artworkAsset: null,
      typeIds: ['grass'],
    ),
  ];

  final statsByFormId = <int, StatBlock>{
    1: const StatBlock(
      hp: 45,
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
    10033: const StatBlock(
      hp: 80,
      attack: 82,
      defense: 83,
      specialAttack: 100,
      specialDefense: 100,
      speed: 80,
    ),
    10195: const StatBlock(
      hp: 50,
      attack: 51,
      defense: 50,
      specialAttack: 66,
      specialDefense: 66,
      speed: 46,
    ),
  };

  final abilitiesByFormId = <int, List<AbilityRef>>{
    1: [
      AbilityRef(id: 65, nameZh: '茂盛', nameEn: 'Overgrow', isHidden: false),
      AbilityRef(id: 34, nameZh: '叶绿素', nameEn: 'Chlorophyll', isHidden: true),
    ],
  };

  final flavorTexts = <FlavorEntry>[
    FlavorEntry(
      versionId: 1,
      versionIdentifier: 'red',
      versionNameZh: '红',
      versionNameEn: 'Red',
      generationId: 1,
      language: 'zh_hans',
      text: '种子在出生时埋在土里。',
    ),
    FlavorEntry(
      versionId: 28,
      versionIdentifier: 'scarlet',
      versionNameZh: '朱',
      versionNameEn: 'Scarlet',
      generationId: 9,
      language: 'en',
      text: 'It can go for days without eating.',
    ),
  ];

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) async {
    final error = queryError;
    if (error != null) {
      throw error;
    }
    final matched = (f.dexMin != null && f.dexMax != null)
        ? summaries
            .where((s) =>
                s.nationalDex >= f.dexMin! && s.nationalDex <= f.dexMax!)
            .toList()
        : summaries;
    return matched.skip(offset).take(limit).toList();
  }

  @override
  Future<int> countPokemon(FilterState f) async => summaries.length;

  @override
  Future<List<FormSummary>> getForms(int speciesId) async {
    if (speciesId != _kSpeciesId) {
      throw StateError('fixture 只有 species $_kSpeciesId');
    }
    return forms;
  }

  @override
  Future<StatBlock> getFormStats(int formId) async =>
      statsByFormId[formId] ??
      (throw StateError('fixture 没有 form $formId 的种族值'));

  @override
  Future<List<AbilityRef>> getFormAbilities(int formId) async =>
      abilitiesByFormId[formId] ?? const <AbilityRef>[];

  @override
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) async {
    if (speciesId != _kSpeciesId) {
      throw StateError('fixture 只有 species $_kSpeciesId');
    }
    return flavorTexts;
  }

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
  Future<List<GenerationRef>> getGenerations() =>
      throw UnimplementedError();

  @override
  Future<List<PokedexRef>> getPokedexes() => throw UnimplementedError();

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) =>
      throw UnimplementedError();

  @override
  Future<DataManifest> getManifest() => throw UnimplementedError();
}

/// 收藏 / 最近浏览 fixture：记录调用并推送流。
class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository({Set<int> initialFavorites = const {}})
      : _favorites = {...initialFavorites};

  final Set<int> _favorites;
  final _changes = StreamController<List<int>>.broadcast();

  /// toggleFavorite 收到的 speciesId（按调用顺序）。
  final List<int> toggled = [];

  /// addRecent 收到的 speciesId（按调用顺序）。
  final List<int> recentsAdded = [];

  /// 注入初始收藏（在仓储被 watch 之前调用）。
  void seed(Set<int> speciesIds) => _favorites.addAll(speciesIds);

  @override
  Stream<List<int>> watchFavoriteSpeciesIds() async* {
    // 先吐当前状态，再接后续变更（broadcast 流不加历史回放）。
    yield _favorites.toList(growable: false);
    yield* _changes.stream;
  }

  @override
  Future<void> toggleFavorite(int speciesId) async {
    toggled.add(speciesId);
    if (!_favorites.remove(speciesId)) {
      _favorites.add(speciesId);
    }
    _changes.add(_favorites.toList(growable: false));
  }

  @override
  Future<void> addRecent(int speciesId) async {
    recentsAdded.add(speciesId);
  }

  @override
  Stream<List<int>> watchRecentSpeciesIds() => const Stream.empty();

  void dispose() => _changes.close();
}
