import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../domain/models/move_entry.dart';
import '../../domain/models/refs.dart';
import '../../shared/widgets/widgets.dart';
import 'detail_data.dart';
import 'learnset_filter.dart';
import 'providers.dart';

/// 完整表格布局的区块宽阈值（design-ui.md §6：expanded 完整表格）。
const double _kMoveTableBreakpoint = 840;

/// damage_class → 简中（DB snake_case 原样传入）。
const Map<String, String> _kDamageClassZh = {
  'physical': '物理',
  'special': '特殊',
  'status': '变化',
};

/// 来源 method → 短词（chips 与行尾标签共用）。
const Map<String, String> _kMethodZh = {
  'level_up': '升级',
  'machine': '学习器',
  'egg': '遗传',
  'tutor': '导师',
  'other': '其他',
};

/// 表格列宽（等宽数字列右对齐）。
const double _kColType = 56;
const double _kColClass = 48;
const double _kColPower = 52;
const double _kColAcc = 52;
const double _kColPp = 40;
const double _kColLevel = 68;

/// 招式分区（design-ui.md §6）：版本组切换 + 来源筛选 + 排序 + 列表；
/// expanded 为完整表格行，compact 为两行 tile；点击行进入招式详情。
class MovesSectionPlaceholder extends ConsumerWidget {
  const MovesSectionPlaceholder({
    super.key,
    required this.speciesId,
  });

  /// 当前宝可梦 speciesId：由页面显式传入（与 _FlavorSection 一致）。
  /// 双栏（宽 ≥1080）下本页内嵌在图鉴分支 `/` 上，路由没有
  /// :speciesId 路径参数，不能从 GoRouterState 反推。
  final int speciesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '招式'),
        const SizedBox(height: AppSpacing.m),
        _MovesSectionBody(speciesId: speciesId),
      ],
    );
  }
}

class _MovesSectionBody extends ConsumerWidget {
  const _MovesSectionBody({required this.speciesId});

  final int speciesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(pokemonDetailProvider(speciesId));
    return detailAsync.when(
      loading: () => const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 26, width: 180),
            SizedBox(height: AppSpacing.m),
            SkeletonBox(height: 26, width: 240),
            SizedBox(height: AppSpacing.m),
            SkeletonBox(height: 44),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 44),
          ],
        ),
      ),
      error: (error, stackTrace) => _MovesLoadError(
        onRetry: () => ref.invalidate(pokemonDetailProvider(speciesId)),
      ),
      data: (detail) {
        final selectedFormId = ref.watch(selectedFormIdProvider(speciesId));
        final form = resolveSelectedForm(detail.forms, selectedFormId);
        return _MovesContent(formId: form.formId);
      },
    );
  }
}

/// 分区级加载失败：轻量文案 + 重试。
class _MovesLoadError extends StatelessWidget {
  const _MovesLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '加载失败',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.s),
        TextButton(onPressed: onRetry, child: const Text('重试')),
      ],
    );
  }
}

class _MovesContent extends ConsumerWidget {
  const _MovesContent({required this.formId});

