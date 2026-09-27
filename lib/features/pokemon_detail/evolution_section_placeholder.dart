import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/di.dart';
import '../../domain/models/evolution.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import 'evolution_layout.dart';

/// 进化树数据（speciesId → 整条进化链；无链返回 null）。
final evolutionTreeProvider =
    FutureProvider.autoDispose.family<EvolutionTree?, int>((
  ref,
  speciesId,
) {
  return ref.watch(pokedexRepositoryProvider).getEvolutionTree(speciesId);
});

/// expanded 横向树布局常量（design-ui.md §5：节点宽 120、列距 80，
/// 容器高按叶数 320~420）。
const double _kNodeWidth = 120;
const double _kColumnGap = 80;
const double _kRowHeight = 136;

/// 节点卡高：缩略图 48 + 间距 4 + 名 18 + 编号 16 + 上下边距 16。
const double _kCardHeight = 102;

/// compact 缩进导引列宽。
const double _kGuideWidth = 28;

/// 进化分区（design-ui.md §5）：compact(<840) 纵向树 / expanded(≥840)
/// InteractiveViewer 横向树；无进化链显示空态；点击节点跳转对应详情。
class EvolutionSectionPlaceholder extends ConsumerWidget {
  const EvolutionSectionPlaceholder({
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
        const SectionTitle(title: '进化'),
        const SizedBox(height: AppSpacing.m),
        _EvolutionBody(speciesId: speciesId),
      ],
    );
  }
}

/// 「没有进化关系」空态文案。
class _NoEvolutionHint extends StatelessWidget {
  const _NoEvolutionHint();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      '该宝可梦没有进化关系',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

/// 分区级加载失败：轻量文案 + 重试（与页面骨架的错误行同构）。
class _SectionError extends StatelessWidget {
  const _SectionError({required this.onRetry});

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

class _EvolutionBody extends ConsumerWidget {
  const _EvolutionBody({required this.speciesId});

  final int speciesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final treeAsync = ref.watch(evolutionTreeProvider(speciesId));
    return treeAsync.when(
      loading: () => const Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(height: 64, width: 220),
            SizedBox(height: AppSpacing.s),
            SkeletonBox(height: 64, width: 260),
          ],
        ),
      ),
      error: (error, stackTrace) => _SectionError(
        onRetry: () => ref.invalidate(evolutionTreeProvider(speciesId)),
      ),
      data: (tree) {
        if (tree == null || tree.root.children.isEmpty) {
          return const _NoEvolutionHint();
        }
        final isExpanded =
            windowSizeFor(MediaQuery.sizeOf(context).width) ==
                WindowSize.expanded;
        return isExpanded
            ? _HorizontalTree(tree: tree, currentSpeciesId: speciesId)
            : _VerticalTree(tree: tree, currentSpeciesId: speciesId);
      },
    );
  }
}

/// compact 纵向树：根在上，子节点逐级缩进（├ / └ 导引线 + 条件 chips）。
class _VerticalTree extends StatelessWidget {
  const _VerticalTree({required this.tree, required this.currentSpeciesId});

  final EvolutionTree tree;
  final int currentSpeciesId;

  @override
  Widget build(BuildContext context) {
    final rows = flattenEvolutionTree(tree);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          _VerticalRow(row: row, currentSpeciesId: currentSpeciesId),
      ],
    );
  }
}

class _VerticalRow extends StatelessWidget {
  const _VerticalRow({required this.row, required this.currentSpeciesId});

  final EvolutionRow row;
  final int currentSpeciesId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // IntrinsicHeight 让导引线与本行内容等高，行与行之间竖线得以连续。
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var level = 0; level < row.depth; level++)
            _GuideColumn(
              isElbow: level == row.depth - 1,
              ancestorIsLast:
                  level < row.depth - 1 && row.guides[level],
              isLastChild: row.isLastChild,
              lineColor: scheme.outlineVariant,
            ),
          Expanded(
            child: _EvolutionTile(
              node: row.node,
              selected: row.node.speciesId == currentSpeciesId,
              conditionLabels: row.edgeFromParent == null
                  ? const <String>[]
                  : evolutionConditionLabels(row.edgeFromParent!),
            ),
          ),
        ],
      ),
    );
  }
}

/// 缩进导引列：竖线 + 横线（├ / └ 视觉），2px outlineVariant。
///
/// 用 Align + FractionallySizedBox 取半高（IntrinsicHeight 场景下
/// LayoutBuilder 不支持内在尺寸计算，不可用）。
class _GuideColumn extends StatelessWidget {
  const _GuideColumn({
    required this.isElbow,
    required this.ancestorIsLast,
    required this.isLastChild,
    required this.lineColor,
  });

  final bool isElbow;
  final bool ancestorIsLast;
  final bool isLastChild;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    /// 半高竖线（[top] 为 true 取上半，否则取下半）。
    Widget halfVLine({required bool top}) {
      return Positioned.fill(
        child: Align(
          alignment: top ? Alignment.topLeft : Alignment.bottomLeft,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Padding(
              padding: const EdgeInsets.only(left: 13),
              child: SizedBox(
                width: 2,
                child: ColoredBox(color: lineColor),
              ),
            ),
          ),
        ),
      );
    }

    final pieces = <Widget>[];
    if (!isElbow) {
      // 祖先导引：祖先为末位子节点时线到该行即止，不再向下延伸。
      if (!ancestorIsLast) {
        pieces.add(Positioned(
          left: 13,
          top: 0,
          bottom: 0,
          width: 2,
          child: ColoredBox(color: lineColor),
        ));
      }
    } else {
      pieces.add(halfVLine(top: true));
      pieces.add(Positioned.fill(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 2,
              margin: const EdgeInsets.only(left: 13),
              color: lineColor,
            ),
          ],
        ),
      ));
      if (!isLastChild) pieces.add(halfVLine(top: false));
    }

    return SizedBox(
      width: _kGuideWidth,
      child: Stack(clipBehavior: Clip.none, children: pieces),
    );
  }
}

