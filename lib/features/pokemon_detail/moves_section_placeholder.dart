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

/// compact tile 右端簇定宽列：徽章宽度随属性名变化（单字「火」vs 双字
/// 「飞行」）会让各行徽章左缘参差，故整簇定宽、右锚定，徽章左缘 /
/// 分类左缘 / 行尾标签右缘在所有行各成一条直线。定宽依据（同 _kCol*
/// 的文件内布局常量）：
/// - 徽章槽 50：sm 徽章最宽属性「超能力」3 字 ×11 + pill 左右 padding
///   AppSpacing.s×2 = 49；徽章撑满定宽槽，与 expanded 表格 cell 同几何；
/// - 分类列 28：bodySmall(12px) 恒为双字「物理/特殊/变化」= 24，+4 余量；
/// - 行尾列 40：labelSmall(12px) 最宽 3 字来源词「学习器」= 36，+4 余量。
const double _kCompactColType = 50;
const double _kCompactColClass = 28;
const double _kCompactColTail = 40;

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
                      // key 挂在 Builder 上：闭包里的 context 即 chip 的
                      // 定位锚点，测试也按这个 key 找单个 chip。
                      Builder(
                        key: ValueKey('moves_vg_chip_${group.id}'),
                        builder: (chipContext) => VersionChip(
                          label: group.labelZh,
                          selected:
                              group.id == _effectiveGroupId(filter, groups),
                          onTap: () {
                            // 先把 chip 完整滚入视野再写筛选状态：视口
                            // 边缘被裁的 chip 选中后不能停在半裁位置，
                            // 否则「选中了哪个」不可读。
                            _revealChip(chipContext);
                            filterNotifier.setVersionGroup(group.id);
                          },
                        ),
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
                    final groups = _groupByMethod(moves, filter);
                    // ≥2 个来源且等级排序：分组折叠视图（列头共享一份）。
                    if (groups != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isTable) const _TableHeader(),
                          _MoveGroupList(
                            // 折叠状态只在同一「形态 + 版本组 + 来源 + 排序」
                            // 组合内有效：key 一变 State 重建，回到默认展开
                            // 规则，旧组合的显式折叠不会残留。
                            key: ValueKey(
                              'move_groups|$formId|${filter.versionGroup}'
                              '|${filter.sort.name}'
                              '|${_methodsKey(filter.methods)}',
                            ),
                            groups: groups,
                            isTable: isTable,
                            expandAll: filter.methods.isNotEmpty,
                          ),
                        ],
                      );
                    }
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

  /// 把刚点按的版本 chip 完整滚入横向视口（先于筛选状态写入）。
  ///
  /// ensureVisible 沿祖先 scrollable 链逐级保证可见：chip 在页面纵向
  /// 滚动里本就可见（用户刚点中它），不会牵动页面纵向滚动。系统
  /// 「关闭动画」（MediaQuery.disableAnimationsOf）时 duration 取零
  /// 直接到位，与详情页分区跳转同一偏好。
  void _revealChip(BuildContext chipContext) {
    Scrollable.ensureVisible(
      chipContext,
      duration: MediaQuery.disableAnimationsOf(chipContext)
          ? Duration.zero
          : AppMotion.fast,
      curve: AppMotion.curve,
    );
  }
}

/// 一个来源分组：method + 该来源的招式（保持查询结果的排序）。
class _MoveGroup {
  const _MoveGroup({required this.method, required this.moves});

  final String method;

  final List<MoveEntry> moves;
}

/// 来源集合 → 稳定的 ValueKey 片段（Set 的迭代序不保证稳定，先排序）。
String _methodsKey(Set<String> methods) {
  if (methods.isEmpty) return '';
  return (methods.toList()..sort()).join(',');
}

