import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/app.dart';
import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/features/settings/providers.dart';
import 'package:fl_pokedex/shared/widgets/pokemon_card.dart';

import '../features/pokedex/fakes.dart';

/// 深浅主题巡检（DESIGN.md §1）：
///
/// 默认浅色启动首页 → 读 Scaffold 底色与卡片 surfaceContainer 色 →
/// 经设置页 UI 切「深色」→ 返回图鉴 → 断言两套语义色随主题切换
/// （浅 ≠ 深，且深色底取 DESIGN.md Dark 表 #060606 / #1A1814 语义），
/// 并以 WCAG 对比度验证深色下文字可读性由主题保证。
void main() {
  /// 计算前景/背景色的 WCAG 对比度（≥4.5 视为正文可读）。
  double contrastRatio(Color a, Color b) {
    double luminance(Color c) {
      double channel(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    final la = luminance(a);
    final lb = luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  testWidgets('浅色 → 设置页切深色 → 返回图鉴：背景与卡片色随主题',
      (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final pokedex = FakePokedexRepository();
    final favorites = FakeFavoritesRepository();
    final container = ProviderContainer(
      overrides: fakeRepositoryOverrides(pokedex: pokedex, favorites: favorites),
    );
    addTearDown(container.dispose);
    addTearDown(favorites.dispose);

    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AmberDexApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 50));

    Color cardColor() => tester
        .widget<Material>(
          find.descendant(
            of: find.byType(PokemonCard),
            matching: find.byType(Material),
          ).first,
        )
        .color!;

    // ---- 浅色断言（DESIGN.md §1 Light 表）----
    final lightContext = tester.element(find.byType(Scaffold).first);
    final lightTheme = Theme.of(lightContext);
    expect(container.read(themeModeProvider), ThemeMode.system);
    expect(lightTheme.brightness, Brightness.light);
    expect(lightTheme.scaffoldBackgroundColor, AppColors.light.bg);
    expect(lightTheme.colorScheme.surfaceContainer,
        AppColors.light.surfaceContainer);
    expect(cardColor(), AppColors.light.surfaceContainer);

    // ---- 经设置页 UI 切深色 ----
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('设置'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('外观'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // ---- 返回图鉴 ----
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('图鉴'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ---- 深色断言（DESIGN.md §1 Dark 表：bg #060606 / 卡 #1A1814）----
    final darkContext = tester.element(find.byType(Scaffold).first);
    final darkTheme = Theme.of(darkContext);
    expect(darkTheme.brightness, Brightness.dark);
    expect(darkTheme.scaffoldBackgroundColor, AppColors.dark.bg);
    expect(darkTheme.colorScheme.surfaceContainer,
        AppColors.dark.surfaceContainer);
    expect(cardColor(), AppColors.dark.surfaceContainer);

    // 浅 ≠ 深：背景与卡片两档容器色都随主题翻转。
    expect(
      darkTheme.scaffoldBackgroundColor,
      isNot(lightTheme.scaffoldBackgroundColor),
    );
    expect(
      darkTheme.colorScheme.surfaceContainer,
      isNot(lightTheme.colorScheme.surfaceContainer),
    );

    // 深色可读性由主题保证：正文色对底色的 WCAG 对比度 ≥ 4.5。
    expect(
      contrastRatio(AppColors.dark.onSurface, AppColors.dark.bg),
      greaterThanOrEqualTo(4.5),
    );
    expect(tester.takeException(), isNull);
  });
}
