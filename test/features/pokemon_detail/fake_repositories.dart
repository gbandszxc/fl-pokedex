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
/// - 3 形态：默认（草/毒，种族值 45/49/49/65/65/45，总和 318，0.7m/6.9kg）、
///   超级（总和 525，2.4m/155.5kg）、地区形态（身高 0 / 体重缺失 → —）；
/// - 2 特性：茂盛（简中+英文说明）、叶绿素（仅英文说明）；
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
      heightM: 0.7,
      weightKg: 6.9,
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
      heightM: 2.4,
      weightKg: 155.5,
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
      // 覆盖「身高 0 / 体重缺失 → 显示 —」的回退分支。
      heightM: 0.0,
      weightKg: null,
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
      const AbilityRef(
        id: 65,
        nameZh: '茂盛',
        nameEn: 'Overgrow',
        isHidden: false,
        descriptionZh: 'HP 较低时，草属性招式威力提高。',
        descriptionEn: 'Powers up Grass-type moves when HP is low.',
      ),
      // 仅英文说明：展开时应出现「暂无简体中文说明」提示。
      const AbilityRef(
        id: 34,
        nameZh: '叶绿素',
        nameEn: 'Chlorophyll',
        isHidden: true,
        descriptionZh: null,
        descriptionEn: 'Boosts Speed in harsh sunlight.',
      ),
    ],
    // 地区形态也有特性，保证资料页不会落入「特性 —」空态。
    10195: [
      const AbilityRef(
        id: 65,
        nameZh: '茂盛',
        nameEn: 'Overgrow',
        isHidden: false,
        descriptionZh: 'HP 较低时，草属性招式威力提高。',
        descriptionEn: 'Powers up Grass-type moves when HP is low.',
      ),
    ],
  };

  /// species 基础信息（C2 接口）。
  final speciesInfo = <int, SpeciesInfo>{
    1: const SpeciesInfo(
      speciesId: 1,
      nationalDex: 1,
      generationId: 1,
      genusZh: '种子宝可梦',
      genusEn: 'Seed Pokémon',
    ),
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
  Future<EvolutionTree?> getEvolutionTree(int speciesId) async =>
      null; // fixture：妙蛙种子简化为无进化链（进化分区显示空态）。

  /// 默认形态有学习集的版本组（招式分区版本组 chips 行用）。
  final versionGroups = <int, List<VersionGroupRef>>{
    1: [
      const VersionGroupRef(
        id: 'scarlet-violet',
        labelZh: '朱/紫',
        generationId: 9,
      ),
    ],
  };

  final learnset = <int, List<MoveEntry>>{
    1: const [
      MoveEntry(
        moveId: 33,
        nameZh: '撞击',
        nameEn: 'Tackle',
        typeId: 'normal',
        damageClass: 'physical',
        power: 40,
        pp: 35,
        accuracy: 100,
        level: 1,
        method: 'level_up',
        versionGroup: 'scarlet-violet',
      ),
      MoveEntry(
        moveId: 73,
        nameZh: '寄生种子',
        nameEn: 'Leech Seed',
        typeId: 'grass',
        damageClass: 'status',
        power: null,
        pp: 10,
        accuracy: 90,
        level: 7,
        method: 'level_up',
        versionGroup: 'scarlet-violet',
      ),
    ],
  };

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) async =>
      versionGroups[formId] ?? const <VersionGroupRef>[];

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) async {
    final all = learnset[formId] ?? const <MoveEntry>[];
    if (methods == null || methods.isEmpty) {
      return all;
    }
    return all.where((move) => methods.contains(move.method)).toList();
  }

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
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) async =>
      speciesInfo[speciesId] ??
      (throw StateError('species 表不存在 id=$speciesId'));

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(
    List<int> speciesIds,
  ) async {
    final error = queryError;
    if (error != null) {
      throw error;
    }
    // 与真实现一致：缺失 id 跳过，按入参顺序返回。
    return [
      for (final id in speciesIds)
        for (final summary in summaries)
          if (summary.speciesId == id) summary,
    ];
  }

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
