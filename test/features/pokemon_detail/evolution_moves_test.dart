import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/data/database/pokedex_database.dart';
import 'package:fl_pokedex/data/repository/pokedex_repository_impl.dart';
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
import 'package:fl_pokedex/domain/repositories/pokedex_repository.dart';
import 'package:fl_pokedex/features/moves/move_detail_page.dart';
import 'package:fl_pokedex/features/pokemon_detail/evolution_layout.dart';
import 'package:fl_pokedex/features/pokemon_detail/evolution_section_placeholder.dart';
import 'package:fl_pokedex/features/pokemon_detail/learnset_filter.dart'
    show MoveSort;
import 'package:fl_pokedex/features/pokemon_detail/moves_section_placeholder.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import '../../helpers/sqlite_loader.dart';
import 'fake_repositories.dart' show FakeFavoritesRepository;

/// 进化 / 招式 fixtures（伊布 8 分支 + 绿毛虫三段链 + 呆呆兽分支）。
class FakeEvolutionMovesRepository implements PokedexRepository {
  /// 注入自定义版本组列表（chips 自动换行回归需要多组长标签组）；
  /// 缺省时沿用 [_versionGroups] 的朱/紫 + 剑/盾。
  FakeEvolutionMovesRepository({List<VersionGroupRef>? versionGroups})
      : _versionGroupOverride = versionGroups;

  final List<VersionGroupRef>? _versionGroupOverride;

  /// getLearnset 收到的 (versionGroup, methods) 调用记录。
  final learnsetQueryLog = <(String, Set<String>?)>[];

  EvolutionEdge _edge(
    int from,
    int to, {
    int? fromForm,
    int? toForm,
    String trigger = 'level-up',
    int? minLevel,
    String? item,
    String? heldItem,
    String? knownMove,
    String? knownMoveType,
    String? location,
    String? region,
    String? timeOfDay,
    int? minHappiness,
    int? minAffection,
  }) {
    return EvolutionEdge(
      chainId: 1,
      fromSpeciesId: from,
      toSpeciesId: to,
      fromFormId: fromForm,
      toFormId: toForm,
      trigger: trigger,
      minLevel: minLevel,
      item: item,
      heldItem: heldItem,
      knownMove: knownMove,
      knownMoveType: knownMoveType,
      location: location,
      region: region,
      timeOfDay: timeOfDay,
      minHappiness: minHappiness,
      minAffection: minAffection,
      needsRain: false,
      turnUpsideDown: false,
    );
  }

  /// members 插入序即链序（首个为根）。
  EvolutionTree _chain(
    Map<int, String> members,
    Map<int, List<EvolutionEdge>> edgesByFrom,
  ) {
    final nodes = <int, EvolutionNode>{
      for (final entry in members.entries)
        entry.key: EvolutionNode(
          speciesId: entry.key,
          nationalDex: entry.key,
          nameZh: entry.value,
          thumbAsset: null,
          children: edgesByFrom[entry.key] ?? const <EvolutionEdge>[],
        ),
    };
    return EvolutionTree(
      root: nodes.values.first,
      nodesBySpeciesId: nodes,
    );
  }

  late final EvolutionTree eeveeTree = _chain(
    const {
      133: '伊布',
      134: '水伊布',
      135: '雷伊布',
      136: '火伊布',
      196: '太阳伊布',
      197: '月亮伊布',
      470: '叶伊布',
      471: '冰伊布',
      700: '仙子伊布',
    },
    {
      133: [
        _edge(133, 134, trigger: 'use-item', item: 'water-stone'),
        _edge(133, 135, trigger: 'use-item', item: 'thunder-stone'),
        _edge(133, 136, trigger: 'use-item', item: 'fire-stone'),
        _edge(133, 196, minHappiness: 220, timeOfDay: 'day'),
        _edge(133, 197, minHappiness: 220, timeOfDay: 'night'),
        _edge(133, 470, knownMove: 'rollout'),
        _edge(133, 471, location: 'ice-rock'),
        _edge(133, 700, knownMoveType: 'fairy', minAffection: 2),
      ],
    },
  );

  late final EvolutionTree caterpieTree = _chain(
    const {10: '绿毛虫', 11: '铁甲蛹', 12: '巴大蝶'},
    {
      10: [_edge(10, 11, minLevel: 10)],
      11: [_edge(11, 12, minLevel: 16)],
    },
  );

  late final EvolutionTree slowpokeTree = _chain(
    const {79: '呆呆兽', 80: '呆壳兽', 199: '呆呆王'},
    {
      79: [
        _edge(79, 80, minLevel: 37),
        _edge(79, 199, trigger: 'trade', heldItem: 'kings-rock'),
      ],
    },
  );

  /// 无进化链（root 无孩子）：拉普拉斯真实无进化关系，覆盖空态的
  /// `tree.root.children.isEmpty` 分支；`getEvolutionTree` 返回 null
  /// 的分支由未收录 speciesId 天然覆盖，无需 fixture。
  late final EvolutionTree laprasTree = _chain(
    const {131: '拉普拉斯'},
    const {},
  );

  /// 形态级进化树：魔尼尼(439) → 魔墙人偶(122/其他地区) &
  /// 魔墙人偶(10168/伽勒尔地区) → 踏冰人偶(866/Lv.42)。
  late final EvolutionTree mrMimeTree = () {
    final mimeJr = EvolutionNode(
      speciesId: 439,
      formId: 439,
      nationalDex: 439,
      nameZh: '魔尼尼',
      isDefaultForm: true,
      typeIds: const ['psychic', 'fairy'],
      children: [
        _edge(439, 122, fromForm: 439, toForm: 122, knownMove: 'mimic'),
        _edge(
          439,
          122,
          fromForm: 439,
          toForm: 10168,
          knownMove: 'mimic',
          region: 'galar',
        ),
      ],
    );
    const defaultMime = EvolutionNode(
      speciesId: 122,
      formId: 122,
      nationalDex: 122,
      nameZh: '魔墙人偶',
      isDefaultForm: true,
      typeIds: ['psychic', 'fairy'],
      children: <EvolutionEdge>[],
    );
    final galarMime = EvolutionNode(
      speciesId: 122,
      formId: 10168,
      nationalDex: 122,
      nameZh: '魔墙人偶',
      formNameZh: '伽勒尔的样子',
      isDefaultForm: false,
      typeIds: const ['ice', 'psychic'],
      children: [
        _edge(122, 866, fromForm: 10168, toForm: 866, minLevel: 42),
      ],
    );
    const mrRime = EvolutionNode(
      speciesId: 866,
      formId: 866,
      nationalDex: 866,
      nameZh: '踏冰人偶',
      isDefaultForm: true,
      typeIds: ['ice', 'psychic'],
      children: <EvolutionEdge>[],
    );
    return EvolutionTree(
      root: mimeJr,
      roots: [mimeJr],
      nodesBySpeciesId: {
        439: mimeJr,
        122: defaultMime,
        866: mrRime,
      },
      nodesByFormId: {
        439: mimeJr,
        122: defaultMime,
        10168: galarMime,
        866: mrRime,
      },
    );
  }();