/// compact 节点行：横向卡（缩略图 + 名 + 编号）+ 节点下方条件 chips。
class _EvolutionTile extends StatelessWidget {
  const _EvolutionTile({
    required this.node,
    required this.selected,
    required this.conditionLabels,
  });

  final EvolutionNode node;
  final bool selected;
  final List<String> conditionLabels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.input),
            onTap: selected
                ? null
                : () => context.push('/pokemon/${node.speciesId}'),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.s),
              decoration: ShapeDecoration(
                color: selected ? scheme.primaryContainer : scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  side: BorderSide(
                    color:
                        selected ? scheme.primary : scheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _NodeThumb(asset: node.thumbAsset),
                  const SizedBox(width: AppSpacing.s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.nameZh,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelLarge,
                      ),
                      Text(
                        formatDexNumber(node.nationalDex),
                        style: AppTypography.tabularFigures(
                          textTheme.bodySmall ?? const TextStyle(),
                        ).copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (conditionLabels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 56,
                top: AppSpacing.xs,
              ),
              child: Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final label in conditionLabels)
                    ConditionChip(label: label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// expanded 横向树：折线连接 + 节点卡，包在 InteractiveViewer 里平移缩放。
class _HorizontalTree extends StatelessWidget {
  const _HorizontalTree({required this.tree, required this.currentSpeciesId});

  final EvolutionTree tree;
  final int currentSpeciesId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final layout = layoutEvolutionCanvas(
      tree,
      nodeWidth: _kNodeWidth,
      columnGap: _kColumnGap,
      rowHeight: _kRowHeight,
    );
    final bySpecies = {
      for (final placement in layout.placements)
        placement.node.speciesId: placement,
    };

    return SizedBox(
      height: layout.viewportHeight,
      child: InteractiveViewer(
        constrained: false,
        minScale: 0.5,
        maxScale: 1.5,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: layout.width,
          height: layout.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _EvolutionEdgePainter(
                    placements: layout.placements,
                    bySpecies: bySpecies,
                    nodeWidth: _kNodeWidth,
                    columnGap: _kColumnGap,
                    lineColor: scheme.outlineVariant,
                  ),
                ),
              ),
              for (final placement in layout.placements)
                Positioned(
                  // 两侧各让 24px 给可能较宽的条件 chips。
                  left: placement.x - (_kNodeWidth + 48) / 2,
                  top: placement.y - _kCardHeight / 2,
                  width: _kNodeWidth + 48,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EvolutionNodeCard(
                        node: placement.node,
                        width: _kNodeWidth,
                        selected:
                            placement.node.speciesId == currentSpeciesId,
                      ),
                      if (placement.edgeFromParent != null)
                        _ConditionChipArea(
                          labels: evolutionConditionLabels(
                            placement.edgeFromParent!,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 节点卡下方的条件 chips（预留高已计入行高）。
class _ConditionChipArea extends StatelessWidget {
  const _ConditionChipArea({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox(height: AppSpacing.xs);
    }
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [for (final label in labels) ConditionChip(label: label)],
      ),
    );
  }
}

/// 折线连接：父右缘 → 中线 → 子左缘（横平竖直，2px outlineVariant）。
class _EvolutionEdgePainter extends CustomPainter {
  _EvolutionEdgePainter({
    required this.placements,
    required this.bySpecies,
    required this.nodeWidth,
    required this.columnGap,
    required this.lineColor,
  });

  final List<EvolutionNodePlacement> placements;
  final Map<int, EvolutionNodePlacement> bySpecies;
  final double nodeWidth;
  final double columnGap;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final placement in placements) {
      final fromSpeciesId = placement.edgeFromParent?.fromSpeciesId;
      if (fromSpeciesId == null) continue;
      final parent = bySpecies[fromSpeciesId];
      if (parent == null) continue;
      final startX = parent.x + nodeWidth / 2;
      final endX = placement.x - nodeWidth / 2;
      final midX = startX + columnGap / 2;
      canvas.drawPath(
        Path()
          ..moveTo(startX, parent.y)
          ..lineTo(midX, parent.y)
          ..lineTo(midX, placement.y)
          ..lineTo(endX, placement.y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_EvolutionEdgePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.nodeWidth != nodeWidth ||
      oldDelegate.columnGap != columnGap ||
      !identical(oldDelegate.placements, placements);
}

/// expanded 节点卡：纵向排布缩略图 / 名 / 编号，当前 species 高亮。
class _EvolutionNodeCard extends StatelessWidget {
  const _EvolutionNodeCard({
    required this.node,
    required this.width,
    required this.selected,
  });

  final EvolutionNode node;
  final double width;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.input),
      onTap: selected
          ? null
          : () => context.push('/pokemon/${node.speciesId}'),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: ShapeDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
            side: BorderSide(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _NodeThumb(asset: node.thumbAsset),
            const SizedBox(height: AppSpacing.xs),
            Text(
              node.nameZh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelLarge,
            ),
            Text(
              formatDexNumber(node.nationalDex),
              style: AppTypography.tabularFigures(
                textTheme.bodySmall ?? const TextStyle(),
              ).copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 48 圆形缩略图；资产缺失回退占位图标。
class _NodeThumb extends StatelessWidget {
  const _NodeThumb({this.asset});

  final String? asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Icon(
      Icons.catching_pokemon,
      size: 24,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerLow,
        shape: const CircleBorder(),
      ),
      child: asset == null
          ? placeholder
          : ClipOval(
              child: Image.asset(
                asset!,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}
