import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// 设置页占位：主题切换为静态 SegmentedButton 预览
/// （后续由 G 单元接 themeModeProvider 实装）。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.l),
        children: [
          Text('外观', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.s),
          // 静态预览：选中态固定"跟随系统"；G 单元接入 themeModeProvider 后替换。
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: const {ThemeMode.system},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: AppSpacing.xl),
          const Center(child: Text('建设中')),
        ],
      ),
    );
  }
}
