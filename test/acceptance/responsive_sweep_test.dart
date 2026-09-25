import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/router.dart';
import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/features/pokedex/pokedex_home_page.dart';

import '../features/pokedex/fakes.dart';

/// 响应式断点巡检（DESIGN.md §3 / architecture.md §2）：
///
/// 四个代表视口各 pump 一次首页壳（真实 routerProvider + Fake 仓储），
/// 断言导航形态与双栏分栏状态——
/// - compact(<600)：底部 NavigationBar；
/// - medium(600–839) / expanded(840–1079)：NavigationRail、无双栏；
/// - twoPane(≥1080)：Rail + 列表面板 + 详情空态面板并存。
///
/// 壳结构以组件类型与既有文案断言（AdaptiveScaffold 无 Key 也可稳定
/// 定位），无需为测试改动 lib 代码。
void main() {
  /// 在 [size] 视口下 pump 真实 app 壳（Fake 仓储注入）。
  Future<void> pumpShell(WidgetTester tester, Size size) async {
    SharedPreferences.setMockInitialValues(const {});
    final pokedex = FakePokedexRepository();
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
    // 首载骨架 → 数据就绪；再留一拍让偏好恢复等异步落地。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('390×844（compact）：NavigationBar，无 NavigationRail', (tester) async {
    await pumpShell(tester, const Size(390, 844));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    // 双栏空态与列表面板标题均不应出现（图鉴分支单栏走 AppBar 布局）。
    expect(find.text('从左侧选择宝可梦'), findsNothing);
    expect(find.byType(PokedexHomeListContent), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('720×1280（medium）：NavigationRail，无双栏', (tester) async {
    await pumpShell(tester, const Size(720, 1280));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('从左侧选择宝可梦'), findsNothing);
    // medium 走 AppBar 内嵌搜索布局（非 expanded 的整页列表内容）。
    expect(find.byType(PokedexHomeListContent), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1024×768（expanded）：NavigationRail，无双栏', (tester) async {
    await pumpShell(tester, const Size(1024, 768));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // expanded（840–1079）仍不足双栏阈值 1080：整页列表内容渲染，
    // 但无详情空态面板。
    expect(find.byType(PokedexHomeListContent), findsOneWidget);
    expect(find.text('从左侧选择宝可梦'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1440×900（twoPane）：Rail + 列表面板 + 详情空态并存', (tester) async {
    await pumpShell(tester, const Size(1440, 900));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // 双栏：列表面板（图鉴分支内嵌布局）与详情空态引导同时渲染。
    expect(find.byType(PokedexHomeListContent), findsOneWidget);
    expect(find.text('从左侧选择宝可梦'), findsOneWidget);
    expect(find.text('查看详情'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
