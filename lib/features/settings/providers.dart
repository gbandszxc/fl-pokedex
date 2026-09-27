import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/theme/app_colors.dart';

/// 桌面宽屏下首页网格卡片密度（design-ui.md §8）。
enum CardDensity { comfortable, compact }

/// SharedPreferences key：主题模式（system / light / dark）。
const String kThemeModePrefsKey = 'theme_mode';

/// SharedPreferences key：主题种子色（amber / rose / forest / blue / teal / violet）。
const String kSeedColorPrefsKey = 'seed_color';

/// SharedPreferences key：首页视图模式（grid / list，与首页共享）。
const String kViewModePrefsKey = 'view_mode';

/// SharedPreferences key：卡片密度（comfortable / compact）。
const String kCardDensityPrefsKey = 'card_density';

/// 应用主题模式（design-ui.md §8 外观三选）。
///
/// 启动异步恢复一次（key `theme_mode`），之后以内存态为准，切换即写回；
/// 用户已显式选择后忽略尚未完成的恢复读取。持久化读取失败时保持
/// 默认值（跟随系统），不影响应用其余功能。
class ThemeModeNotifier extends Notifier<ThemeMode> {
  /// 用户已显式切换时忽略尚未完成的恢复读取，避免回跳。
  bool _settled = false;

  /// Provider 生命周期结束后不再回写 state（riverpod 2 无 ref.mounted）。
  bool _disposed = false;

  @override
  ThemeMode build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _settled) {
        return;
      }
      _settled = true;
      state = switch (prefs.getString(kThemeModePrefsKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } on Object catch (error, stackTrace) {
      // 偏好读取失败不致命：保持「跟随系统」默认即可。
      debugPrint('theme_mode restore failed: $error\n$stackTrace');
    }
  }

  void set(ThemeMode mode) {
    _settled = true;
    if (state == mode) {
      return;
    }
    state = mode;
    unawaited(_persist(mode));
  }

  Future<void> _persist(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kThemeModePrefsKey, mode.name);
    } on Object catch (error, stackTrace) {
      debugPrint('theme_mode persist failed: $error\n$stackTrace');
    }
  }
}

/// 主题模式 Provider：app.dart 接入 MaterialApp.router 的 themeMode。
final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// 主题种子色 Provider（design-ui.md §8 主题色六选一，默认琥珀）。
///
/// 启动异步恢复一次（key `seed_color`），之后以内存态为准，切换即写回；
/// 用户已显式选择后忽略尚未完成的恢复读取。非法值、缺失与读取失败均
/// 保持默认琥珀，不影响应用其余功能。结构逐行同构 [ThemeModeNotifier]。
class SeedColorNotifier extends Notifier<AppSeedColor> {
  /// 用户已显式切换时忽略尚未完成的恢复读取，避免回跳。
  bool _settled = false;

  /// Provider 生命周期结束后不再回写 state（riverpod 2 无 ref.mounted）。
  bool _disposed = false;

  @override
  AppSeedColor build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return AppSeedColor.amber;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _settled) {
        return;
      }
      _settled = true;
      final stored = prefs.getString(kSeedColorPrefsKey);
      state = stored == null
          ? AppSeedColor.amber
          : AppSeedColor.values.byName(stored);
    } on Object catch (error, stackTrace) {
      // 偏好读取失败/值非法不致命：保持默认琥珀即可。
      debugPrint('seed_color restore failed: $error\n$stackTrace');
    }
  }

  void set(AppSeedColor seed) {
    _settled = true;
    if (state == seed) {
      return;
    }
    state = seed;
    unawaited(_persist(seed));
  }

  Future<void> _persist(AppSeedColor seed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kSeedColorPrefsKey, seed.name);
    } on Object catch (error, stackTrace) {
      debugPrint('seed_color persist failed: $error\n$stackTrace');
    }
  }
}

/// 主题种子色 Provider：app.dart 接入 buildLightTheme/buildDarkTheme 的 seed。
final seedColorProvider =
    NotifierProvider<SeedColorNotifier, AppSeedColor>(SeedColorNotifier.new);

/// 首页网格卡片密度：舒适（maxCrossAxisExtent 200）/
/// 紧凑（maxCrossAxisExtent 180）。仅桌面宽屏生效。
class CardDensityNotifier extends Notifier<CardDensity> {
  bool _settled = false;

  bool _disposed = false;

  @override
  CardDensity build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return CardDensity.comfortable;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _settled) {
        return;
      }
      _settled = true;
      state = prefs.getString(kCardDensityPrefsKey) == CardDensity.compact.name
          ? CardDensity.compact
          : CardDensity.comfortable;
    } on Object catch (error, stackTrace) {
      debugPrint('card_density restore failed: $error\n$stackTrace');
    }
  }

  void set(CardDensity density) {
    _settled = true;
    if (state == density) {
      return;
    }
    state = density;
    unawaited(_persist(density));
  }

  Future<void> _persist(CardDensity density) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kCardDensityPrefsKey, density.name);
    } on Object catch (error, stackTrace) {
      debugPrint('card_density persist failed: $error\n$stackTrace');
    }
  }
}

/// 卡片密度 Provider（消费方由首页网格集成单元接入）。
final cardDensityProvider =
    NotifierProvider<CardDensityNotifier, CardDensity>(CardDensityNotifier.new);

/// 首页布局（design-ui.md §8：网格 / 列表）。
///
/// 与首页（pokedex feature 的 listViewModeProvider）共享 SP key
/// `view_mode`，但 features 之间禁止互相 import，故在设置侧自建；
/// 设置页只负责写 SP，首页内存态在下次启动恢复时生效。
enum HomeViewLayout { grid, list }

/// 首页布局 Provider：启动异步恢复（key `view_mode`），切换即写回 SP。
class HomeViewLayoutNotifier extends Notifier<HomeViewLayout> {
  bool _settled = false;

  bool _disposed = false;

  @override
  HomeViewLayout build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return HomeViewLayout.grid;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _settled) {
        return;
      }
      _settled = true;
      state = prefs.getString(kViewModePrefsKey) == HomeViewLayout.list.name
          ? HomeViewLayout.list
          : HomeViewLayout.grid;
    } on Object catch (error, stackTrace) {
      debugPrint('view_mode restore failed: $error\n$stackTrace');
    }
  }

  void set(HomeViewLayout layout) {
    _settled = true;
    if (state == layout) {
      return;
    }
    state = layout;
    unawaited(_persist(layout));
  }

  Future<void> _persist(HomeViewLayout layout) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kViewModePrefsKey, layout.name);
    } on Object catch (error, stackTrace) {
      debugPrint('view_mode persist failed: $error\n$stackTrace');
    }
  }
}

/// 首页布局 Provider（设置页 SegmentedButton 绑定）。
final homeViewLayoutProvider =
    NotifierProvider<HomeViewLayoutNotifier, HomeViewLayout>(
  HomeViewLayoutNotifier.new,
);
