import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/features/favorites/favorites_page.dart';
import 'package:fl_pokedex/features/favorites/providers.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import 'fakes.dart';

typedef _Harness = (
  ProviderContainer container,
  FakeSummariesPokedexRepository pokedex,
  FakeFavoritesRepository favorites,
);

/// 测试用最小路由：收藏页 + 详情占位，供 `context.push` 生效。
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(
        path: '/favorites',
        builder: (_, __) => const FavoritesPage(),
      ),
      GoRoute(
        path: '/pokemon/:speciesId',
        builder: (_, state) => Scaffold(
          appBar: AppBar(),
          body: Text('detail-${state.pathParameters['speciesId']}'),
        ),
      ),
    ],
  );
}

FakeSummariesPokedexRepository _fakePokedex() {
  return FakeSummariesPokedexRepository({
    1: makeSummary(speciesId: 1, nameZh: '妙蛙种子', nameEn: 'Bulbasaur'),
    4: makeSummary(speciesId: 4, nameZh: '小火龙', nameEn: 'Charmander'),
    25: makeSummary(speciesId: 25, nameZh: '皮卡丘', nameEn: 'Pikachu'),
  });
}

/// 紧凑视口（400×800）下泵入收藏页，等待流首推 + 摘要解析就绪。
Future<_Harness> _pumpFavorites(
  WidgetTester tester, {
  List<int> favorites = const [],
  List<int> recents = const [],
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final pokedex = _fakePokedex();
  final favoritesRepo = FakeFavoritesRepository(
    initialFavorites: favorites,
    initialRecents: recents,
  );
  final container = ProviderContainer(
    overrides: fakeRepositoryOverrides(
      pokedex: pokedex,
      favorites: favoritesRepo,
    ),
  );
  addTearDown(container.dispose);
  addTearDown(favoritesRepo.dispose);

  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: _testRouter(),
      ),
    ),
  );
  // 流首推 → 摘要解析 → 网格数据落地。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  return (container, pokedex, favoritesRepo);
}

void main() {
  testWidgets('收藏网格：渲染 2 只收藏卡片', (tester) async {
    final (_, _, _) = await _pumpFavorites(tester, favorites: [1, 4]);

    expect(find.byType(PokemonCard), findsNWidgets(2));
    expect(find.text('妙蛙种子'), findsOneWidget);
    expect(find.text('小火龙'), findsOneWidget);
    expect(find.byType(PokemonListTile), findsNothing);
  });

  testWidgets('取消收藏后卡片随流消失', (tester) async {
    final (_, _, favorites) = await _pumpFavorites(tester, favorites: [1, 4]);

    // 两张卡片均常显实心心形；点第一张（妙蛙种子）取消收藏。
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.favorite).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(favorites.favorites, [4]);
    expect(find.byType(PokemonCard), findsOneWidget);
    expect(find.text('妙蛙种子'), findsNothing);
    expect(find.text('小火龙'), findsOneWidget);
  });

  testWidgets('最近浏览行：区块标题 + 最新在前，点按导航并记录', (tester) async {
    var (_, pokedex, favorites) = await _pumpFavorites(
      tester,
      favorites: const [1],
      recents: const [25, 4], // 尾部最新 → 行内应先皮卡丘后小火龙。
    );

    expect(find.text('最近浏览'), findsOneWidget);
    expect(find.text('皮卡丘'), findsOneWidget);
    expect(find.text('小火龙'), findsOneWidget);

    // 行内顺序：仓储「最新在尾部」→ 展示反转，小火龙（最新）在最左。
    final pikachuCenter = tester.getCenter(find.text('皮卡丘'));
    final charmanderCenter = tester.getCenter(find.text('小火龙'));
    expect(charmanderCenter.dx, lessThan(pikachuCenter.dx));

    await tester.tap(find.text('皮卡丘'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 导航到详情页 + addRecent 已记录（25 已在尾部 → [4, 25] 不变）。
    expect(find.text('detail-25'), findsOneWidget);
    expect(favorites.recents, [4, 25]);
    expect(pokedex.summariesCalls, isNotEmpty);

    // 回到收藏页时视图仍正常。
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('最近浏览'), findsOneWidget);
  });

  testWidgets('最近浏览行宽 76（图 + 名）', (tester) async {
    await _pumpFavorites(
      tester,
      favorites: const [1],
      recents: const [25],
    );

    final nameFinder = find.text('皮卡丘');
    expect(nameFinder, findsOneWidget);
    final thumb = tester.getSize(
      find.ancestor(
        of: nameFinder,
        matching: find.byType(SizedBox),
      ).first,
    );
    expect(thumb.width, 76);
  });

  testWidgets('列表视图模式（SP view_mode=list）渲染列表行', (tester) async {
    await _pumpFavorites(
      tester,
      favorites: const [1, 4],
      prefs: const {'view_mode': 'list'},
    );

    expect(find.byType(PokemonListTile), findsNWidgets(2));
    expect(find.byType(PokemonCard), findsNothing);
    expect(
      containerOf(tester).read(favoritesViewModeProvider),
      FavoritesViewMode.list,
    );
  });

  testWidgets('空态：无收藏且无浏览记录时显示指引', (tester) async {
    await _pumpFavorites(tester);

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('还没有收藏'), findsOneWidget);
    expect(find.text('去图鉴点亮心形吧'), findsOneWidget);
    expect(find.text('最近浏览'), findsNothing);
  });

  testWidgets('收藏为空但最近浏览非空：浏览行保留 + 收藏空态并存', (tester) async {
    await _pumpFavorites(tester, recents: const [25]);

    expect(find.text('最近浏览'), findsOneWidget);
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('还没有收藏'), findsOneWidget);
    expect(find.byType(PokemonCard), findsNothing);
  });
}

/// 从已绑定的 tester 中取 ProviderContainer（scope 唯一）。
ProviderContainer containerOf(WidgetTester tester) {
  final element = tester.element(find.byType(FavoritesPage));
  return ProviderScope.containerOf(element);
}