/// 是否按来源分组：仅等级排序下分组——威力 / 名称是跨来源排序，
/// 分组会把同一排序轴上的行切碎，语义不成立；
/// 结果只含 1 个来源时分组表头没有信息量，保持平铺。
List<_MoveGroup>? _groupByMethod(List<MoveEntry> moves, LearnsetFilter filter) {
  if (filter.sort != MoveSort.level) return null;
  final byMethod = <String, List<MoveEntry>>{};
  for (final move in moves) {
    byMethod.putIfAbsent(move.method, () => <MoveEntry>[]).add(move);
  }
  if (byMethod.length < 2) return null;
  // 组序沿用 methodGroupOrder（升级 → 学习器 → 遗传 → 导师 → 其他），
  // 与 level 排序的组序一致，展开任一组都不会与相邻组错位。
  final methods = byMethod.keys.toList()
    ..sort((a, b) {
      final byOrder = methodGroupOrder(a).compareTo(methodGroupOrder(b));
      return byOrder != 0 ? byOrder : a.compareTo(b);
    });
  return [
    for (final method in methods)
      _MoveGroup(method: method, moves: byMethod[method]!),
  ];
}

/// 分组折叠列表：默认展开规则由 [expandAll] 决定，之后用户点击优先。
///
/// 折叠组不构建行（条件渲染）：不占高度、不进 widget 树，
/// 默认视图因此只渲染首组规模的行。
class _MoveGroupList extends StatefulWidget {
  const _MoveGroupList({
    super.key,
    required this.groups,
    required this.isTable,
    required this.expandAll,
  });

  final List<_MoveGroup> groups;

  /// true = 完整表格行，false = compact 两行 tile（与平铺视图同一套行）。
  final bool isTable;

  /// true = 全部分组默认展开（有来源筛选时，用户已缩小到明确来源）；
  /// false = 只展开第一个分组（默认视图求短）。
  final bool expandAll;

  @override
  State<_MoveGroupList> createState() => _MoveGroupListState();
}

class _MoveGroupListState extends State<_MoveGroupList> {
  /// 已展开的来源集合：按默认规则初始化，之后由用户点击改写。
  final Set<String> _expandedMethods = <String>{};

  @override
  void initState() {
    super.initState();
    _expandedMethods.addAll([
      for (final (index, group) in widget.groups.indexed)
        if (widget.expandAll || index == 0) group.method,
    ]);
  }

  void _toggle(String method) => setState(() {
        if (!_expandedMethods.remove(method)) {
          _expandedMethods.add(method);
        }
      });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, group) in widget.groups.indexed) ...[
          _MoveGroupHeader(
            method: group.method,
            count: group.moves.length,
            expanded: _expandedMethods.contains(group.method),
            onTap: () => _toggle(group.method),
          ),
          if (_expandedMethods.contains(group.method))
            for (final (rowIndex, move) in group.moves.indexed) ...[
              if (widget.isTable)
                _TableRow(move: move)
              else
                _CompactTile(move: move),
              if (rowIndex != group.moves.length - 1) const Divider(height: 1),
            ],
          if (index != widget.groups.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

/// 分组表头：左「{来源}招式 · N 个」，右侧 chevron（整行可点，旋转表折叠态）。
class _MoveGroupHeader extends StatelessWidget {
  const _MoveGroupHeader({
    required this.method,
    required this.count,
    required this.expanded,
    required this.onTap,
  });

  final String method;

  final int count;

  final bool expanded;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      // 测试定位锚点：来源 identifier（DB snake_case，同 _kMethodZh 的键）。
      key: ValueKey('move_group_header_$method'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
        child: Row(
          children: [
            Text(
              '${_kMethodZh[method] ?? method}招式',
              style: textTheme.labelMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '· $count 个',
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              child: Icon(
                Icons.expand_more,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
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
                // 以下三列定宽（_kCompactCol*）：Expanded 名称吃掉行宽
                // 差异后，右端簇起点只由总定宽决定，各行几何一致。
                SizedBox(
                  width: _kCompactColType,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TypeBadge(type: move.typeId, size: TypeBadgeSize.sm),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  width: _kCompactColClass,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _damageClassLabel(move),
                      maxLines: 1,
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  width: _kCompactColTail,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _levelLabel(move),
                      maxLines: 1,
                      style: _tabular(textTheme, textTheme.labelSmall),
                    ),
                  ),
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