  /// 仅非默认形态可进化：大葱鸭(83 未收录进树，仅伽勒尔的样子 10166 → 葱游兵 865)。
  late final EvolutionTree farfetchdTree = () {
    final galarRoot = EvolutionNode(
      speciesId: 83,
      formId: 10166,
      nationalDex: 83,
      nameZh: '大葱鸭',
      formNameZh: '伽勒尔的样子',
      isDefaultForm: false,
      typeIds: const ['fighting'],
      children: [
        _edge(
          83,
          865,
          fromForm: 10166,
          toForm: 865,
          trigger: 'three-critical-hits',
        ),
      ],
    );
    const sirfetchd = EvolutionNode(
      speciesId: 865,
      formId: 865,
      nationalDex: 865,
      nameZh: '葱游兵',
      isDefaultForm: true,
      typeIds: ['fighting'],
      children: <EvolutionEdge>[],
    );
    return EvolutionTree(
      root: galarRoot,
      roots: [galarRoot],
      nodesBySpeciesId: {83: galarRoot, 865: sirfetchd},
      nodesByFormId: {10166: galarRoot, 865: sirfetchd},
    );
  }();

  /// 多根并行链：喵喵 3 根（关都→猫老大 / 阿罗拉→阿罗拉猫老大 / 伽勒尔→喵头目）。
  late final EvolutionTree meowthTree = () {
    final kantoMeowth = EvolutionNode(
      speciesId: 52,
      formId: 52,
      nationalDex: 52,
      nameZh: '喵喵',
      isDefaultForm: true,
      typeIds: const ['normal'],
      children: [_edge(52, 53, fromForm: 52, toForm: 53, minLevel: 28)],
    );
    const kantoPersian = EvolutionNode(
      speciesId: 53,
      formId: 53,
      nationalDex: 53,
      nameZh: '猫老大',
      isDefaultForm: true,
      typeIds: ['normal'],
      children: <EvolutionEdge>[],
    );
    final alolaMeowth = EvolutionNode(
      speciesId: 52,
      formId: 10107,
      nationalDex: 52,
      nameZh: '喵喵',
      formNameZh: '阿罗拉的样子',
      isDefaultForm: false,
      typeIds: const ['dark'],
      children: [
        _edge(52, 53, fromForm: 10107, toForm: 10108, minHappiness: 160),
      ],
    );
    const alolaPersian = EvolutionNode(
      speciesId: 53,
      formId: 10108,
      nationalDex: 53,
      nameZh: '猫老大',
      formNameZh: '阿罗拉的样子',
      isDefaultForm: false,
      typeIds: ['dark'],
      children: <EvolutionEdge>[],
    );
    final galarMeowth = EvolutionNode(
      speciesId: 52,
      formId: 10161,
      nationalDex: 52,
      nameZh: '喵喵',
      formNameZh: '伽勒尔的样子',
      isDefaultForm: false,
      typeIds: const ['steel'],
      children: [_edge(52, 863, fromForm: 10161, toForm: 863, minLevel: 28)],
    );
    const perrserker = EvolutionNode(
      speciesId: 863,
      formId: 863,
      nationalDex: 863,
      nameZh: '喵头目',
      isDefaultForm: true,
      typeIds: ['steel'],
      children: <EvolutionEdge>[],
    );
    return EvolutionTree(
      root: kantoMeowth,
      roots: [kantoMeowth, alolaMeowth, galarMeowth],
      nodesBySpeciesId: {
        52: kantoMeowth,
        53: kantoPersian,
        863: perrserker,
      },
      nodesByFormId: {
        52: kantoMeowth,
        53: kantoPersian,
        10107: alolaMeowth,
        10108: alolaPersian,
        10161: galarMeowth,
        863: perrserker,
      },
    );
  }();

  EvolutionTree? _treeFor(int speciesId) {
    for (final tree in [
      eeveeTree,
      caterpieTree,
      slowpokeTree,
      laprasTree,
      mrMimeTree,
      farfetchdTree,
      meowthTree,
    ]) {
      if (tree.nodesBySpeciesId.containsKey(speciesId)) return tree;
    }
    return null;
  }

  final _summaries = <PokemonSummary>[
    const PokemonSummary(
      speciesId: 133,
      nationalDex: 133,
      nameZh: '伊布',
      nameEn: 'Eevee',
      nameJa: 'イーブイ',
      typeIds: ['normal'],
      thumbAsset: null,
      generationId: 1,
      isLegendary: false,
      isMythical: false,
      isUltraBeast: false,
    ),
  ];

  final _forms = <int, List<FormSummary>>{
    133: [
      FormSummary(
        formId: 6133,
        speciesId: 133,
        formIdentifier: null,
        formNameZh: '伊布',
        formNameEn: 'Eevee',
        isDefault: true,
        isMega: false,
        isGmax: false,
        isRegional: false,
        artworkAsset: null,
        typeIds: const ['normal'],
      ),
    ],
  };

  final _versionGroups = <int, List<VersionGroupRef>>{
    6133: const [
      VersionGroupRef(id: 'scarlet-violet', labelZh: '朱/紫', generationId: 9),
      VersionGroupRef(id: 'sword-shield', labelZh: '剑/盾', generationId: 8),
    ],
  };

  /// 刻意乱序：默认排序（level）与 power 排序都能看出变化。
  final _learnsets = <String, List<MoveEntry>>{
    'scarlet-violet': [
      MoveEntry(
        moveId: 1,
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
        moveId: 4,
        nameZh: '变硬',
        nameEn: 'Harden',
        typeId: 'normal',
        damageClass: 'status',
        pp: 30,
        level: 1,
        method: 'level_up',
        versionGroup: 'scarlet-violet',
      ),
      MoveEntry(
        moveId: 2,
        nameZh: '电击',
        nameEn: 'Thunder Shock',
        typeId: 'electric',
        damageClass: 'special',
        power: 40,
        pp: 30,
        accuracy: 100,
        level: 5,
        method: 'level_up',
        versionGroup: 'scarlet-violet',
      ),
      MoveEntry(
        moveId: 5,
        nameZh: '剑舞',
        nameEn: 'Swords Dance',
        typeId: 'normal',
        damageClass: 'status',
        pp: 20,
        method: 'machine',
        versionGroup: 'scarlet-violet',
      ),
      MoveEntry(
        moveId: 3,
        nameZh: '十万伏特',
        nameEn: 'Thunderbolt',
        typeId: 'electric',
        damageClass: 'special',
        power: 90,
        pp: 15,
        accuracy: 100,
        method: 'machine',
        versionGroup: 'scarlet-violet',
      ),
      MoveEntry(
        moveId: 6,
        nameZh: '撒娇',
        nameEn: 'Charm',
        typeId: 'fairy',
        damageClass: 'status',
        pp: 20,
        accuracy: 100,
        method: 'tutor',
        versionGroup: 'scarlet-violet',
      ),
    ],
    'sword-shield': [
      MoveEntry(
        moveId: 1,
        nameZh: '撞击',
        nameEn: 'Tackle',
        typeId: 'normal',
        damageClass: 'physical',
        power: 40,
        pp: 35,
        accuracy: 100,
        level: 1,
        method: 'level_up',
        versionGroup: 'sword-shield',
      ),
      MoveEntry(
        moveId: 7,
        nameZh: '挖洞',
        nameEn: 'Dig',
        typeId: 'ground',
        damageClass: 'physical',
        power: 80,
        pp: 10,
        accuracy: 100,
        method: 'machine',
        versionGroup: 'sword-shield',
      ),
    ],
  };

