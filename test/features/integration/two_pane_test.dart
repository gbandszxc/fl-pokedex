import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/router.dart';
import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/domain/models/ability_ref.dart';
import 'package:fl_pokedex/domain/models/evolution.dart';
import 'package:fl_pokedex/domain/models/flavor_entry.dart';
import 'package:fl_pokedex/domain/models/form_summary.dart';
import 'package:fl_pokedex/domain/models/filters.dart';
import 'package:fl_pokedex/domain/models/move_entry.dart';
import 'package:fl_pokedex/domain/models/pokemon_summary.dart';
import 'package:fl_pokedex/domain/models/refs.dart';
import 'package:fl_pokedex/domain/models/species_info.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';
import 'package:fl_pokedex/features/pokedex/providers.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/features/settings/providers.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import '../pokedex/fakes.dart';

/// 在首页 Fake（70 条合成数据）之上补齐 species 1 的详情接口：
/// #001 以「妙蛙种子」呈现（与详情 fixture 一致），供双栏详情面板
/// 端到端渲染（名称 / 属性 / 种族值 / 图鉴说明）。
class _TwoPaneFakePokedexRepository extends FakePokedexRepository {
  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) async {
    final items = await super.queryPokemon(f, limit: limit, offset: offset);
    return [
      for (final item in items)
        item.speciesId == 1
            ? item.copyWith(
                nameZh: '妙蛙种子',
                nameEn: 'Bulbasaur',
                nameJa: 'フシギダネ',
                typeIds: ['grass', 'poison'],
              )
            : item,
    ];
  }

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(
    List<int> speciesIds,
  ) async {
    final all =
        await queryPokemon(const FilterState(), limit: 1 << 20, offset: 0);
    return [
      for (final id in speciesIds)
        ...all.where((summary) => summary.speciesId == id),
    ];
  }

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) async => SpeciesInfo(
        speciesId: speciesId,
        nationalDex: speciesId,
        generationId: 1,
        genusZh: speciesId == 1 ? '种子宝可梦' : null,
        genusEn: speciesId == 1 ? 'Seed Pokémon' : null,
      );

  @override
  Future<List<FormSummary>> getForms(int speciesId) async {
    if (speciesId == 1) {
      return const [
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
          artworkAsset: null,
          typeIds: ['grass', 'poison'],
          heightM: 0.7,
          weightKg: 6.9,
        ),
      ];
    }
    if (speciesId == 2) {
      // #002 通用默认形态（typeCycle[2 % 4] = water，与列表 fixture 一致），
      // 供双栏「下一只」切换后的面板渲染。
      return const [
        FormSummary(
          formId: 2,
          speciesId: 2,
          formIdentifier: null,
          formNameZh: '宝可梦002',
          formNameEn: 'Pokemon002',
          isDefault: true,
          isMega: false,
          isGmax: false,
          isRegional: false,
          artworkAsset: null,
          typeIds: ['water'],
          heightM: null,
          weightKg: null,
        ),
      ];
    }
    throw StateError('fixture 只有 species 1 / 2 的形态');
  }

  @override
  Future<StatBlock> getFormStats(int formId) async => const StatBlock(
        hp: 45,
        attack: 49,
        defense: 49,
        specialAttack: 65,
        specialDefense: 65,
        speed: 45,
      );

  @override
  Future<List<AbilityRef>> getFormAbilities(int formId) async => const [
        AbilityRef(id: 65, nameZh: '茂盛', nameEn: 'Overgrow', isHidden: false),
      ];

  @override
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) async => [
        FlavorEntry(
          versionId: 1,
          versionIdentifier: 'red',
          versionNameZh: '红',
          versionNameEn: 'Red',
          generationId: 1,
          language: 'zh_hans',
          text: speciesId == 1 ? '种子在出生时埋在土里。' : '通用说明。',
        ),
      ];

  @override
  Future<List<FlavorEntry>> getFormFlavorTexts(int formId) async =>
      const [];

  /// 妙蛙种子三段链（species 1 → 2 → 3）：供双栏回归测试验证进化分区
  /// 渲染节点（节点名 / 编号自足，不查列表仓储）。
  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) async {
    if (speciesId != 1 && speciesId != 2 && speciesId != 3) {
      return null;
    }
    EvolutionEdge edge(int from, int to, int minLevel) => EvolutionEdge(
          chainId: 1,
          fromSpeciesId: from,
          toSpeciesId: to,
          trigger: 'level-up',
          minLevel: minLevel,
          needsRain: false,
          turnUpsideDown: false,
        );
    EvolutionNode node(int id, String name, List<EvolutionEdge> children) =>
        EvolutionNode(
          speciesId: id,
          nationalDex: id,
          nameZh: name,
          thumbAsset: null,
          children: children,
        );
    final root = node(1, '妙蛙种子', [edge(1, 2, 16)]);
    return EvolutionTree(
      root: root,
      nodesBySpeciesId: {
        1: root,
        2: node(2, '妙蛙草', [edge(2, 3, 32)]),
        3: node(3, '妙蛙花', const <EvolutionEdge>[]),
      },
    );
  }

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) async => const [
        VersionGroupRef(id: 'scarlet-violet', labelZh: '朱/紫', generationId: 9),
      ];

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) async {
    final moves = <MoveEntry>[
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
        nameZh: '飞叶快刀',
        nameEn: 'Razor Leaf',
        typeId: 'grass',
        damageClass: 'physical',
        power: 55,
        pp: 25,
        accuracy: 95,
        level: 7,
        method: 'level_up',
        versionGroup: 'scarlet-violet',
      ),
    ];
    if (methods == null || methods.isEmpty) return moves;
    return moves.where((m) => methods.contains(m.method)).toList();
  }
}

