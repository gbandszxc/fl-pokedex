import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/theme.dart';

/// 应用根组件：MaterialApp.router + 主题接入。
///
/// themeMode 初始跟随系统（G 单元接入 themeModeProvider 后持久化）；
/// locale 设为 zh，Material 组件文案保持引擎默认。
class AmberDexApp extends ConsumerWidget {
  const AmberDexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '琥珀图鉴',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      locale: const Locale('zh'),
      routerConfig: router,
    );
  }
}