  final _moveDetails = <int, MoveDetail>{
    1: const MoveDetail(
      id: 1,
      nameZh: '撞击',
      nameEn: 'Tackle',
      nameJa: 'たいあたり',
      typeId: 'normal',
      damageClass: 'physical',
      power: 40,
      pp: 35,
      accuracy: 100,
      priority: 0,
      effectEn: 'A physical charging attack.',
      flavorZh: '用整个身体撞上去，简单可靠。',
      generationId: 1,
    ),
    2: const MoveDetail(
      id: 2,
      nameZh: '电击',
      nameEn: 'Thunder Shock',
      nameJa: 'でんきショック',
      typeId: 'electric',
      damageClass: 'special',
      power: 40,
      pp: 30,
      accuracy: 100,
      priority: 0,
      effectChance: 10,
      effectEn:
          'Has a \$effect_chance% chance to paralyze the target.',
      generationId: 1,
    ),
  };

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) async {
    final matched = (f.dexMin != null && f.dexMax != null)
        ? _summaries
            .where((s) =>
                s.nationalDex >= f.dexMin! && s.nationalDex <= f.dexMax!)
            .toList()
        : _summaries;
    return matched.skip(offset).take(limit).toList();
  }

  @override
  Future<int> countPokemon(FilterState f) async => _summaries.length;

  @override
  Future<List<FormSummary>> getForms(int speciesId) async =>
      _forms[speciesId] ?? (throw StateError('fixture 没有 species $speciesId'));

  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) async =>
      _treeFor(speciesId);

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) async =>
      _versionGroupOverride ??
      _versionGroups[formId] ??
      const <VersionGroupRef>[];

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) async {
    learnsetQueryLog.add((
      versionGroup,
      methods == null ? null : <String>{...methods},
    ));
    final moves = _learnsets[versionGroup] ?? const <MoveEntry>[];
    if (methods == null || methods.isEmpty) return moves;
    return moves.where((m) => methods.contains(m.method)).toList();
  }

  @override
  Future<MoveDetail?> getMoveDetail(int moveId) async =>
      _moveDetails[moveId];

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
  Future<List<TypeRef>> getTypes() => throw UnimplementedError();

  @override
  Future<List<GenerationRef>> getGenerations() => throw UnimplementedError();

  @override
  Future<List<PokedexRef>> getPokedexes() => throw UnimplementedError();

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) async {
    if (_treeFor(speciesId) == null && speciesId != 133) {
      throw StateError('fixture 没有 species $speciesId');
    }
    return SpeciesInfo(
      speciesId: speciesId,
      nationalDex: speciesId,
      generationId: 1,
    );
  }

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) async {
    // 单条 IN 查询语义：按入参顺序返回，缺失的 id 跳过。
    return [
      for (final id in speciesIds)
        ..._summaries.where((s) => s.speciesId == id),
    ];
  }

  @override
  Future<List<int>> getAllSpeciesIds() => throw UnimplementedError();

  @override
  Future<DataManifest> getManifest() => throw UnimplementedError();
}

