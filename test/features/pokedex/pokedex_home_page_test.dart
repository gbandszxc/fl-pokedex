import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/search_history.dart';
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

  testWidgets('只记录提交或打开结果的搜索，支持重搜和单条删除', (tester) async {
    final (container, _, _) = await _pumpHome(tester);
    final field = find.byType(TextField);

    await tester.enterText(field, '草稿');
    await tester.pump(const Duration(milliseconds: 250));
    expect(container.read(searchHistoryProvider).requireValue, isEmpty);

    await tester.enterText(field, '001');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.enterText(field, ' 001 ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.enterText(field, '皮卡');
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    await tester.tap(find.text('皮卡丘'));
    await tester.pumpAndSettle();
    expect(container.read(searchHistoryProvider).requireValue, ['皮卡', '001']);

    Navigator.of(tester.element(find.textContaining('detail-'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.tap(find.byTooltip('清空搜索'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('删除搜索记录：皮卡'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('删除搜索记录：皮卡'), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(container.read(filterProvider).query, '001');
    expect(find.byTooltip('删除搜索记录：001'), findsNothing);
    expect(container.read(searchHistoryProvider).requireValue, ['001']);
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

  testWidgets('搜别名显示 matchHint；点搜索栏清空按钮立即复位', (tester) async {
    final (container, _, _) = await _pumpHome(tester);

    await tester.enterText(find.byType(TextField), '比雕');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('宝可梦018'), findsOneWidget);
    final hintLine = find.byType(MatchHintLine);
    expect(hintLine, findsOneWidget);
    expect(
      find.descendant(of: hintLine, matching: find.text('别名')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: hintLine, matching: find.text('比雕')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('clear_search_query')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(filterProvider).query, isEmpty);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(
      container.read(pokemonListProvider).requireValue.total,
      70,
    );
  });

  testWidgets('激活分类过滤在筛选栏显示可关闭芯片', (tester) async {
    final (container, _, _) = await _pumpHome(tester);

    container.read(filterProvider.notifier).setGenus('种子宝可梦');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    final chip = find.byKey(const ValueKey('active_genus_chip'));
    expect(chip, findsOneWidget);
    expect(find.text('分类：种子宝可梦 ×'), findsOneWidget);
    expect(container.read(pokemonListProvider).requireValue.total, 1);

    await tester.tap(chip);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    expect(container.read(filterProvider).genus, isNull);
    expect(find.byKey(const ValueKey('active_genus_chip')), findsNothing);
    expect(container.read(pokemonListProvider).requireValue.total, 70);
  });
}
