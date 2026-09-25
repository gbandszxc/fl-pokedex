import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/providers.dart';
import 'router.dart';
import 'theme/theme.dart';

/// 应用根组件：MaterialApp.router + 主题接入。
///
/// themeMode 由 settings feature 的 [themeModeProvider] 提供
/// （SP key `theme_mode` 持久化，跟随系统为默认）；locale 设为 zh，
/// Material 组件文案保持引擎默认。
class AmberDexApp extends ConsumerWidget {
  const AmberDexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Fl-PokeDex',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: const Locale('zh'),
      routerConfig: router,
    );
  }
}
