import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import '../features/favorites/fakes.dart';

/// 版本组学习集差异 · UI 层（任务 F2 已覆盖 provider 层与分区直挂路径，
/// 本文件补「详情页招式 tab」的完整用户路径）：
///
/// 走真实 [PokemonDetailPage] 的 TabBarView 切到「招式」，验证——
/// 1. 默认选中最新版本组并渲染其列表；
/// 2. 切版本组 chips → 列表内容随组变化（两个 fixture 组数据不同）；
/// 3. 来源（method）筛选 chips 生效，「全部」可恢复。

/// 伊布 fixture：两个版本组的学习集刻意不同。
class _VersionGroupFake implements PokedexRepository {
  final versionGroups = const [
    VersionGroupRef(id: 'scarlet-violet', labelZh: '朱/紫', generationId: 9),
    VersionGroupRef(id: 'sword-shield', labelZh: '剑/盾', generationId: 8),
  ];

    /// 朱/紫 4 条：升级 2 + 学习器 1 + 导师 1。
    final learnsets = <String, List<MoveEntry>>{
      'scarlet-violet': [
        const MoveEntry(
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
        const MoveEntry(
          moveId: 2,
          nameZh: '电光一闪',
          nameEn: 'Quick Attack',
          typeId: 'normal',
          damageClass: 'physical',
          power: 40,
          pp: 30,
          accuracy: 100,
          level: 8,
          method: 'level_up',
          versionGroup: 'scarlet-violet',
        ),
        const MoveEntry(
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
        const MoveEntry(
          moveId: 4,
          nameZh: '撒娇',
          nameEn: 'Charm',
          typeId: 'fairy',
          damageClass: 'status',
          pp: 28,
          accuracy: 100,
          method: 'tutor',
          versionGroup: 'scarlet-violet',
        ),
      ],
      // 剑/盾 2 条：升级 1 + 学习器 1（十万伏特为朱紫独占，挖洞为剑盾独占）。
      'sword-shield': [
        const MoveEntry(
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
        const MoveEntry(
          moveId: 5,
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

    List<MoveEntry> learnsetFor(String group, Set<String>? methods) {
      final moves = learnsets[group] ?? const <MoveEntry>[];
      if (methods == null || methods.isEmpty) return moves;
      return moves.where((m) => methods.contains(m.method)).toList();
    }

    @override
    Future<List<MoveEntry>> getLearnset(
      int formId,
      String versionGroup, {
      Set<String>? methods,
    }) async =>
        learnsetFor(versionGroup, methods);

    @override
    Future<List<VersionGroupRef>> getFormVersionGroups(int formId) async =>
        versionGroups;

    @override
    Future<List<PokemonSummary>> queryPokemon(
      FilterState f, {
      required int limit,
      required int offset,
    }) async =>
        const [];

    @override
    Future<int> countPokemon(FilterState f) async => 0;

    @override
    Future<List<PokemonSummary>> getPokemonSummaries(
      List<int> speciesIds,
    ) async => [
          for (final id in speciesIds)
            if (id == 133)
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

    @override
    Future<SpeciesInfo> getSpeciesInfo(int speciesId) async => SpeciesInfo(
          speciesId: speciesId,
          nationalDex: speciesId,
          generationId: 1,
          genusZh: '进化宝可梦',
        );

    @override
    Future<List<FormSummary>> getForms(int speciesId) async => [
          const FormSummary(
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
            typeIds: ['normal'],
          ),
        ];

    @override
    Future<StatBlock> getFormStats(int formId) async =>
        const StatBlock(
          hp: 55,
          attack: 55,
          defense: 50,
          specialAttack: 45,
          specialDefense: 65,
          speed: 55,
        );

    @override
    Future<List<AbilityRef>> getFormAbilities(int formId) async => const [
          AbilityRef(
            id: 93,
            nameZh: '适应力',
            nameEn: 'Adaptability',
            isHidden: false,
          ),
        ];

    @override
    Future<List<FlavorEntry>> getFlavorTexts(int speciesId) async => const [];

    @override
    Future<List<FlavorEntry>> getFormFlavorTexts(int formId) async => const [];

    @override
    Future<EvolutionTree?> getEvolutionTree(int speciesId) async => null;

    @override
    Future<MoveDetail?> getMoveDetail(int moveId) async => null;

    @override
    Future<List<TypeRef>> getTypes() async => const [];

    @override
    Future<List<GenerationRef>> getGenerations() async => const [];

    @override
    Future<List<PokedexRef>> getPokedexes() async => const [];

    @override
    Future<DataManifest> getManifest() async => DataManifest(
          schemaVersion: 1,
          dataVersion: 'test',
          pokemonCount: 1,
          formCount: 1,
          moveCount: 5,
          abilityCount: 1,
          versionCount: 2,
          buildDate: '2026-01-01',
          upstreamRevision: const {},
          learnsetVersionGroups: const ['scarlet-violet', 'sword-shield'],
          missingArtwork: const [],
        );
}

void main() {
  /// 泵入 /pokemon/133 详情页（800×600，compact/medium Tab 布局）。
  Future<void> pumpDetail(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final favorites = FakeFavoritesRepository();
    final repo = _VersionGroupFake();
    final container = ProviderContainer(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(repo),
        favoritesRepositoryProvider.overrideWithValue(favorites),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(favorites.dispose);

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/pokemon/133',
      routes: [
        GoRoute(
          path: '/pokemon/:speciesId',
          builder: (_, state) => PokemonDetailPage(
            speciesId: int.parse(state.pathParameters['speciesId']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildLightTheme(),
          routerConfig: router,
        ),
      ),
    );
    // 详情头部就绪（英日文行为头部特有文本）。
    for (var i = 0;
        i < 100 && find.textContaining('Eevee · ').evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// 切到详情页第 [label] 个 tab：tap 后分多帧泵足切换动画
  /// （TabController 动画约 300ms，单帧 pump 会遗留挂起）。
  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).first);
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// 收起折叠式 SliverAppBar：按「当前 pinned TabBar 位置 → 就位」的
  /// 实测距离上拖，不硬编码头高（F1c 后 = 视口高×0.5 clamp 300–440）。
  ///
  /// 距离留 16px 余量：拖过头会让内层滚动把 tab 顶部内容推进 pinned
  /// TabBar 覆盖区导致 tap miss。拖后断言 TabBar 已接近就位再继续交互。
  Future<void> collapseHeader(WidgetTester tester) async {
    const pinnedTabTop = 56.0; // kToolbarHeight
    const tabAnchor = '图鉴说明';
    final top = tester.getTopLeft(find.text(tabAnchor).first).dy;
    final distance = top - pinnedTabTop - 16;
    if (distance > 20) {
      // 起点取 TabBar 上方 50px，保证落在头部区域内（外层滚动收 header）。
      await tester.dragFrom(
        Offset(400, top - 50),
        Offset(0, -distance),
      );
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    expect(
      tester.getTopLeft(find.text(tabAnchor).first).dy,
      lessThan(pinnedTabTop + 64),
      reason: '折叠头部未收起，tab 内容区仍被压缩',
    );
  }

  testWidgets('招式 tab：默认最新版本组（朱/紫）渲染列表', (tester) async {
    await pumpDetail(tester);
    await openTab(tester, '招式');
    await collapseHeader(tester);

    expect(find.text('共 4 个招式'), findsOneWidget);
    // 头部收起后版本组 chips 不被 pinned TabBar 覆盖（可被 tap 命中）。
    final tabBarBottom =
        tester.getBottomLeft(find.text('图鉴说明').first).dy;
    expect(
      tester.getCenter(find.widgetWithText(VersionChip, '朱/紫')).dy,
      greaterThan(tabBarBottom),
      reason: '版本组 chips 位于 pinned TabBar 覆盖区内，无法交互',
    );
    // 默认选中最新组。
    expect(
      tester.widget<VersionChip>(
        find.widgetWithText(VersionChip, '朱/紫'),
      ).selected,
      isTrue,
    );
    expect(
      tester.widget<VersionChip>(
        find.widgetWithText(VersionChip, '剑/盾'),
      ).selected,
      isFalse,
    );
    // 朱/紫独占招式渲染，等级序（Lv.1 撞击在前）。
    expect(find.text('十万伏特'), findsOneWidget);
    expect(find.text('撒娇'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切版本组 chips → 列表内容随组变化', (tester) async {
    await pumpDetail(tester);
    await openTab(tester, '招式');
    await collapseHeader(tester);
    expect(find.text('共 4 个招式'), findsOneWidget);

    await tester.tap(find.widgetWithText(VersionChip, '剑/盾'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // 剑/盾组：2 条，朱紫独占的十万伏特消失、剑盾独占的挖洞出现。
    expect(find.text('共 2 个招式'), findsOneWidget);
    expect(find.text('挖洞'), findsOneWidget);
    expect(find.text('十万伏特'), findsNothing);
    expect(
      tester.widget<VersionChip>(
        find.widgetWithText(VersionChip, '剑/盾'),
      ).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('来源筛选 chips 生效（学习器），「全部」可恢复', (tester) async {
    await pumpDetail(tester);
    await openTab(tester, '招式');
    await collapseHeader(tester);
    await tester.tap(find.widgetWithText(VersionChip, '剑/盾'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('共 2 个招式'), findsOneWidget);

    // 只看学习器（machine）：剑/盾组只剩挖洞。
    await tester.tap(find.text('学习器').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('共 1 个招式'), findsOneWidget);
    expect(find.text('挖洞'), findsOneWidget);
    expect(find.text('撞击'), findsNothing);

    // 「全部」恢复。
    await tester.tap(find.text('全部').first);
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('共 2 个招式'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