typedef _Harness = (
  ProviderContainer container,
  FakeFavoritesRepository favorites,
);

/// 真实路由（routerProvider）+ Fake 仓储泵入应用，窗口 [size]。
Future<_Harness> _pumpApp(WidgetTester tester, {required Size size}) async {
  SharedPreferences.setMockInitialValues(const {});
  final pokedex = _TwoPaneFakePokedexRepository();
  final favorites = FakeFavoritesRepository();
  final container = ProviderContainer(
    overrides: fakeRepositoryOverrides(pokedex: pokedex, favorites: favorites),
  );
  addTearDown(container.dispose);
  addTearDown(favorites.dispose);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: container.read(routerProvider),
      ),
    ),
  );
  // 首载骨架 → 数据就绪；再留一拍让收藏 / 密度等异步恢复落地。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  return (container, favorites);
}

/// 当前路由地址（验证「面板选中 vs 路由跳转」行为）。
///
/// 注意用 [RouteMatch.matchedLocation] 而非 `currentConfiguration.uri`：
/// 后者不含 `push` 产生的 ImperativeRouteMatch（文档明确排除）。
String _location(ProviderContainer container) =>
    container
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .last
        .matchedLocation;

/// 详情面板数据就绪的泵帧（fake 全为即时异步，少量有界泵即可）。
Future<void> _pumpDetailReady(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
}

/// 首行网格卡片数 = 当前窗口下的网格列数。
int _gridColumnCount(WidgetTester tester) {
  final cards = find.byType(PokemonCard);
  final count = cards.evaluate().length;
  final tops = List<double>.filled(count, 0);
  var minY = double.infinity;
  for (var i = 0; i < count; i++) {
    final dy = tester.getTopLeft(cards.at(i)).dy;
    tops[i] = dy;
    if (dy < minY) {
      minY = dy;
    }
  }
  return tops.where((dy) => dy - minY < 0.5).length;
}

SliverGridDelegateWithMaxCrossAxisExtent _gridDelegate(WidgetTester tester) =>
    tester.widget<SliverGrid>(find.byType(SliverGrid).first).gridDelegate
        as SliverGridDelegateWithMaxCrossAxisExtent;

