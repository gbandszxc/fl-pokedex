import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
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
import 'package:fl_pokedex/domain/repositories/pokedex_repository.dart';
import 'package:fl_pokedex/features/moves/move_detail_page.dart';
import 'package:fl_pokedex/features/pokemon_detail/evolution_section_placeholder.dart';
import 'package:fl_pokedex/features/pokemon_detail/learnset_filter.dart'
    show MoveSort;
import 'package:fl_pokedex/features/pokemon_detail/moves_section_placeholder.dart';

/// 进化 / 招式 fixtures（伊布 8 分支 + 绿毛虫三段链 + 呆呆兽分支）。
class FakeEvolutionMovesRepository implements PokedexRepository {
  /// getLearnset 收到的 (versionGroup, methods) 调用记录。
  final learnsetQueryLog = <(String, Set<String>?)>[];

  EvolutionEdge _edge(
    int from,
    int to, {
    String trigger = 'level-up',
    int? minLevel,
    String? item,
    String? heldItem,
    String? knownMove,
    String? knownMoveType,
    String? location,
    String? timeOfDay,
    int? minHappiness,
    int? minAffection,
  }) {
    return EvolutionEdge(
      chainId: 1,
      fromSpeciesId: from,
      toSpeciesId: to,
      trigger: trigger,
      minLevel: minLevel,
      item: item,
      heldItem: heldItem,
      knownMove: knownMove,
      knownMoveType: knownMoveType,
      location: location,
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

  EvolutionTree? _treeFor(int speciesId) {
    for (final tree in [eeveeTree, caterpieTree, slowpokeTree]) {
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
      _versionGroups[formId] ?? const <VersionGroupRef>[];

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
  Future<DataManifest> getManifest() => throw UnimplementedError();
}

void main() {
  late FakeEvolutionMovesRepository repo;

  setUp(() {
    repo = FakeEvolutionMovesRepository();
  });

  /// 挂载一个分区到 /pokemon/:speciesId 路由下（分区自身从路由读 speciesId）。
  Future<void> pumpSection(
    WidgetTester tester, {
    required WidgetBuilder section,
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
              child: Builder(builder: section),
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

  group('进化分区 · 伊布', () {
    testWidgets('expanded 横向树渲染根与 8 个子节点', (tester) async {
      await pumpSection(
        tester,
        section: (_) => const EvolutionSectionPlaceholder(),
        speciesId: 133,
        size: const Size(1000, 900),
      );

      expect(find.byType(InteractiveViewer), findsOneWidget);
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
        section: (_) => const EvolutionSectionPlaceholder(),
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
        section: (_) => const EvolutionSectionPlaceholder(),
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
        section: (_) => const EvolutionSectionPlaceholder(),
        speciesId: 133,
        size: const Size(400, 900),
      );

      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.text('伊布'), findsOneWidget);
      expect(find.text('仙子伊布'), findsOneWidget);
      expect(find.text('使用火之石'), findsOneWidget);
    });
  });

  group('进化分区 · 绿毛虫三段链', () {
    testWidgets('中间节点「铁甲蛹」出现，等级条件 chip 为 Lv.10 / Lv.16', (tester) async {
      await pumpSection(
        tester,
        section: (_) => const EvolutionSectionPlaceholder(),
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
        section: (_) => const EvolutionSectionPlaceholder(),
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

  group('招式分区', () {
    testWidgets('默认按等级排序渲染列表与计数', (tester) async {
      await pumpSection(
        tester,
        section: (_) => const MovesSectionPlaceholder(),
        speciesId: 133,
      );

      expect(find.text('共 6 个招式'), findsOneWidget);
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
        section: (_) => const MovesSectionPlaceholder(),
        speciesId: 133,
      );
      expect(repo.learnsetQueryLog.single.$1, 'scarlet-violet');

      await tester.tap(find.text('剑/盾'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }

      expect(repo.learnsetQueryLog.last.$1, 'sword-shield');
      expect(find.text('挖洞'), findsOneWidget);
      expect(find.text('十万伏特'), findsNothing);
    });

    testWidgets('来源筛选（学习器）按 OR 过滤', (tester) async {
      await pumpSection(
        tester,
        section: (_) => const MovesSectionPlaceholder(),
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
        section: (_) => const MovesSectionPlaceholder(),
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
        section: (_) => const MovesSectionPlaceholder(),
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
}