  final int formId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(learnsetFilterProvider(formId));
    final filterNotifier = ref.read(learnsetFilterProvider(formId).notifier);
    final groupsAsync = ref.watch(learnsetVersionGroupsProvider(formId));
    final movesAsync = ref.watch(learnsetProvider((formId, filter)));
    // valueOrNull：error 态下 value 会抛异常，此处回退为空列表。
    final groups = groupsAsync.valueOrNull ?? const <VersionGroupRef>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final (index, group) in groups.indexed) ...[
                      VersionChip(
                        label: group.labelZh,
                        selected: group.id == _effectiveGroupId(filter, groups),
                        onTap: () =>
                            filterNotifier.setVersionGroup(group.id),
                      ),
                      if (index != groups.length - 1)
                        const SizedBox(width: AppSpacing.s),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            _SortMenu(
              sort: filter.sort,
              onSelected: filterNotifier.setSort,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              VersionChip(
                label: '全部',
                selected: filter.methods.isEmpty,
                onTap: () => filterNotifier.setMethods(const <String>{}),
              ),
              for (final entry in _kMethodZh.entries) ...[
                const SizedBox(width: AppSpacing.s),
                VersionChip(
                  label: entry.value,
                  selected: filter.methods.contains(entry.key),
                  onTap: () {
                    final next = <String>{...filter.methods};
                    if (!next.remove(entry.key)) {
                      next.add(entry.key);
                    }
                    filterNotifier.setMethods(next);
                  },
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        movesAsync.when(
          loading: () => const Skeleton(
            child: Column(
              children: [
                SkeletonBox(height: 44),
                SizedBox(height: AppSpacing.s),
                SkeletonBox(height: 44),
                SizedBox(height: AppSpacing.s),
                SkeletonBox(height: 44),
                SizedBox(height: AppSpacing.s),
                SkeletonBox(height: 44),
              ],
            ),
          ),
          error: (error, stackTrace) => _MovesLoadError(
            onRetry: () =>
                ref.invalidate(learnsetProvider((formId, filter))),
          ),
          data: (moves) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '共 ${moves.length} 个招式',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              if (moves.isEmpty)
                const EmptyState(
                  title: '没有匹配的招式',
                  message: '试试清除来源筛选或切换版本组。',
                  icon: Icons.format_list_bulleted_outlined,
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTable =
                        constraints.maxWidth >= _kMoveTableBreakpoint;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isTable) const _TableHeader(),
                        for (final (index, move) in moves.indexed) ...[
                          if (isTable)
                            _TableRow(move: move)
                          else
                            _CompactTile(move: move),
                          if (index != moves.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    );
                  },
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 当前生效的版本组：显式选中优先，否则默认（最新）组。
  String _effectiveGroupId(
    LearnsetFilter filter,
    List<VersionGroupRef> groups,
  ) {
    if (filter.versionGroup.isNotEmpty) return filter.versionGroup;
    return groups.isEmpty ? '' : groups.first.id;
  }
}

/// 排序菜单（等级 / 威力 / 名称）。
class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.sort, required this.onSelected});

  final MoveSort sort;
  final ValueChanged<MoveSort> onSelected;

  static const Map<MoveSort, String> _labels = {
    MoveSort.level: '等级',
    MoveSort.power: '威力',
    MoveSort.name: '名称',
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<MoveSort>(
      initialValue: sort,
      tooltip: '排序方式',
      onSelected: onSelected,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      itemBuilder: (context) => [
        for (final value in MoveSort.values)
          PopupMenuItem(
            value: value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  child: value == sort
                      ? Icon(Icons.check, size: 16, color: scheme.primary)
                      : null,
                ),
                const SizedBox(width: AppSpacing.s),
                Text(_labels[value]!),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '排序',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// 行尾标签：有等级显示 Lv.NN，否则显示来源短词。
String _levelLabel(MoveEntry move) {
  final level = move.level;
  if (level != null) {
    return 'Lv.${level.toString().padLeft(2, '0')}';
  }
  return _kMethodZh[move.method] ?? move.method;
}

String _numOrDash(int? value) => value?.toString() ?? '—';

String _damageClassLabel(MoveEntry move) =>
    _kDamageClassZh[move.damageClass] ?? move.damageClass;

TextStyle _tabular(TextTheme textTheme, TextStyle? style) =>
    AppTypography.tabularFigures(style ?? const TextStyle());

/// expanded 表格头（caption 列头，与行同列宽）。
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    Widget cell(String label, double width, {bool right = false}) => SizedBox(
          width: width,
          child: Text(
            label,
            textAlign: right ? TextAlign.right : TextAlign.left,
            style: style,
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const Expanded(child: SizedBox()),
          cell('属性', _kColType),
          cell('分类', _kColClass),
          cell('威力', _kColPower, right: true),
          cell('命中', _kColAcc, right: true),
          cell('PP', _kColPp, right: true),
          cell('等级', _kColLevel, right: true),
        ],
      ),
    );
  }
}

/// expanded 表格行：名称 | 属性徽章 | 分类 | 威力 | 命中 | PP | 等级。
class _TableRow extends StatelessWidget {
  const _TableRow({required this.move});

  final MoveEntry move;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    Widget cell(Widget child, double width, {bool right = false}) => SizedBox(
          width: width,
          child: Align(
            alignment: right ? Alignment.centerRight : Alignment.centerLeft,
            child: child,
          ),
        );

    return InkWell(
      onTap: () => context.push('/move/${move.moveId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            Expanded(
              child: Text(
                move.nameZh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium,
              ),
            ),
            cell(TypeBadge(type: move.typeId, size: TypeBadgeSize.sm),
                _kColType),
            cell(
              Text(_damageClassLabel(move), style: textTheme.bodySmall),
              _kColClass,
            ),
            cell(
              Text(_numOrDash(move.power),
                  style: _tabular(textTheme, textTheme.bodyMedium)),
              _kColPower,
              right: true,
            ),
            cell(
              Text(_numOrDash(move.accuracy),
                  style: _tabular(textTheme, textTheme.bodyMedium)),
              _kColAcc,
              right: true,
            ),
            cell(
              Text(_numOrDash(move.pp),
                  style: _tabular(textTheme, textTheme.bodyMedium)),
              _kColPp,
              right: true,
            ),
            cell(
              Text(_levelLabel(move),
                  style: _tabular(textTheme, textTheme.labelMedium)),
              _kColLevel,
              right: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// compact 两行 tile：上行名 + 徽章 + 分类 + 行尾标签，下行数据 caption。
class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.move});

  final MoveEntry move;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/move/${move.moveId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    move.nameZh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                TypeBadge(type: move.typeId, size: TypeBadgeSize.sm),
                const SizedBox(width: AppSpacing.s),
                Text(_damageClassLabel(move), style: textTheme.bodySmall),
                const SizedBox(width: AppSpacing.s),
                Text(
                  _levelLabel(move),
                  style: _tabular(textTheme, textTheme.labelSmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '威力 ${_numOrDash(move.power)}'
              ' · 命中 ${_numOrDash(move.accuracy)}'
              ' · PP ${_numOrDash(move.pp)}',
              style: _tabular(textTheme, textTheme.bodySmall)
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
