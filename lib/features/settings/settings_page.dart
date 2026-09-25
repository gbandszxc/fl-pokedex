import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/tokens.dart';
import '../../core/di.dart';
import '../../domain/models/manifest.dart';
import '../../shared/widgets/widgets.dart';
import 'providers.dart';

/// 应用版本号（与 pubspec.yaml 的 version 保持一致，手动同步）。
const String kAppVersion = '1.0.0';

/// 数据清单（关于区块：数据版本 / 构建日期 / 规模）。
final manifestProvider = FutureProvider<DataManifest>((ref) async {
  return ref.watch(pokedexRepositoryProvider).getManifest();
});

/// 设置页（design-ui.md §8）：外观 / 首页布局 / 桌面卡片密度 / 关于。
///
/// 纯个人偏好，无任何账号与网络项（PRODUCT.md 硬性契约）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pad = pagePaddingFor(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Center(
        child: ConstrainedBox(
          // 宽屏下设置内容限宽居中（DESIGN.md §4 阅读宽度习惯）。
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, pad, AppSpacing.xl),
            children: [
              const SectionTitle(title: '外观'),
              const SizedBox(height: AppSpacing.s),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('跟随系统'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ],
                selected: {ref.watch(themeModeProvider)},
                onSelectionChanged: (selection) => ref
                    .read(themeModeProvider.notifier)
                    .set(selection.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle(title: '首页布局'),
              const SizedBox(height: AppSpacing.s),
              SegmentedButton<HomeViewLayout>(
                segments: const [
                  ButtonSegment(
                    value: HomeViewLayout.grid,
                    label: Text('网格'),
                  ),
                  ButtonSegment(
                    value: HomeViewLayout.list,
                    label: Text('列表'),
                  ),
                ],
                selected: {ref.watch(homeViewLayoutProvider)},
                onSelectionChanged: (selection) => ref
                    .read(homeViewLayoutProvider.notifier)
                    .set(selection.first),
                showSelectedIcon: false,
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionTitle(title: '桌面卡片密度'),
              const SizedBox(height: AppSpacing.s),
              SegmentedButton<CardDensity>(
                segments: const [
                  ButtonSegment(
                    value: CardDensity.comfortable,
                    label: Text('舒适'),
                  ),
                  ButtonSegment(
                    value: CardDensity.compact,
                    label: Text('紧凑'),
                  ),
                ],
                selected: {ref.watch(cardDensityProvider)},
                onSelectionChanged: (selection) => ref
                    .read(cardDensityProvider.notifier)
                    .set(selection.first),
                showSelectedIcon: false,
              ),
              const _Caption('仅桌面宽屏生效'),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.m),
              const SectionTitle(title: '关于'),
              const SizedBox(height: AppSpacing.s),
              _AboutRow(label: '版本', value: kAppVersion),
              ref
                  .watch(manifestProvider)
                  .when(
                    data: (manifest) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AboutRow(label: '数据', value: manifest.dataVersion),
                        _AboutRow(
                          label: '数据库构建',
                          value: _buildDateLabel(manifest.buildDate),
                        ),
                        _AboutRow(
                          label: '数据规模',
                          value:
                              '宝可梦 ${manifest.pokemonCount} 只 · '
                              '招式 ${manifest.moveCount} 个',
                        ),
                      ],
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.s),
                      child: SkeletonBox(height: 16, width: 220),
                    ),
                    error: (_, __) =>
                        const _AboutRow(label: '数据', value: '信息不可用'),
                  ),
              const _AboutRow(label: '数据来源', value: 'PokéAPI'),
              const Padding(
                padding: EdgeInsets.only(top: AppSpacing.s),
                child: _Caption(
                  '图鉴数据与官方立绘来自 PokéAPI（BSD-3-Clause）；'
                  '宝可梦名称与形象版权归 © Nintendo / Creatures Inc. / '
                  'GAME FREAK inc. 所有，仅为非商业粉丝用途随应用本地分发。'
                  '本应用代码与界面为原创，以 MIT 许可发布。',
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开源许可'),
                titleTextStyle: Theme.of(context).textTheme.bodyMedium,
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Fl-PokeDex',
                  applicationVersion: kAppVersion,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ISO 8601 构建时间 → 日期（`2026-09-25`）。
String _buildDateLabel(String buildDate) =>
    buildDate.length >= 10 ? buildDate.substring(0, 10) : buildDate;

/// 分组下的说明文字（caption，次级文字色）。
class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodySmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

/// 关于区块的「标签 + 值」行。
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