void main() {
  testWidgets('宽 ≥1080 双栏：详情面板空态 → 点 #001 内联渲染且不导航',
      (tester) async {
    final (container, favorites) =
        await _pumpApp(tester, size: const Size(1200, 900));

    // 双栏结构：NavigationRail + 列表面板（含标题行 / 搜索）+ 空态详情面板。
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('图鉴'), findsWidgets);
    expect(find.text('从左侧选择宝可梦'), findsOneWidget);
    expect(find.text('查看详情'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(_location(container), '/');

    // 点 #001 卡片：写选中态，详情面板内联出现妙蛙种子，路由不变化。
    await tester.tap(find.text('妙蛙种子').first);
    await tester.pump();
    expect(container.read(paneSelectionProvider), 1);
    await _pumpDetailReady(tester);

    expect(find.text('妙蛙种子'), findsWidgets);
    expect(find.text('#001'), findsWidgets);
    expect(_location(container), '/'); // 未发生路由 push
    expect(favorites.recents, [1]); // 点选仍记录最近浏览
    // 列表面板仍在原位（没有整页详情覆盖窗口）。
    expect(find.text('搜索 名称 / 编号'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing); // 面板嵌入无返回按钮
  });

  testWidgets('双栏回归：进化与招式分区正常渲染（当前路由 / 无 :speciesId 参数）',
      (tester) async {
    final (container, _) = await _pumpApp(tester, size: const Size(1200, 900));

    // 选中 #001：详情面板内联渲染。此时路由是图鉴分支 /，分区 speciesId
    // 必须来自页面显式传参（回归防护：曾从 GoRouterState 读取而拿到 null，
    // 误显示「没有进化关系」「无法识别当前宝可梦」空态）。
    await tester.tap(find.text('妙蛙种子').first);
    await _pumpDetailReady(tester);
    // 进化 / 招式分区数据链多层异步（树 / 详情 → 版本组 → 学习集），泵足帧。
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }

    expect(_location(container), '/');
    // 进化分区渲染出三段链的后继节点，不误显示「没有进化关系」空态。
    expect(find.text('该宝可梦没有进化关系'), findsNothing);
    expect(find.text('妙蛙草'), findsOneWidget);
    expect(find.text('妙蛙花'), findsOneWidget);
    // 招式分区渲染出行与计数，不误显示「无法识别当前宝可梦」空态。
    expect(find.text('无法识别当前宝可梦，请从图鉴重新进入。'), findsNothing);
    expect(find.text('共 2 个招式'), findsOneWidget);
    expect(find.text('撞击'), findsWidgets);
    expect(find.text('飞叶快刀'), findsWidgets);
  });

  testWidgets('双栏：详情面板滑动切换写选中态，面板与列表选中跟随且不导航',
      (tester) async {
    final (container, favorites) =
        await _pumpApp(tester, size: const Size(1200, 900));

    // 选中 #001 → 详情面板内联渲染。
    await tester.tap(find.text('妙蛙种子').first);
    await tester.pump();
    await _pumpDetailReady(tester);
    expect(container.read(paneSelectionProvider), 1);

    // 面板内水平滑动切换：左滑 = 下一只。定位用面板头的编号文本
    // （直接 find.text 会同时命中列表卡片，故收窄到详情页子树；
    // .first：进化分区节点也带编号文本，取遍历序首个 = 面板头编号）。
    Finder paneDexNumber(String label) => find.descendant(
          of: find.byType(PokemonDetailPage),
          matching: find.text(label),
        ).first;

    // 左滑：写 paneSelectionProvider（不导航），KeyedSubtree 按 ValueKey
    // 重建面板为 #002，列表选中描边随之跟随。
    await tester.drag(paneDexNumber('#001'), const Offset(-150, 0));
    await _pumpDetailReady(tester);

    expect(container.read(paneSelectionProvider), 2);
    expect(_location(container), '/'); // 切换不走路由
    expect(find.text('#002'), findsWidgets); // 面板头部 + 列表卡片
    // 面板切换按新条目记录最近浏览。
    expect(favorites.recents, [1, 2]);

    // 反向右滑（= 上一只）：回 #001。
    await tester.drag(paneDexNumber('#002'), const Offset(150, 0));
    await _pumpDetailReady(tester);
    expect(container.read(paneSelectionProvider), 1);
    expect(find.text('#001'), findsWidgets);

    // 边界：#001 已是首位，右滑越界原地不动。
    await tester.drag(paneDexNumber('#001'), const Offset(150, 0));
    await _pumpDetailReady(tester);
    expect(container.read(paneSelectionProvider), 1);
  });

  testWidgets('宽 <1080 单栏：点卡片推入详情路由（行为不变）', (tester) async {
    final (container, _) = await _pumpApp(tester, size: const Size(800, 600));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('从左侧选择宝可梦'), findsNothing); // 无双栏空态
    expect(container.read(paneSelectionProvider), isNull);

    await tester.tap(find.text('妙蛙种子').first);
    await _pumpDetailReady(tester);

    expect(_location(container), '/pokemon/1'); // 正常 push
    expect(find.byType(BackButton), findsOneWidget); // 全页详情有返回
    expect(find.text('妙蛙种子'), findsWidgets);
  });

  testWidgets('1200 宽：卡片密度切换 舒适 200/244 ↔ 紧凑 156/200', (tester) async {
    final (container, _) =
        await _pumpApp(tester, size: const Size(1200, 900));

    // 舒适档：extent 200 + 固定卡高 244（两档密度均弃用宽高比）。
    expect(_gridDelegate(tester).maxCrossAxisExtent, 200);
    expect(_gridDelegate(tester).mainAxisExtent, 244);

    container.read(cardDensityProvider.notifier).set(CardDensity.compact);
    await tester.pump();

    // 紧凑档：extent 156 + 固定卡高 200。
    expect(_gridDelegate(tester).maxCrossAxisExtent, 156);
    expect(_gridDelegate(tester).mainAxisExtent, 200);

    container.read(cardDensityProvider.notifier).set(CardDensity.comfortable);
    await tester.pump();
    expect(_gridDelegate(tester).maxCrossAxisExtent, 200);
    expect(_gridDelegate(tester).mainAxisExtent, 244);
  });

  testWidgets('小屏 360×800（MuMu 逻辑宽）舒适档：网格无纵向溢出', (tester) async {
    await _pumpApp(tester, size: const Size(360, 800));

    // 首屏渲染 ≥6 张卡片，无任何布局异常。
    expect(tester.takeException(), isNull);
    expect(find.byType(PokemonCard), findsAtLeastNWidgets(6));

    // 直达底部强制构建全部卡片，全程无布局异常。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -60000));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.byType(PokemonCard), findsWidgets);
  });

  testWidgets('最小支持宽 320×700 舒适档：网格无纵向溢出', (tester) async {
    await _pumpApp(tester, size: const Size(320, 700));

    expect(tester.takeException(), isNull);
    // 视口更矮：首屏惰性构建 4 张（固定卡高 244），无异常即可。
    expect(find.byType(PokemonCard), findsAtLeastNWidgets(4));

    // 直达底部强制构建全部卡片（含最窄列布局），全程无布局异常。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -60000));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(find.byType(PokemonCard), findsWidgets);
  });

  testWidgets('紧凑档列数多于舒适档（1400 宽双栏面板内）', (tester) async {
    final (container, _) =
        await _pumpApp(tester, size: const Size(1400, 900));

    final comfortableColumns = _gridColumnCount(tester);
    expect(comfortableColumns, greaterThan(1));

    container.read(cardDensityProvider.notifier).set(CardDensity.compact);
    await tester.pump();

    final compactColumns = _gridColumnCount(tester);
    expect(compactColumns, greaterThan(comfortableColumns));
  });

  testWidgets('键盘：/ 聚焦搜索框，Esc 清空搜索并失焦', (tester) async {
    final (container, favorites) =
        await _pumpApp(tester, size: const Size(800, 600));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode, isNotNull);
    expect(field.focusNode!.hasFocus, isFalse);

    // `/`：聚焦搜索框（字符不被插入）。
    await tester.sendKeyEvent(LogicalKeyboardKey.slash);
    await tester.pump();
    expect(field.focusNode!.hasFocus, isTrue);

    // 输入搜索词，防抖落盘。
    await tester.enterText(find.byType(TextField), '皮卡');
    await tester.pump(const Duration(milliseconds: 300));
    expect(container.read(filterProvider).query, '皮卡');

    // Esc：清空输入框 + 立即重载 + 失焦。
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 300));

    final after = tester.widget<TextField>(find.byType(TextField));
    expect(after.controller!.text, isEmpty);
    expect(field.focusNode!.hasFocus, isFalse);
    expect(container.read(filterProvider).query, isEmpty);
    expect(favorites.recents, isEmpty);
  });
}
