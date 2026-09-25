import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/features/pokedex/pokedex_home_page.dart';
import 'package:fl_pokedex/features/pokedex/providers.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import 'fakes.dart';

typedef _Harness = (
  ProviderContainer container,
  FakePokedexRepository pokedex,
  FakeFavoritesRepository favorites,
);

/// 测试用最小路由：首页 + 详情占位，供 `context.push` 生效。
GoRouter _testRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const PokedexHomePage()),
      GoRoute(
        path: '/pokemon/:speciesId',
        builder: (_, state) => Scaffold(
          body: Text('detail-${state.pathParameters['speciesId']}'),
        ),
      ),
    ],
  );
}

/// 紧凑视口（400×800）下泵入首页，等待首屏数据就绪。
Future<_Harness> _pumpHome(
  WidgetTester tester, {
  List<int> initialFavorites = const [],
}) async {
  SharedPreferences.setMockInitialValues(const {});
  final pokedex = FakePokedexRepository();
  final favorites = FakeFavoritesRepository(initialFavorites: initialFavorites);
  final container = ProviderContainer(
    overrides: fakeRepositoryOverrides(pokedex: pokedex, favorites: favorites),
  );
  addTearDown(container.dispose);
  addTearDown(favorites.dispose);

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
  // 首载骨架 → 数据就绪；再留一拍让收藏流首推落地。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 50));
  return (container, pokedex, favorites);
}

void main() {
  testWidgets('初始加载渲染网格卡片，滚动到底部追加至 70 条', (tester) async {
    final (container, _, _) = await _pumpHome(tester);

    final initial = container.read(pokemonListProvider).requireValue;
    expect(initial.items, hasLength(60));
    expect(initial.total, 70);
    expect(find.byType(PokemonCard), findsWidgets);

    // 一次大距离拖拽直达底部（extentAfter < 600 触发 loadMore）。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -60000));
    await tester.pump(const Duration(milliseconds: 200));

    final loaded = container.read(pokemonListProvider).requireValue;
    expect(loaded.items, hasLength(70));
    expect(loaded.items.map((e) => e.speciesId).toSet(), hasLength(70));

    // 再次拉到底，末尾条目可见。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -60000));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('#070'), findsOneWidget);
  });

  testWidgets('输入「皮卡」：200ms 防抖后重载，只剩匹配结果', (tester) async {
    final (container, pokedex, _) = await _pumpHome(tester);

    await tester.enterText(find.byType(TextField), '皮卡');
    // 防抖窗口内不应触发查询（首载已产生 query+count 两次调用）。
    await tester.pump(const Duration(milliseconds: 100));
    expect(pokedex.queryLog, hasLength(2));

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    final state = container.read(pokemonListProvider).requireValue;
    expect(pokedex.lastFilter?.query, '皮卡');
    expect(state.total, 1);
    expect(state.items.single.nameZh, '皮卡丘');
    expect(find.text('皮卡丘'), findsOneWidget);
    expect(find.text('宝可梦001'), findsNothing);
  });

  testWidgets('切换列表视图后渲染 PokemonListTile', (tester) async {
    await _pumpHome(tester);

    expect(find.byType(PokemonCard), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('view_mode_toggle')));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PokemonListTile), findsWidgets);
    expect(find.byType(PokemonCard), findsNothing);
  });

  testWidgets('空结果显示 EmptyState，「清除筛选」一键恢复', (tester) async {
    final (container, _, _) = await _pumpHome(tester);

    container.read(filterProvider.notifier).updateQuery('不存在的关键词');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('清除筛选'), findsOneWidget);

    await tester.tap(find.text('清除筛选'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(EmptyState), findsNothing);
    expect(
      container.read(pokemonListProvider).requireValue.items,
      hasLength(60),
    );
    // 清除筛选同步清空搜索框。
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, isEmpty);
  });

  testWidgets('收藏心形：初始收藏常显实心，点击取消并随流更新', (tester) async {
    final (_, _, favorites) = await _pumpHome(tester, initialFavorites: [1]);

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pump(const Duration(milliseconds: 100));

    expect(favorites.favorites, isEmpty);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('点按卡片行记录最近浏览（addRecent）', (tester) async {
    final (_, _, favorites) = await _pumpHome(tester);

    // 详情路由未包裹 go_router，push 会抛错；吞掉后仅验证 addRecent 副作用。
    await tester.tap(find.text('宝可梦001').first);
    await tester.pump(const Duration(milliseconds: 50));

    expect(favorites.recents, [1]);
  });
}
