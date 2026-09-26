import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';

import 'fake_repositories.dart';

/// 上一只 / 下一只切换（单元 C）：
/// - 按钮（chevron_left / chevron_right）挂在工具栏两端，tooltip「上一只 / 下一只」；
/// - 顺序 = national_dex（fixture：1 → 25），首尾边界禁用置灰；
/// - 全页 tap / 键盘 ← → 走 context.go 替换栈顶；
/// - 键盘仅在页面键盘锚点自身持焦时生效（TabBar 左右箭头不受抢占）。
void main() {
  late FakePokedexRepository repo;
  late FakeFavoritesRepository favorites;

  setUp(() {
    repo = FakePokedexRepository();
    favorites = FakeFavoritesRepository();
  });

  tearDown(() {
    favorites.dispose();
  });

  Widget buildApp({int speciesId = 1}) {
    return ProviderScope(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(repo),
        favoritesRepositoryProvider.overrideWithValue(favorites),
      ],
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/pokemon/$speciesId',
          routes: [
            GoRoute(
              path: '/pokemon/:speciesId',
              builder: (context, state) => PokemonDetailPage(
                speciesId:
                    int.tryParse(state.pathParameters['speciesId'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, {int speciesId = 1}) async {
    favorites.seed(const {});
    await tester.pumpWidget(buildApp(speciesId: speciesId));
    await tester.pumpAndSettle();
  }

  /// 双栏详情面板契约：showBackButton=false + 注入 onSwitchSpecies
  /// （壳层写 paneSelectionProvider，不导航）。
  Widget buildPane(
    List<int> switchedTo,
  ) {
    return ProviderScope(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(repo),
        favoritesRepositoryProvider.overrideWithValue(favorites),
      ],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(
          body: PokemonDetailPage(
            speciesId: 1,
            showBackButton: false,
            onSwitchSpecies: switchedTo.add,
          ),
        ),
      ),
    );
  }

  /// TabBar 第一个 tab 的焦点节点（Tab widget 自身的 Focus scope）。
  FocusNode firstTabNode(WidgetTester tester) =>
      Focus.of(tester.element(find.text('图鉴说明').first));

  group('上一只 / 下一只按钮', () {
    testWidgets('工具栏两端各一枚，tooltip 与图标语义为上一只 / 下一只',
        (tester) async {
      await pumpPage(tester);

      final prev = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('上一只'),
          matching: find.byType(IconButton),
        ).first,
      );
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('下一只'),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      // #001：上一只越界禁用（onPressed null → Material 主题 disabled 前景），
      // 下一只可用。
      expect(prev.onPressed, isNull);
      expect(next.onPressed, isNotNull);
    });

    testWidgets('tap 下一只：编号 / 名称切换到 #025（路由替换栈顶）',
        (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byTooltip('下一只'));
      await tester.pumpAndSettle();

      expect(find.text('#025'), findsOneWidget);
      expect(find.text('Pikachu · ピカチュウ'), findsOneWidget);
      expect(find.text('#001'), findsNothing);
    });

    testWidgets('tap 上一只：从 #025 回到 #001', (tester) async {
      await pumpPage(tester, speciesId: 25);

      await tester.tap(find.byTooltip('上一只'));
      await tester.pumpAndSettle();

      expect(find.text('#001'), findsOneWidget);
      expect(find.text('Bulbasaur · フシギダネ'), findsOneWidget);
    });

    testWidgets('#025 的下一只越界禁用', (tester) async {
      await pumpPage(tester, speciesId: 25);

      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('下一只'),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(next.onPressed, isNull);
    });
  });

  group('桌面键盘 ← / →', () {
    testWidgets('锚点持焦：→ 切下一只、← 切回上一只', (tester) async {
      await pumpPage(tester);

      // 前置自证：页面键盘锚点自动持焦。
      expect(FocusManager.instance.primaryFocus?.debugLabel,
          'pokemon_detail_keyboard_anchor');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('#025'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('#001'), findsOneWidget);
    });

    testWidgets('焦点在 Tab 上时 → 不切换（TabBar 箭头键行为不被抢占）',
        (tester) async {
      await pumpPage(tester);

      final tabNode = firstTabNode(tester);
      tabNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      // 未切换到下一只；焦点也没有被键盘锚点收回（留给 Tab 遍历）。
      expect(find.text('#025'), findsNothing);
      expect(find.text('#001'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('pokemon_detail_keyboard_anchor'),
      );
    });
  });

  group('双栏面板切换契约（壳层注入 onSwitchSpecies）', () {
    testWidgets('tap 下一只只回调目标 id，不做路由导航', (tester) async {
      final switchedTo = <int>[];
      favorites.seed(const {});
      await tester.pumpWidget(buildPane(switchedTo));
      await tester.pumpAndSettle();

      // 面板嵌入：无返回键（showBackButton=false），上一只越界禁用。
      expect(find.byType(BackButton), findsNothing);
      final prev = tester.widget<IconButton>(
        find.ancestor(
          of: find.byTooltip('上一只'),
          matching: find.byType(IconButton),
        ).first,
      );
      expect(prev.onPressed, isNull);

      await tester.tap(find.byTooltip('下一只'));
      await tester.pumpAndSettle();

      expect(switchedTo, [25]);
      // 回调模式不走路由：仍是当前页面的 #001 内容（壳层负责按
      // paneSelectionProvider 重建面板）。
      expect(find.text('#001'), findsOneWidget);
    });
  });
}
