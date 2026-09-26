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
/// - 触摸设备：页面级水平滑动切换（左滑 = 下一只，右滑 = 上一只），
///   累计位移超阈值触发一次，快甩（松手速度超阈值）兜底；
/// - 桌面键盘：← / → 仅在页面键盘锚点自身持焦时生效；点按页面空白处
///   会把焦点收回锚点（TabBar 左右箭头切 tab 的行为不受抢占）；
/// - 顺序 = national_dex（fixture：1 → 25），首尾边界原地不动；
/// - 全页模式走 pushReplacement 替换栈顶；双栏面板注入 onSwitchSpecies
///   回调（不导航）。
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

  group('切换按钮已移除', () {
    testWidgets('工具栏不再渲染「上一只 / 下一只」箭头按钮', (tester) async {
      await pumpPage(tester);

      expect(find.byTooltip('上一只'), findsNothing);
      expect(find.byTooltip('下一只'), findsNothing);
    });
  });

  group('水平滑动切换', () {
    testWidgets('左滑：#001 切到 #025（路由替换栈顶）', (tester) async {
      await pumpPage(tester);

      // 在头部编号文本上水平左滑（该区域无内部横滚组件，页面级手势获胜）。
      await tester.drag(find.text('#001'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(find.text('#025'), findsOneWidget);
      expect(find.text('Pikachu · ピカチュウ'), findsOneWidget);
      expect(find.text('#001'), findsNothing);
    });

    testWidgets('右滑：从 #025 回到 #001', (tester) async {
      await pumpPage(tester, speciesId: 25);

      await tester.drag(find.text('#025'), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(find.text('#001'), findsOneWidget);
      expect(find.text('Bulbasaur · フシギダネ'), findsOneWidget);
    });

    testWidgets('#001 右滑越界：原地不动', (tester) async {
      await pumpPage(tester);

      await tester.drag(find.text('#001'), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(find.text('#001'), findsOneWidget);
      expect(find.text('#025'), findsNothing);
    });

    testWidgets('#025 左滑越界：原地不动', (tester) async {
      await pumpPage(tester, speciesId: 25);

      await tester.drag(find.text('#025'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(find.text('#025'), findsOneWidget);
      expect(find.text('#001'), findsNothing);
    });

    testWidgets('垂直拖动不触发切换（垂直滚动与滑动切换互不干扰）', (tester) async {
      await pumpPage(tester);

      await tester.drag(find.text('#001'), const Offset(0, -120));
      await tester.pumpAndSettle();

      expect(find.text('#025'), findsNothing);
      expect(find.text('#001'), findsOneWidget);
    });

    testWidgets('快甩（位移不足阈值、松手速度足够）也切换', (tester) async {
      await pumpPage(tester);

      // 位移 60px 未达 72px 阈值；速度 1200px/s 超过快甩阈值：
      // 走 onHorizontalDragEnd 的 primaryVelocity 兜底分支。
      await tester.fling(find.text('#001'), const Offset(-60, 0), 1200);
      await tester.pumpAndSettle();

      expect(find.text('#025'), findsOneWidget);
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

    testWidgets('焦点在 Tab 上时 → 不切换（TabBar 箭头键行为不被抢占）', (tester) async {
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

    testWidgets('点按页面空白处后焦点回到锚点，← / → 恢复可用', (tester) async {
      await pumpPage(tester);

      // 模拟焦点已离开页面锚点（如点过 Tab）。
      firstTabNode(tester).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('#025'), findsNothing);

      // 点按页面空白（头部编号文本，无任何按钮语义）→ 焦点收回键盘锚点。
      await tester.tap(find.text('#001'));
      await tester.pump();
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        'pokemon_detail_keyboard_anchor',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('#025'), findsOneWidget);
    });
  });

  group('双栏面板切换契约（壳层注入 onSwitchSpecies）', () {
    testWidgets('左滑只回调目标 id，不做路由导航', (tester) async {
      final switchedTo = <int>[];
      favorites.seed(const {});
      await tester.pumpWidget(buildPane(switchedTo));
      await tester.pumpAndSettle();

      // 面板嵌入：无返回键（showBackButton=false）。
      expect(find.byType(BackButton), findsNothing);

      await tester.drag(find.text('#001'), const Offset(-150, 0));
      await tester.pumpAndSettle();

      expect(switchedTo, [25]);
      // 回调模式不走路由：仍是当前页面的 #001 内容（壳层负责按
      // paneSelectionProvider 重建面板）。
      expect(find.text('#001'), findsOneWidget);
    });

    testWidgets('右滑越界（#001 无上一只）不回调', (tester) async {
      final switchedTo = <int>[];
      favorites.seed(const {});
      await tester.pumpWidget(buildPane(switchedTo));
      await tester.pumpAndSettle();

      await tester.drag(find.text('#001'), const Offset(150, 0));
      await tester.pumpAndSettle();

      expect(switchedTo, isEmpty);
    });
  });
}
