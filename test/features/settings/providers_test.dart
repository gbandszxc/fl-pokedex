import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/features/settings/providers.dart';

void main() {
  Future<void> flush(WidgetTester tester) async {
    // 恢复读取是异步的：泵一拍让微任务队列落地。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
  }

  testWidgets('themeMode：从 SP 恢复，切换写回（roundtrip）', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final container = ProviderContainer();

    expect(container.read(themeModeProvider), ThemeMode.system);
    await flush(tester);
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // 切换 → 状态与 SP 同步。
    container.read(themeModeProvider.notifier).set(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    await flush(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'light');

    // roundtrip：新容器从 SP 恢复出刚才写回的值。
    container.dispose();
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(container2.read(themeModeProvider), ThemeMode.system);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(container2.read(themeModeProvider), ThemeMode.light);
  });

  testWidgets('themeMode：非法/缺失值回退跟随系统', (tester) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'sepia'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await flush(tester);
    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('seedColor：切换写回 SP（roundtrip）并可恢复', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();

    expect(container.read(seedColorProvider), AppSeedColor.amber);
    await flush(tester);

    // 切换 → 状态与 SP 同步。
    container.read(seedColorProvider.notifier).set(AppSeedColor.rose);
    expect(container.read(seedColorProvider), AppSeedColor.rose);
    await flush(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('seed_color'), 'rose');

    // roundtrip：新容器从 SP 恢复出刚才写回的值。
    container.dispose();
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(container2.read(seedColorProvider), AppSeedColor.amber);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(container2.read(seedColorProvider), AppSeedColor.rose);
  });

  testWidgets('seedColor：非法/缺失值回退琥珀', (tester) async {
    SharedPreferences.setMockInitialValues({'seed_color': 'crimson'});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await flush(tester);
    expect(container.read(seedColorProvider), AppSeedColor.amber);
  });

  testWidgets('cardDensity：从 SP 恢复，切换写回（roundtrip）', (tester) async {
    SharedPreferences.setMockInitialValues({'card_density': 'compact'});
    final container = ProviderContainer();

    expect(container.read(cardDensityProvider), CardDensity.comfortable);
    await flush(tester);
    expect(container.read(cardDensityProvider), CardDensity.compact);

    container.read(cardDensityProvider.notifier).set(CardDensity.comfortable);
    await flush(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('card_density'), 'comfortable');

    container.dispose();
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    expect(container2.read(cardDensityProvider), CardDensity.comfortable);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(container2.read(cardDensityProvider), CardDensity.comfortable);
  });

  testWidgets('homeViewLayout：切换写回 SP view_mode 并可恢复', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    final container = ProviderContainer();

    await flush(tester);
    expect(container.read(homeViewLayoutProvider), HomeViewLayout.grid);

    container.read(homeViewLayoutProvider.notifier).set(HomeViewLayout.list);
    expect(container.read(homeViewLayoutProvider), HomeViewLayout.list);
    await flush(tester);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('view_mode'), 'list');

    container.dispose();
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    // 先触发一次读取（启动 build + 异步恢复），再泵帧等待恢复落地。
    expect(container2.read(homeViewLayoutProvider), HomeViewLayout.grid);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));
    expect(container2.read(homeViewLayoutProvider), HomeViewLayout.list);
  });
}