void main() {
  late FakeEvolutionMovesRepository repo;

  setUp(() {
    repo = FakeEvolutionMovesRepository();
  });

  /// 挂载一个分区到 /pokemon/:speciesId 路由下；speciesId 与路由参数
  /// 一致地经 [section] 显式传给分区（真实页面同样显式传 detail.speciesId，
  /// 分区不再从路由读取）。
  Future<void> pumpSection(
    WidgetTester tester, {
    required Widget Function(int speciesId) section,
    required int speciesId,
    Size size = const Size(800, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/pokemon/$speciesId',
      routes: [
        GoRoute(
          path: '/pokemon/:speciesId',
          // 分区在真实页面中位于 Scaffold body 内（Material 祖先），
          // harness 保持同构。
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: Builder(builder: (context) => section(speciesId)),
            ),
          ),
        ),
        GoRoute(
          path: '/move/:moveId',
          builder: (context, state) {
            final moveId = int.tryParse(state.pathParameters['moveId'] ?? '');
            return moveId == null
                ? const MoveDetailPage.notFound()
                : MoveDetailPage(moveId: moveId);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [pokedexRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    // 有界泵帧代替 pumpAndSettle（加载骨架有循环动画）；
    // 分区数据链多层异步（详情 → 版本组 → 学习集），泵足 5 帧。
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// 展开来源分组：默认视图只展开首个分组（升级），跨来源断言前先展开目标组。
  Future<void> expandGroup(WidgetTester tester, String method) async {
    final header = find.byKey(ValueKey('move_group_header_$method'));
    await tester.ensureVisible(header);
    await tester.pump();
    await tester.tap(header);
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// 节点卡底色（经名字向上找最近一个带 ShapeDecoration 的 Container）。
  Color cardColorOf(WidgetTester tester, String name) {
    final finder = find.ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is ShapeDecoration,
      ),
    );
    final decoration =
        tester.widget<Container>(finder.first).decoration! as ShapeDecoration;
    return decoration.color!;
  }

  /// 节点卡外框 rect（经名字向上找最近一个带 ShapeDecoration 的
  /// Container；与 [cardColorOf] 同一查找路径）。
  Rect cardRectOf(WidgetTester tester, String name) {
    final finder = find.ancestor(
      of: find.text(name),
      matching: find.byWidgetPredicate(
        (w) => w is Container && w.decoration is ShapeDecoration,
      ),
    );
    return tester.getRect(finder.first);
  }

  /// 路由栈顶地址（经 context 反查 pumpSection 内构造的 GoRouter）。
  /// 注意用 [RouteMatch.matchedLocation] 而非 `currentConfiguration.uri`：
  /// 后者不含 `push` 产生的 ImperativeRouteMatch（同 two_pane_test 的做法）。
  String currentLocation(WidgetTester tester) {
    // push 后树上会有新旧两个分区实例，.first 恒为旧页面（必然存在）；
    // InheritedGoRouter 由 MaterialApp.router 共享，任一 context 均可达。
    final element = tester.element(
      find.byType(EvolutionSectionPlaceholder).first,
    );
    return GoRouter.of(element)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;
  }

  String currentUri(WidgetTester tester) {
    final element = tester.element(
      find.byType(EvolutionSectionPlaceholder).last,
    );
    return GoRouterState.of(element).uri.toString();
  }

  group('进化布局纯逻辑', () {
    test('isLinearEvolutionChain：纯线性三阶链为 true', () {
      expect(isLinearEvolutionChain(repo.caterpieTree), isTrue);
    });

    test('isLinearEvolutionChain：伊布型 1 根 8 分支为 false', () {
      expect(isLinearEvolutionChain(repo.eeveeTree), isFalse);
    });

    test('isLinearEvolutionChain：二层分叉（根两条出边）为 false', () {
      expect(isLinearEvolutionChain(repo.slowpokeTree), isFalse);
    });

    test('isLinearEvolutionChain：根无孩子视为线性（true，空态由调用方处理）',
        () {
      const loneRoot = EvolutionNode(
        speciesId: 1,
        nationalDex: 1,
        nameZh: '独苗',
        thumbAsset: null,
        children: <EvolutionEdge>[],
      );
      final loneTree = EvolutionTree(
        root: loneRoot,
        nodesBySpeciesId: const {1: loneRoot},
      );
      expect(isLinearEvolutionChain(loneTree), isTrue);
    });

    test('isLinearEvolutionChain：环路数据按链尾终止，不炸不误判', () {
      EvolutionEdge edge(int from, int to) => EvolutionEdge(
            chainId: 1,
            fromSpeciesId: from,
            toSpeciesId: to,
            trigger: 'level-up',
            needsRain: false,
            turnUpsideDown: false,
          );
      final nodeA = EvolutionNode(
        speciesId: 1,
        nationalDex: 1,
        nameZh: '甲',
        thumbAsset: null,
        children: [edge(1, 2)],
      );
      final cycleTree = EvolutionTree(
        root: nodeA,
        nodesBySpeciesId: {
          1: nodeA,
          2: EvolutionNode(
            speciesId: 2,
            nationalDex: 2,
            nameZh: '乙',
            thumbAsset: null,
            children: [edge(2, 1)],
          ),
        },
      );
      expect(isLinearEvolutionChain(cycleTree), isTrue);
    });

    test('linearChainRowWidth：3 节点 = 3×120 + 2×72 + 2×16', () {
      expect(linearChainRowWidth(3), 536.0);
    });

    test('linearChainRowWidth：少于 2 节点返回 0', () {
      expect(linearChainRowWidth(1), 0.0);
      expect(linearChainRowWidth(0), 0.0);
    });

    test('linearChainRowWidth：自定义布局常数', () {
      expect(
        linearChainRowWidth(
          2,
          nodeMinWidth: 100,
          arrowColumnWidth: 50,
          rowPadding: 10,
        ),
        270.0,
      );
    });

    test('flattenEvolutionTree：线性链 guides 按「祖先直系末子终点」判定', () {
      // 绿毛虫链 10→11→12，先序行号 0/1/2；各节点均只有一个直系孩子。
      // 行1（铁甲蛹）是绿毛虫唯一直系孩子（同时为末子），绿毛虫向直系子节点
      // 延伸的竖干在行1拐角处收束（guides=[false]，即 └ 端点）；行2（巴大蝶）
      // 列0保持空白、列1由 EdgeRow 接续铁甲蛹到巴大蝶并收束为 [false, false]。
      final rows = flattenEvolutionTree(repo.caterpieTree);
      expect(
        rows.map((r) => r.guides).toList(),
        [
          <bool>[],
          [false],
          [false, false],
        ],
      );
    });

    test('flattenEvolutionTree：末支含孙代时祖先竖干到末直系子节即止（魔墙人偶）', () {
      // 魔尼尼(行0) → 魔墙人偶(行1) & 魔墙人偶-伽勒尔(行2) → 踏冰人偶(行3)。
      // 行1 为首支，列0竖干延续 [true]；行2 为魔尼尼末个直系孩子，列0应于拐角处
      // 收束为 [false]（不拖至伽勒尔卡底边）；行3 踏冰人偶列0留白、列1收束 [false, false]。
      final rows = flattenEvolutionTree(repo.mrMimeTree);
      expect(
        rows.map((r) => r.guides).toList(),
        [
          <bool>[],
          [true],
          [false],
          [false, false],
        ],
      );
    });

    test('flattenEvolutionTree：伊布 8 分支根竖线穿过末分支之前的每一行', () {
      // 伊布树先序行号 0..8：根子树行数 9 → 末行 8；分支全为叶子。
      // 行1..7 分支行：伊布子树末行 8 > 当前行号 → guides=[true]；
      // 行8（仙子伊布）为末行：8 = 8 → guides=[false]。分支行 depth=1，
      // guides[0] 即拐角列（level = depth-1）的竖线延续判据——水伊布
      // 等叶分支之后还有后续分支行，主干竖线必须继续；行8 为 └ 端点。
      final rows = flattenEvolutionTree(repo.eeveeTree);
      expect(
        rows.map((r) => r.guides).toList(),
        [
          <bool>[],
          [true],
          [true],
          [true],
          [true],
          [true],
          [true],
          [true],
          [false],
        ],
      );
    });
  });

  group('进化分区 · 伊布', () {
    testWidgets('宽屏渲染根与 8 个子节点（分支链走纵向树 dense）', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(1000, 900),
      );

      expect(find.byType(InteractiveViewer), findsNothing);
      // 伊布 1 根 8 分支：分支链不走横排形态，宽屏（本地宽 ≥840）
      // 走 dense 纵向树，根与 8 个子节点全部渲染。
      expect(find.text('伊布'), findsOneWidget);
      for (final name in [
        '水伊布', '雷伊布', '火伊布', '太阳伊布',
        '月亮伊布', '叶伊布', '冰伊布', '仙子伊布',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('条件 chip 文案（道具 / 昵称条件 / 招式 / 地点诚实显示）', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(1000, 900),
      );

      expect(find.text('使用火之石'), findsOneWidget);
      expect(find.text('使用水之石'), findsOneWidget);
      expect(find.text('使用雷之石'), findsOneWidget);
      expect(find.text('白天'), findsOneWidget);
      expect(find.text('夜晚'), findsOneWidget);
      expect(find.text('亲密度 ≥220'), findsNWidgets(2));
      expect(find.text('友好度 ≥2'), findsOneWidget);
      expect(find.text('学会滚动'), findsOneWidget);
      expect(find.text('学会妖精属性招式'), findsOneWidget);
      // 未收录的 location 标识符原样英文美化，不编造中文。
      expect(find.text('地点 Ice Rock'), findsOneWidget);
    });

    testWidgets('当前 species 高亮（primaryContainer 底），根不高亮', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 135,
        size: const Size(1000, 900),
      );

      expect(
        cardColorOf(tester, '雷伊布'),
        AppColors.light.primaryContainer,
      );
      expect(cardColorOf(tester, '伊布'), AppColors.light.bg);
    });

    testWidgets('compact(400px) 纵向树可渲染（无 InteractiveViewer）', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(400, 900),
      );

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text('伊布'), findsOneWidget);
      expect(find.text('仙子伊布'), findsOneWidget);
      expect(find.text('使用火之石'), findsOneWidget);
    });

    testWidgets('纵向树导引线锚定卡身中心：双子行零断线衔接，拐角精确落在卡中心',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(400, 900),
      );

      final eeveeCard = cardRectOf(tester, '伊布');
      final vaporEdge = tester.getRect(
        find.byKey(const ValueKey('evo_tree_edge_134')),
      );
      final vaporRow = tester.getRect(
        find.byKey(const ValueKey('evo_tree_card_row_134')),
      );
      final vaporElbow = tester.getRect(
        find.byKey(const ValueKey('evo_tree_elbow_134')),
      );
      final vaporCard = cardRectOf(tester, '水伊布');
      final joltEdge = tester.getRect(
        find.byKey(const ValueKey('evo_tree_edge_135')),
      );
      final sylveonElbow = tester.getRect(
        find.byKey(const ValueKey('evo_tree_elbow_700')),
      );
      final sylveonCard = cardRectOf(tester, '仙子伊布');

      // 根卡底边 → 首条边行 → 首条卡行 → 下一兄弟边行：0px 断线无缝拼接。
      expect(vaporEdge.top, moreOrLessEquals(eeveeCard.bottom, epsilon: 0.5));
      expect(vaporRow.top, moreOrLessEquals(vaporEdge.bottom, epsilon: 0.5));
      expect(joltEdge.top, moreOrLessEquals(vaporRow.bottom, epsilon: 0.5));

      // 拐角列与卡行等高，横线中点（height/2）精确落在水伊布、仙子伊布卡身垂直中心。
      expect(
        vaporElbow.center.dy,
        moreOrLessEquals(vaporCard.center.dy, epsilon: 0.5),
      );
      expect(
        sylveonElbow.center.dy,
        moreOrLessEquals(sylveonCard.center.dy, epsilon: 0.5),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('进化分区 · 绿毛虫三段链', () {
    testWidgets('线性链宽屏走横排一行（三卡同排），窄面板回退垂直时间线且 0px 断线', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
        size: const Size(1000, 900),
      );

      double dyOf(String name) => tester.getCenter(find.text(name)).dy;
      expect((dyOf('绿毛虫') - dyOf('巴大蝶')).abs(), lessThan(4));
      expect(find.text('Lv.10'), findsOneWidget);
      expect(find.text('Lv.16'), findsOneWidget);

      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
        size: const Size(400, 900),
      );
      double dxOf(String name) => tester.getTopLeft(find.text(name)).dx;
      expect((dxOf('铁甲蛹') - dxOf('绿毛虫')).abs(), lessThan(2));
      expect((dxOf('巴大蝶') - dxOf('铁甲蛹')).abs(), lessThan(2));
      expect(dyOf('铁甲蛹') - dyOf('绿毛虫'), greaterThan(48));
      expect(dyOf('巴大蝶') - dyOf('铁甲蛹'), greaterThan(48));

      // 垂直时间线连接段紧贴上下两张卡片边框（0px 断口）。
      final conn11 = tester.getRect(
        find.byKey(const ValueKey('evo_timeline_conn_11')),
      );
      final conn12 = tester.getRect(
        find.byKey(const ValueKey('evo_timeline_conn_12')),
      );
      expect(
        conn11.top,
        moreOrLessEquals(cardRectOf(tester, '绿毛虫').bottom, epsilon: 0.5),
      );
      expect(
        conn11.bottom,
        moreOrLessEquals(cardRectOf(tester, '铁甲蛹').top, epsilon: 0.5),
      );
      expect(
        conn12.top,
        moreOrLessEquals(cardRectOf(tester, '铁甲蛹').bottom, epsilon: 0.5),
      );
      expect(
        conn12.bottom,
        moreOrLessEquals(cardRectOf(tester, '巴大蝶').top, epsilon: 0.5),
      );

      expect(find.text('Lv.10'), findsOneWidget);
      expect(find.text('Lv.16'), findsOneWidget);
      expect(find.text('等级提升'), findsNWidgets(2));
      expect(find.byType(ConditionChip), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('52poke 横排形态：三卡等宽 140、间距相等 120，条件位于卡间箭头线上方',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
        size: const Size(1000, 900),
      );

      final cardRects = [
        for (final name in ['绿毛虫', '铁甲蛹', '巴大蝶'])
          cardRectOf(tester, name),
      ];
      for (final rect in cardRects) {
        expect(rect.width, kHorizontalNodeWidthRoomy,
            reason: '横排宽屏卡宽应固定为 140');
      }

      // 两段连接区宽度严格相等（112）。
      final gap1 = cardRects[1].left - cardRects[0].right;
      final gap2 = cardRects[2].left - cardRects[1].right;
      expect(gap1, moreOrLessEquals(kHorizontalEdgeWidthRoomy, epsilon: 0.5));
      expect(gap2, moreOrLessEquals(gap1, epsilon: 0.5));

      // Lv.10 芯片落在卡 0 与卡 1 之间的连接段中，且位于卡片中线之上（箭头线上方）。
      final lv10Rect = tester.getRect(find.text('Lv.10'));
      expect(lv10Rect.left, greaterThanOrEqualTo(cardRects[0].right - 0.5));
      expect(lv10Rect.right, lessThanOrEqualTo(cardRects[1].left + 0.5));
      expect(lv10Rect.bottom, lessThan(cardRects[0].center.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('中间节点「铁甲蛹」出现，等级条件 chip 为 Lv.10 / Lv.16', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
      );

      expect(find.text('绿毛虫'), findsOneWidget);
      expect(find.text('铁甲蛹'), findsOneWidget);
      expect(find.text('巴大蝶'), findsOneWidget);
      expect(find.text('Lv.10'), findsOneWidget);
      expect(find.text('Lv.16'), findsOneWidget);
    });
  });

  group('进化分区 · 呆呆兽分支', () {
    testWidgets('携带道具交换分支显示「携带王者之证交换」', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 79,
      );

      expect(find.text('呆呆兽'), findsOneWidget);
      expect(find.text('呆壳兽'), findsOneWidget);
      expect(find.text('呆呆王'), findsOneWidget);
      expect(find.text('Lv.37'), findsOneWidget);
      expect(find.text('通信交换'), findsOneWidget);
      expect(find.text('携带王者之证交换'), findsOneWidget);
    });
  });

  group('进化分区 · 空态', () {
    testWidgets('root 无孩子（拉普拉斯）显示「该宝可梦没有进化关系」', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 131,
      );

      expect(find.text('该宝可梦没有进化关系'), findsOneWidget);
      // 空态不渲染任何节点卡：分区内无可点击的节点。
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('getEvolutionTree 返回 null（fixture 未收录的 species）同样显示空态',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 25,
      );

      expect(find.text('该宝可梦没有进化关系'), findsOneWidget);
    });
  });

  group('进化分区 · 节点点击导航', () {
    testWidgets('线性链横排形态：点「巴大蝶」push 到 /pokemon/12', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
        size: const Size(1000, 900),
      );
      expect(currentLocation(tester), '/pokemon/10');

      await tester.tap(find.text('巴大蝶'));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(currentLocation(tester), '/pokemon/12');
    });

    testWidgets('分支链纵向树形态：点「水伊布」push 到 /pokemon/134', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(1000, 900),
      );

      await tester.tap(find.text('水伊布'));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(currentLocation(tester), '/pokemon/134');
    });

    testWidgets('点击当前 species 自身不导航', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 10,
        size: const Size(1000, 900),
      );

      await tester.tap(find.text('绿毛虫'));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(currentLocation(tester), '/pokemon/10');
      // 当前节点 onTap 为 null，不 push 新页面：分区实例仍只有一个。
      expect(find.byType(EvolutionSectionPlaceholder), findsOneWidget);
    });
  });

  group('进化分区 · 形态分支 / 多根并行 / 响应式零溢出', () {
    Color formCardColor(WidgetTester tester, int formId) {
      final containerFinder = find.descendant(
        of: find.byKey(ValueKey('evo_card_$formId')),
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is ShapeDecoration,
        ),
      );
      final deco = tester.widget<Container>(containerFinder.first).decoration!
          as ShapeDecoration;
      return deco.color!;
    }

    testWidgets('魔墙人偶：52poke 横向阶梯树展示其他地区与伽勒尔地区分支，页内点击切形态',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 122,
        size: const Size(800, 900),
      );

      // 魔尼尼(1) → [魔墙人偶(122) | 魔墙人偶-伽勒尔(10168) → 踏冰人偶(866)]。
      expect(find.text('其他地区'), findsOneWidget);
      expect(find.text('伽勒尔地区'), findsOneWidget);
      expect(find.text('Lv.42'), findsOneWidget);
      expect(find.text('伽勒尔的样子'), findsOneWidget);
      expect(find.byType(TypeBadge), findsAtLeastNWidgets(6));

      // 默认选中 122：122 高亮、10168 不高亮。
      expect(formCardColor(tester, 122), AppColors.light.primaryContainer);
      expect(formCardColor(tester, 10168), AppColors.light.bg);

      // 横向阶梯树：魔墙人偶(122) 与 伽勒尔魔墙人偶(10168) 同列对齐，踏冰人偶位于第 3 阶更右。
      final defaultRect =
          tester.getRect(find.byKey(const ValueKey('evo_card_122')));
      final galarRect =
          tester.getRect(find.byKey(const ValueKey('evo_card_10168')));
      final rimeRect =
          tester.getRect(find.byKey(const ValueKey('evo_card_866')));
      expect(defaultRect.left, moreOrLessEquals(galarRect.left, epsilon: 0.5));
      expect(rimeRect.left, greaterThan(galarRect.right));
      expect(galarRect.center.dy, moreOrLessEquals(rimeRect.center.dy, epsilon: 0.5));

      // 同物种不同形态（10168）：点击原地切换 selectedFormIdProvider(122)，不 push 路由。
      await tester.tap(find.byKey(const ValueKey('evo_card_10168')));
      await tester.pump();
      expect(currentLocation(tester), '/pokemon/122');
      expect(find.byType(EvolutionSectionPlaceholder), findsOneWidget);
      expect(formCardColor(tester, 10168), AppColors.light.primaryContainer);
      expect(formCardColor(tester, 122), AppColors.light.bg);
      expect(tester.takeException(), isNull);
    });

    testWidgets('从魔尼尼点击伽勒尔魔墙人偶携带 ?formId=10168 导航', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 439,
        size: const Size(800, 900),
      );

      await tester.tap(find.byKey(const ValueKey('evo_card_10168')));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(currentUri(tester), '/pokemon/122?formId=10168');
    });

    testWidgets('窄屏纵向卡片属性徽章保持紧凑同行排布，不横向拉满卡片', (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 122,
        size: const Size(360, 800),
      );

      final rootCard = find.byKey(const ValueKey('evo_card_439'));
      final badges = find.descendant(
        of: rootCard,
        matching: find.byType(TypeBadge),
      );
      expect(badges, findsNWidgets(2));
      final rootRect = tester.getRect(rootCard);
      final psychicRect = tester.getRect(badges.at(0));
      final fairyRect = tester.getRect(badges.at(1));
      expect(psychicRect.top, moreOrLessEquals(fairyRect.top, epsilon: 0.5),
          reason: '双属性徽章应同行并排');
      expect(fairyRect.left, greaterThan(psychicRect.right));
      expect(fairyRect.right, lessThanOrEqualTo(rootRect.right));
      expect(tester.takeException(), isNull);
    });

    testWidgets('仅特定形态可进化（大葱鸭）：默认形态显示不可进化提示，切伽勒尔后消除',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => EvolutionSectionPlaceholder(speciesId: id),
        speciesId: 83,
        size: const Size(360, 800),
      );

      expect(find.textContaining('当前形态无法进化'), findsOneWidget);
      expect(find.textContaining('伽勒尔的样子'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('evo_card_10166')));
      await tester.pump();
      expect(find.textContaining('当前形态无法进化'), findsNothing);
      expect(formCardColor(tester, 10166), AppColors.light.primaryContainer);
      expect(tester.takeException(), isNull);
    });

    testWidgets('多根并行链（喵喵三形态）：渲染 3 条完整演化线及分隔线', (tester) async {
      for (final width in [360.0, 720.0]) {
        await pumpSection(
          tester,
          section: (id) => EvolutionSectionPlaceholder(speciesId: id),
          speciesId: 52,
          size: Size(width, 900),
        );

        expect(find.text('喵喵'), findsNWidgets(3));
        expect(find.text('猫老大'), findsNWidgets(2));
        expect(find.text('喵头目'), findsOneWidget);
        expect(find.byType(Divider), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('全断点 + 1.25x 字号压力测试：魔墙人偶 / 伊布 / 绿毛虫 / 喵喵零溢出且不断线',
        (tester) async {
      const widths = [320.0, 360.0, 412.0, 480.0, 600.0, 720.0, 1000.0, 1280.0];
      for (final width in widths) {
        for (final speciesId in [122, 133, 10, 52]) {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1.0;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [pokedexRepositoryProvider.overrideWithValue(repo)],
              child: MaterialApp(
                theme: buildLightTheme(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.25)),
                  child: Scaffold(
                    body: SingleChildScrollView(child: child),
                  ),
                ),
                home: EvolutionSectionPlaceholder(speciesId: speciesId),
              ),
            ),
          );
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(
            tester.takeException(),
            isNull,
            reason: 'species=$speciesId width=$width 1.25x 字号下出现异常',
          );

          // 所有节点卡不得超过视口右缘。
          for (final element
              in find.byType(InkWell).evaluate()) {
            final box = element.renderObject as RenderBox?;
            if (box == null || !box.hasSize) continue;
            final topLeft = box.localToGlobal(Offset.zero);
            expect(
              topLeft.dx + box.size.width,
              lessThanOrEqualTo(width + 0.5),
              reason: 'species=$speciesId width=$width 存在横向越界',
            );
          }

          // 若当前为纵向树，验证首条分支与根卡之间 0px 断线且拐角对齐卡中心。
          if (speciesId == 122 &&
              find.byKey(const ValueKey('evo_tree_elbow_10168')).evaluate().isNotEmpty) {
            final edgeRect = tester.getRect(
              find.byKey(const ValueKey('evo_tree_edge_122')),
            );
            final rootRect = tester.getRect(
              find.byKey(const ValueKey('evo_card_439')),
            );
            expect(
              edgeRect.top,
              moreOrLessEquals(rootRect.bottom, epsilon: 0.5),
            );
            final galarElbow = tester.getRect(
              find.byKey(const ValueKey('evo_tree_elbow_10168')),
            );
            final galarCard = tester.getRect(
              find.byKey(const ValueKey('evo_card_10168')),
            );
            expect(
              galarElbow.center.dy,
              moreOrLessEquals(galarCard.center.dy, epsilon: 0.5),
            );
          }
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  group('进化分区 · 真实离线库全形态链路', () {
    loadSqliteForHostTests();

    testWidgets('魔墙人偶 / 呆呆兽 / 喵喵 / 大葱鸭 / 伊布 / 蛇纹熊 / 黏黏宝 / 野蛮鲈鱼 / 熊徒弟窄屏与宽屏零异常',
        (tester) async {
      final db = PokedexDatabase(
        PokedexDatabase.readOnlyExecutor(File('assets/database/pokedex.db')),
      );
      addTearDown(db.close);
      final realRepo = PokedexRepositoryImpl(
        db,
        loadManifestJson: () async => const <String, dynamic>{},
      );

      for (final size in const [Size(360, 800), Size(800, 900)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        for (final speciesId in [122, 79, 52, 83, 133, 263, 704, 550, 891]) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [pokedexRepositoryProvider.overrideWithValue(realRepo)],
              child: MaterialApp(
                theme: buildLightTheme(),
                home: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: EvolutionSectionPlaceholder(speciesId: speciesId),
                  ),
                ),
              ),
            ),
          );
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '真实库 species=$speciesId size=$size 渲染产生异常',
          );
          expect(find.text('该宝可梦没有进化关系'), findsNothing);
        }
      }
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('PokemonDetailPage 支持 initialFormId 预选特定形态并高亮进化树',
        (tester) async {
      final db = PokedexDatabase(
        PokedexDatabase.readOnlyExecutor(File('assets/database/pokedex.db')),
      );
      addTearDown(db.close);
      final realRepo = PokedexRepositoryImpl(
        db,
        loadManifestJson: () async => const <String, dynamic>{},
      );
      final favorites = FakeFavoritesRepository();
      addTearDown(favorites.dispose);
      tester.view.physicalSize = const Size(412, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pokedexRepositoryProvider.overrideWithValue(realRepo),
            favoritesRepositoryProvider.overrideWithValue(favorites),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            home: const Scaffold(
              body: PokemonDetailPage(speciesId: 122, initialFormId: 10168),
            ),
          ),
        ),
      );
      final iceBadgeFinder = find.byKey(const ValueKey('detail_header_type_ice'));
      for (var waited = 0;
          iceBadgeFinder.evaluate().isEmpty && waited < 3000;
          waited += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      // 头部选中形态为伽勒尔的样子（冰/超能力属性）。
      expect(iceBadgeFinder, findsOneWidget);

      await tester.tap(find.text('进化'));
      final galarEvoFinder = find.byKey(const ValueKey('evo_card_10168'));
      for (var waited = 0;
          galarEvoFinder.evaluate().isEmpty && waited < 3000;
          waited += 50) {
        await tester.pump(const Duration(milliseconds: 50));
      }

      final galarCardFinder = find.descendant(
        of: galarEvoFinder,
        matching: find.byWidgetPredicate(
          (w) => w is Container && w.decoration is ShapeDecoration,
        ),
      );
      final deco = tester.widget<Container>(galarCardFinder.first).decoration!
          as ShapeDecoration;
      expect(deco.color, AppColors.light.primaryContainer);
      expect(tester.takeException(), isNull);
    });
  });

  group('招式分区', () {
    testWidgets('默认按等级排序渲染列表与计数', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      expect(find.text('共 6 个招式'), findsOneWidget);
      // 默认只展开首个分组（升级）；跨来源的 dy 断言需先展开学习器 / 导师组。
      await expandGroup(tester, 'machine');
      await expandGroup(tester, 'tutor');
      double dyOf(String name) => tester.getCenter(find.text(name)).dy;
      // level 排序：level_up(1,1,5) → machine → tutor；同组同级按编号。
      expect(dyOf('撞击'), lessThan(dyOf('变硬')));
      expect(dyOf('变硬'), lessThan(dyOf('电击')));
      expect(dyOf('电击'), lessThan(dyOf('十万伏特')));
      expect(dyOf('十万伏特'), lessThan(dyOf('剑舞')));
      expect(dyOf('剑舞'), lessThan(dyOf('撒娇')));
    });

    testWidgets('切换版本组触发新查询并渲染对应内容', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );
      expect(repo.learnsetQueryLog.single.$1, 'scarlet-violet');

      await tester.tap(find.text('剑/盾'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(repo.learnsetQueryLog.last.$1, 'sword-shield');
      // 剑/盾组 2 条分属升级 / 学习器：挖洞（学习器）先展开其分组。
      await expandGroup(tester, 'machine');
      expect(find.text('挖洞'), findsOneWidget);
      expect(find.text('十万伏特'), findsNothing);
    });

    testWidgets('窄面板版本组 chips 自动换行：全部常驻可见且行距 = AppSpacing.s', (tester) async {
      // 多组长标签版本组：窄窗口（480）下若仍是横滚，行尾 chip 会被右缘
      // 裁掉一半甚至完全不可见（1600×900 双栏用户实测「黑2/白2 只露出
      // 黑2/」的等价场景）；改 Wrap 折行后全部 chip 必须完整落在可用宽内。
      repo = FakeEvolutionMovesRepository(
        versionGroups: const [
          VersionGroupRef(id: 'gen9', labelZh: '朱/紫', generationId: 9),
          VersionGroupRef(id: 'gen8', labelZh: '剑/盾', generationId: 8),
          VersionGroupRef(id: 'gen4', labelZh: '晶灿钻石/明亮珍珠', generationId: 4),
          VersionGroupRef(id: 'pla', labelZh: 'LEGENDS 阿尔宙斯', generationId: 8),
        ],
      );
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(480, 900),
      );

      final chipIds = ['gen9', 'gen8', 'gen4', 'pla'];
      final rects = <Rect>[
        for (final id in chipIds)
          tester.getRect(find.byKey(ValueKey('moves_vg_chip_$id'))),
      ];

      // 版本组行的可用宽 = chips 的 Wrap 祖先（Expanded 收紧约束）：
      // 全部 chip 的横向 rect 必须落在其内——不溢出、不被「排序」菜单
      // 或视口右缘裁切。
      final wrapRect = tester.getRect(
        find.ancestor(
          of: find.byKey(const ValueKey('moves_vg_chip_gen9')),
          matching: find.byType(Wrap),
        ),
      );
      for (final (index, rect) in rects.indexed) {
        expect(rect.left, greaterThanOrEqualTo(wrapRect.left - 0.5),
            reason: 'chip ${chipIds[index]} 左缘越界');
        expect(rect.right, lessThanOrEqualTo(wrapRect.right + 0.5),
            reason: 'chip ${chipIds[index]} 右缘被裁切');
      }

      // 横滚已移除：分区内不再有任何横向 SingleChildScrollView
      //（harness 外层的纵向页面滚动是合法祖先，不算在内）。
      final horizontalScrolls =
          tester.widgetList<SingleChildScrollView>(
        find.descendant(
          of: find.byType(MovesSectionPlaceholder),
          matching: find.byType(SingleChildScrollView),
        ),
      ).where((w) => w.scrollDirection == Axis.horizontal);
      expect(horizontalScrolls, isEmpty, reason: 'chips 行不应再有横向滚动');

      // 长标签在 480 宽下必然折行：按 chip top 聚类成行（0.5px 容差），
      // 行数 ≥2，且相邻两行的行距（上一行最底 → 下一行最顶）为
      // runSpacing = AppSpacing.s。
      final tops = rects.map((r) => r.top).toList()..sort();
      final runTops = <double>[];
      for (final top in tops) {
        if (runTops.isEmpty || top - runTops.last > 0.5) runTops.add(top);
      }
      expect(runTops.length, greaterThanOrEqualTo(2),
          reason: '480 宽 + 长标签下版本组 chips 应折成 ≥2 行');

      double runBottom(int runIndex) {
        var bottom = double.negativeInfinity;
        for (final rect in rects) {
          if ((rect.top - runTops[runIndex]).abs() <= 0.5 &&
              rect.bottom > bottom) {
            bottom = rect.bottom;
          }
        }
        return bottom;
      }

      for (var i = 0; i < runTops.length - 1; i++) {
        expect(runTops[i + 1] - runBottom(i), AppSpacing.s,
            reason: '折行行距应为 runSpacing = AppSpacing.s');
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact tile 定宽右簇：所有行的属性徽章左缘成一条直线', (tester) async {
      // compact（<840）下展开全部分组：6 行徽章齐备，其中「十万伏特」
      // 名称 4 字、其余 2 字，名称宽度不同 —— 修复前簇宽随徽章/名称
      // 变化，各行徽章左缘必然参差。
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(480, 900),
      );

      await expandGroup(tester, 'machine');
      await expandGroup(tester, 'tutor');

      // 撞击 / 变硬 / 电击 / 剑舞 / 十万伏特 / 撒娇 每行一枚徽章；
      // 每枚徽章按 widget 实例定位（电属性有两行，不能按 type 找）。
      final badges = tester.widgetList<TypeBadge>(find.byType(TypeBadge));
      final badgeLefts = <double>[
        for (final badge in badges)
          tester
              .getRect(
                find.byWidgetPredicate((w) => identical(w, badge)),
              )
              .left,
      ];
      expect(badgeLefts, hasLength(6));
      expect(badgeLefts, everyElement(badgeLefts.first));
    });

    testWidgets('来源筛选（学习器）按 OR 过滤', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      // .first：来源 chip 在列表之前（列表行尾也有「学习器」标签）。
      await tester.tap(find.text('学习器').first);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(repo.learnsetQueryLog.last.$2, <String>{'machine'});
      expect(find.text('共 2 个招式'), findsOneWidget);
      expect(find.text('剑舞'), findsOneWidget);
      expect(find.text('十万伏特'), findsOneWidget);
      expect(find.text('撞击'), findsNothing);
    });

    testWidgets('power 排序：威力降序，缺失排尾', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      // 点按钮本体（内部文字的命中测试在 harness 下不稳定）。
      await tester.tap(find.byType(PopupMenuButton<MoveSort>));
      // 菜单开启动画完全结束后 IgnorePointer 才放行（360ms 不够）。
      await tester.pumpAndSettle();
      await tester.tap(find.text('威力'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      double dyOf(String name) => tester.getCenter(find.text(name)).dy;
      expect(dyOf('十万伏特'), lessThan(dyOf('撞击')));
      expect(dyOf('撞击'), lessThan(dyOf('电击')));
      // 威力缺失（变硬/剑舞/撒娇）排尾，按编号稳定。
      expect(dyOf('电击'), lessThan(dyOf('变硬')));
      expect(dyOf('变硬'), lessThan(dyOf('撒娇')));
    });

    testWidgets('点击招式行导航到招式详情', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      await tester.tap(find.text('撞击'));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(find.text('用整个身体撞上去，简单可靠。'), findsOneWidget);
      expect(find.byKey(MoveDetailPage.flavorQuoteKey), findsOneWidget);
    });
  });

  group('招式分区 · 按来源分组折叠', () {
    testWidgets('≥2 来源时渲染分组表头与每组计数，组序沿用 methodGroupOrder',
        (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      // fixture 三个来源：升级 3 / 学习器 2 / 导师 1。
      for (final method in ['level_up', 'machine', 'tutor']) {
        expect(
          find.byKey(ValueKey('move_group_header_$method')),
          findsOneWidget,
          reason: '来源 $method 应有一个分组表头',
        );
      }
      // 结果里没有的来源不出现分组表头。
      expect(find.byKey(const ValueKey('move_group_header_egg')), findsNothing);
      expect(
        find.byKey(const ValueKey('move_group_header_other')),
        findsNothing,
      );
      expect(find.text('升级招式'), findsOneWidget);
      expect(find.text('· 3 个'), findsOneWidget);
      expect(find.text('学习器招式'), findsOneWidget);
      expect(find.text('· 2 个'), findsOneWidget);
      expect(find.text('导师招式'), findsOneWidget);
      expect(find.text('· 1 个'), findsOneWidget);

      // 组序：升级 → 学习器 → 导师（methodGroupOrder，与 level 排序一致）。
      double dyOfKey(String method) => tester
          .getCenter(find.byKey(ValueKey('move_group_header_$method')))
          .dy;
      expect(dyOfKey('level_up'), lessThan(dyOfKey('machine')));
      expect(dyOfKey('machine'), lessThan(dyOfKey('tutor')));
    });

    testWidgets('默认只展开首组：升级行可见，学习器 / 导师行不构建', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      expect(find.text('撞击'), findsOneWidget);
      expect(find.text('变硬'), findsOneWidget);
      expect(find.text('电击'), findsOneWidget);
      // 折叠组不构建行：既不可见，也不在 widget 树里。
      expect(find.text('剑舞'), findsNothing);
      expect(find.text('十万伏特'), findsNothing);
      expect(find.text('撒娇'), findsNothing);
    });

    testWidgets('点击表头展开 / 收起学习器组', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      final machine = find.byKey(const ValueKey('move_group_header_machine'));
      await tester.tap(machine);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('剑舞'), findsOneWidget);
      expect(find.text('十万伏特'), findsOneWidget);
      // 同组的升级行不受影响，表头自身仍在（可再次点击收起）。
      expect(find.text('撞击'), findsOneWidget);
      expect(machine, findsOneWidget);

      await tester.tap(machine);
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('剑舞'), findsNothing);
      expect(find.text('十万伏特'), findsNothing);
      expect(find.text('撞击'), findsOneWidget);
    });

    testWidgets('有来源筛选时全部分组展开（跨来源行直接可见）', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      // 多选两个来源：学习器 + 导师（.first：来源 chip 在列表之前）。
      await tester.tap(find.text('学习器').first);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await tester.tap(find.text('导师').first);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(find.text('共 3 个招式'), findsOneWidget);
      // 两个分组都无需手动展开。
      expect(find.text('剑舞'), findsOneWidget);
      expect(find.text('十万伏特'), findsOneWidget);
      expect(find.text('撒娇'), findsOneWidget);
      expect(find.text('撞击'), findsNothing);
    });

    testWidgets('排序切到威力后分组表头消失，所有行平铺可见', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      await tester.tap(find.byType(PopupMenuButton<MoveSort>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('威力'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // 跨来源排序下分组语义不成立：全部表头消失。
      for (final method in ['level_up', 'machine', 'tutor']) {
        expect(
          find.byKey(ValueKey('move_group_header_$method')),
          findsNothing,
          reason: '威力排序下不应有 $method 分组表头',
        );
      }
      // 6 条全部渲染（不必展开）。
      for (final name in ['撞击', '变硬', '电击', '十万伏特', '剑舞', '撒娇']) {
        expect(find.text(name), findsOneWidget, reason: '威力排序下 $name 应平铺可见');
      }
    });

    testWidgets('≥840 宽表格模式：列头 + 分组折叠共用同一套表格行', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
        size: const Size(1000, 900),
      );

      // 表格列头仍渲染（列头只在表格模式出现一次，位于分组之上）。
      expect(find.text('属性'), findsOneWidget);
      expect(find.text('分类'), findsOneWidget);
      expect(find.text('威力'), findsOneWidget);
      expect(find.text('命中'), findsOneWidget);
      expect(find.text('等级'), findsOneWidget);

      expect(find.byKey(const ValueKey('move_group_header_machine')), findsOneWidget);
      expect(find.text('撞击'), findsOneWidget);
      expect(find.text('十万伏特'), findsNothing);
      // 「学习器」只出现在来源 chip 上（折叠组不构建行）。
      expect(find.text('学习器'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('move_group_header_machine')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('十万伏特'), findsOneWidget);
      // chip + 2 条学习器行的行尾标签（无等级 → 显示来源短词）。
      expect(find.text('学习器'), findsNWidgets(3));

      // 表格行仍可点进招式详情。
      await tester.tap(find.text('撞击'));
      await tester.pump(const Duration(milliseconds: 300));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      expect(find.text('用整个身体撞上去，简单可靠。'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('切换版本组后回到默认折叠（只展开首组）', (tester) async {
      await pumpSection(
        tester,
        section: (id) => MovesSectionPlaceholder(speciesId: id),
        speciesId: 133,
      );

      // 先显式展开学习器组。
      await expandGroup(tester, 'machine');
      expect(find.text('剑舞'), findsOneWidget);

      await tester.tap(find.text('剑/盾'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      // 新版本组（升级 1 + 学习器 1）按默认规则折叠：显式展开不残留。
      expect(find.byKey(const ValueKey('move_group_header_machine')), findsOneWidget);
      expect(find.text('共 2 个招式'), findsOneWidget);
      expect(find.text('撞击'), findsOneWidget);
      expect(find.text('挖洞'), findsNothing);

      await expandGroup(tester, 'machine');
      expect(find.text('挖洞'), findsOneWidget);
    });
  });
}
