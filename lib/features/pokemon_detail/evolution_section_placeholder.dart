import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../core/di.dart';
import '../../domain/models/evolution.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';
import 'evolution_layout.dart';
import 'providers.dart';

/// 进化树数据（speciesId → 整条进化链；无链返回 null）。
final evolutionTreeProvider =
    FutureProvider.autoDispose.family<EvolutionTree?, int>((
  ref,
  speciesId,
) {
  return ref.watch(pokedexRepositoryProvider).getEvolutionTree(speciesId);
});

/// compact 纵向树导引列宽。
const double _kGuideWidth = 28;

/// dense 纵向树导引列宽（design-ui.md §5 密度放大）。
const double _kGuideWidthDense = 32;

/// 节点缩略图直径；dense 放大到 56。
const double _kThumbSize = 48;
const double _kThumbSizeDense = 56;

/// 水平连接线上方条件芯片组与中线之间的安全间距（避开 2px 线段与 8px 箭头）。
const double _kConnectorLabelGap = 6;

/// 垂直时间线竖线的水平中轴 = 卡身内缩略图中心：内边距 s(8) + 半径 24 = 32。
const double _kTimelineLineCenter = AppSpacing.s + _kThumbSize / 2;

/// 进化分区（design-ui.md §5）：形态级多根森林 + 三态自适应渲染：
/// - 宽度充裕（横排整林宽度拟合，且分支链还要求 ≥ [kHorizontalBranchMinWidth]）：
///   52poke 风格横向阶梯树（竖排中心卡 + 连续脊柱分支线 + 箭头线上方条件芯片）；
/// - 窄宽且纯线性链：垂直时间线（零边距卡片 + 0px 断口连续竖线与下箭头）；
/// - 窄宽或含分支/多根的纵向退化：双子行零断线纵向树（条件连线子行 + 动态卡中心拐角子行）。
class EvolutionSectionPlaceholder extends ConsumerWidget {
  const EvolutionSectionPlaceholder({
    super.key,
    required this.speciesId,
    this.selectedFormId,
  });

  final int speciesId;

  /// 当前详情页选中的形态 id；缺省时回退读取 [selectedFormIdProvider]。
  final int? selectedFormId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveFormId =
        selectedFormId ?? ref.watch(selectedFormIdProvider(speciesId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: '进化'),
        const SizedBox(height: AppSpacing.m),
        _EvolutionBody(
          speciesId: speciesId,
          selectedFormId: effectiveFormId,
        ),
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

/// 分区级加载失败：轻量文案 + 重试。
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

/// 当当前选中的形态不在进化树内（如关都大葱鸭 / 普通野蛮鲈鱼）时的温和提示条。
class _NonEvolvingFormNotice extends StatelessWidget {
  const _NonEvolvingFormNotice({required this.evolvingFormNames});

  final List<String> evolvingFormNames;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = evolvingFormNames.isEmpty
        ? '当前形态无法进化'
        : '当前形态无法进化，仅${evolvingFormNames.map((name) => '「$name」').join(' / ')}存在以下进化';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Text(
              detail,
              style:
                  textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionBody extends ConsumerWidget {
  const _EvolutionBody({
    required this.speciesId,
    required this.selectedFormId,
  });

  final int speciesId;
  final int? selectedFormId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      final maxWidth = constraints.maxWidth;
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
          if (tree == null || !tree.hasAnyEvolution) {
            return const _NoEvolutionHint();
          }
          final highlightedFormId = resolveHighlightedEvolutionFormId(
            tree,
            speciesId: speciesId,
            selectedFormId: selectedFormId,
          );
          final evolvingFormNames = <String>[
            if (highlightedFormId == null)
              for (final node in tree.effectiveNodesByFormId.values)
                if (node.speciesId == speciesId && node.formNameZh != null)
                  node.formNameZh!,
          ];

          void onNodeTap(EvolutionNode node) {
            final targetFormId = node.resolvedFormId;
            if (targetFormId == highlightedFormId) return;
            if (node.speciesId == speciesId) {
              ref.read(selectedFormIdProvider(speciesId).notifier).state =
                  targetFormId;
              return;
            }
            final location = node.isDefaultForm
                ? '/pokemon/${node.speciesId}'
                : '/pokemon/${node.speciesId}?formId=$targetFormId';
            context.push(location);
          }

          final hasBranch = hasBranchingInForest(tree);
          final horizontalAllowed =
              !hasBranch || maxWidth >= kHorizontalBranchMinWidth;

          final roomyWidth = horizontalForestWidth(
            tree,
            nodeWidth: kHorizontalNodeWidthRoomy,
            edgeWidth: kHorizontalEdgeWidthRoomy,
            branchSpineWidth: kHorizontalBranchSpineWidthRoomy,
          );
          final standardWidth = horizontalForestWidth(
            tree,
            nodeWidth: kHorizontalNodeWidth,
            edgeWidth: kHorizontalEdgeWidth,
            branchSpineWidth: kHorizontalBranchSpineWidth,
          );

          final Widget forest;
          if (horizontalAllowed && maxWidth >= roomyWidth) {
            forest = _HorizontalForest(
              tree: tree,
              highlightedFormId: highlightedFormId,
              onNodeTap: onNodeTap,
              cardWidth: kHorizontalNodeWidthRoomy,
              edgeWidth: kHorizontalEdgeWidthRoomy,
              branchSpineWidth: kHorizontalBranchSpineWidthRoomy,
            );
          } else if (horizontalAllowed && maxWidth >= standardWidth) {
            forest = _HorizontalForest(
              tree: tree,
              highlightedFormId: highlightedFormId,
              onNodeTap: onNodeTap,
              cardWidth: kHorizontalNodeWidth,
              edgeWidth: kHorizontalEdgeWidth,
              branchSpineWidth: kHorizontalBranchSpineWidth,
            );
          } else {
            final dense = windowSizeFor(maxWidth) == WindowSize.expanded;
            forest = _VerticalForest(
              tree: tree,
              highlightedFormId: highlightedFormId,
              onNodeTap: onNodeTap,
              dense: dense,
            );
          }

          if (highlightedFormId != null) {
            return forest;
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NonEvolvingFormNotice(evolvingFormNames: evolvingFormNames),
              const SizedBox(height: AppSpacing.m),
              forest,
            ],
          );
        },
      );
    });
  }
}

/// 并行根之间的分隔线（如呆呆兽普通与伽勒尔线、喵喵三地区线）。
class _ForestDivider extends StatelessWidget {
  const _ForestDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 形态一：52poke 风格横向阶梯树（同时支持线性链、单/多级分支与多根并行）
// ---------------------------------------------------------------------------

class _HorizontalForest extends StatelessWidget {
  const _HorizontalForest({
    required this.tree,
    required this.highlightedFormId,
    required this.onNodeTap,
    required this.cardWidth,
    required this.edgeWidth,
    required this.branchSpineWidth,
  });

  final EvolutionTree tree;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;
  final double cardWidth;
  final double edgeWidth;
  final double branchSpineWidth;

  @override
  Widget build(BuildContext context) {
    final roots = tree.effectiveRoots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, root) in roots.indexed) ...[
          if (index > 0) const _ForestDivider(),
          _HorizontalSubtree(
            tree: tree,
            node: root,
            visitedFormIds: <int>{},
            highlightedFormId: highlightedFormId,
            onNodeTap: onNodeTap,
            cardWidth: cardWidth,
            edgeWidth: edgeWidth,
            branchSpineWidth: branchSpineWidth,
          ),
        ],
      ],
    );
  }
}

class _HorizontalSubtree extends StatelessWidget {
  const _HorizontalSubtree({
    required this.tree,
    required this.node,
    required this.visitedFormIds,
    required this.highlightedFormId,
    required this.onNodeTap,
    required this.cardWidth,
    required this.edgeWidth,
    required this.branchSpineWidth,
  });

  final EvolutionTree tree;
  final EvolutionNode node;
  final Set<int> visitedFormIds;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;
  final double cardWidth;
  final double edgeWidth;
  final double branchSpineWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final nodes = tree.effectiveNodesByFormId;
    final nextVisited = <int>{...visitedFormIds, node.resolvedFormId};
    final edges = [
      for (final edge in node.children)
        if (!nextVisited.contains(edge.resolvedToFormId) &&
            nodes[edge.resolvedToFormId] != null)
          edge,
    ];

    final card = _HorizontalEvolutionCard(
      node: node,
      selected: node.resolvedFormId == highlightedFormId,
      width: cardWidth,
      onTap: () => onNodeTap(node),
    );

    if (edges.isEmpty) {
      return card;
    }

    if (edges.length == 1) {
      final edge = edges.single;
      final child = nodes[edge.resolvedToFormId]!;
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          card,
          _HorizontalEdgeConnector(
            width: edgeWidth,
            conditionLabels: evolutionConditionLabels(
              edge,
              indicateOtherRegion: shouldIndicateOtherRegion(edge, edges),
            ),
          ),
          _HorizontalSubtree(
            tree: tree,
            node: child,
            visitedFormIds: nextVisited,
            highlightedFormId: highlightedFormId,
            onNodeTap: onNodeTap,
            cardWidth: cardWidth,
            edgeWidth: edgeWidth,
            branchSpineWidth: branchSpineWidth,
          ),
        ],
      );
    }

    // 多分支阶梯树：左卡 + 中央水平短桩 + 右侧连续脊柱分叉列。
    final stubWidth = branchSpineWidth / 2;
    final forkWidth = branchSpineWidth - stubWidth;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        card,
        SizedBox(
          width: stubWidth,
          height: 2,
          child: ColoredBox(color: scheme.outlineVariant),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, edge) in edges.indexed)
              _HorizontalBranchRow(
                tree: tree,
                edge: edge,
                siblings: edges,
                child: nodes[edge.resolvedToFormId]!,
                visitedFormIds: nextVisited,
                highlightedFormId: highlightedFormId,
                onNodeTap: onNodeTap,
                cardWidth: cardWidth,
                edgeWidth: edgeWidth,
                branchSpineWidth: branchSpineWidth,
                forkWidth: forkWidth,
                isFirst: index == 0,
                isLast: index == edges.length - 1,
              ),
          ],
        ),
      ],
    );
  }
}

class _HorizontalBranchRow extends StatelessWidget {
  const _HorizontalBranchRow({
    required this.tree,
    required this.edge,
    required this.siblings,
    required this.child,
    required this.visitedFormIds,
    required this.highlightedFormId,
    required this.onNodeTap,
    required this.cardWidth,
    required this.edgeWidth,
    required this.branchSpineWidth,
    required this.forkWidth,
    required this.isFirst,
    required this.isLast,
  });

  final EvolutionTree tree;
  final EvolutionEdge edge;
  final List<EvolutionEdge> siblings;
  final EvolutionNode child;
  final Set<int> visitedFormIds;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;
  final double cardWidth;
  final double edgeWidth;
  final double branchSpineWidth;
  final double forkWidth;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: forkWidth,
            child: CustomPaint(
              painter: _HorizontalSpinePainter(
                lineColor: scheme.outlineVariant,
                isFirst: isFirst,
                isLast: isLast,
              ),
            ),
          ),
          // 上下对称 xs(4) 内边距承担分支间距，使行垂直中点与内部子树中心重合。
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _HorizontalEdgeConnector(
                  width: edgeWidth,
                  conditionLabels: evolutionConditionLabels(
                    edge,
                    indicateOtherRegion:
                        shouldIndicateOtherRegion(edge, siblings),
                  ),
                ),
                _HorizontalSubtree(
                  tree: tree,
                  node: child,
                  visitedFormIds: visitedFormIds,
                  highlightedFormId: highlightedFormId,
                  onNodeTap: onNodeTap,
                  cardWidth: cardWidth,
                  edgeWidth: edgeWidth,
                  branchSpineWidth: branchSpineWidth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 分支脊柱绘制器：首分支从半高起竖线向下，末分支上半竖线止于半高，
/// 中间分支贯穿全高，所有分支从半高向右水平接出。
class _HorizontalSpinePainter extends CustomPainter {
  const _HorizontalSpinePainter({
    required this.lineColor,
    required this.isFirst,
    required this.isLast,
  });

  final Color lineColor;
  final bool isFirst;
  final bool isLast;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final midY = size.height / 2;
    const lineX = 1.0;

    if (!isFirst) {
      canvas.drawLine(Offset(lineX, 0), Offset(lineX, midY), paint);
    }
    if (!isLast) {
      canvas.drawLine(Offset(lineX, midY), Offset(lineX, size.height), paint);
    }
    canvas.drawLine(Offset(lineX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_HorizontalSpinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.isFirst != isFirst ||
      oldDelegate.isLast != isLast;
}

/// 横向连接箭头与上方条件芯片：箭头横线与右端实心三角恒落在 `size.height / 2`，
/// 芯片通过 [_SymmetricAboveCenter] 置于中线之上且控件自身对中线严格对称。
class _HorizontalEdgeConnector extends StatelessWidget {
  const _HorizontalEdgeConnector({
    required this.width,
    required this.conditionLabels,
  });

  final double width;
  final List<String> conditionLabels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _HorizontalArrowPainter(
                lineColor: scheme.outlineVariant,
                arrowColor: scheme.outline,
              ),
            ),
          ),
          _SymmetricAboveCenter(
            gapAboveCenter: _kConnectorLabelGap,
            child: conditionLabels.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs / 2,
                      children: [
                        for (final label in conditionLabels)
                          ConditionChip(
                            label: label,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalArrowPainter extends CustomPainter {
  const _HorizontalArrowPainter({
    required this.lineColor,
    required this.arrowColor,
  });

  final Color lineColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final midY = size.height / 2;
    const arrowLen = 6.0;
    const arrowHalfH = 4.0;
    final lineEnd = math.max(0.0, size.width - arrowLen);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, midY), Offset(lineEnd, midY), linePaint);

    final arrowPath = Path()
      ..moveTo(size.width, midY)
      ..lineTo(lineEnd, midY - arrowHalfH)
      ..lineTo(lineEnd, midY + arrowHalfH)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(_HorizontalArrowPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.arrowColor != arrowColor;
}

/// 将唯一子组件置于垂直中心以上 `gapAboveCenter` 处，并把总高度对称撑开到
/// `2 * (childHeight + gapAboveCenter)`，保证中线与箭头线段永不偏移。
class _SymmetricAboveCenter extends SingleChildRenderObjectWidget {
  const _SymmetricAboveCenter({
    required this.gapAboveCenter,
    required super.child,
  });

  final double gapAboveCenter;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSymmetricAboveCenter(gapAboveCenter: gapAboveCenter);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSymmetricAboveCenter renderObject,
  ) {
    renderObject.gapAboveCenter = gapAboveCenter;
  }
}

class _RenderSymmetricAboveCenter extends RenderShiftedBox {
  _RenderSymmetricAboveCenter({
    required double gapAboveCenter,
    RenderBox? child,
  })  : _gapAboveCenter = gapAboveCenter,
        super(child);

  double _gapAboveCenter;
  double get gapAboveCenter => _gapAboveCenter;
  set gapAboveCenter(double value) {
    if (_gapAboveCenter == value) return;
    _gapAboveCenter = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(height) ?? 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(height) ?? 0.0;

  @override
  double computeMinIntrinsicHeight(double width) {
    final c = child;
    if (c == null) return _gapAboveCenter * 2;
    return 2 * (c.getMinIntrinsicHeight(width) + _gapAboveCenter);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final c = child;
    if (c == null) return _gapAboveCenter * 2;
    return 2 * (c.getMaxIntrinsicHeight(width) + _gapAboveCenter);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final c = child;
    if (c == null) {
      return constraints.constrain(Size(0, _gapAboveCenter * 2));
    }
    final halfMaxH = constraints.hasBoundedHeight
        ? math.max(0.0, constraints.maxHeight / 2 - _gapAboveCenter)
        : double.infinity;
    final childSize = c.getDryLayout(
      BoxConstraints(
        minWidth: 0,
        maxWidth: constraints.maxWidth,
        minHeight: 0,
        maxHeight: halfMaxH,
      ),
    );
    final desiredHeight = 2 * (childSize.height + _gapAboveCenter);
    final w = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.constrainWidth(childSize.width);
    return constraints.constrain(Size(w, desiredHeight));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(0, _gapAboveCenter * 2));
      return;
    }
    final halfMaxH = constraints.hasBoundedHeight
        ? math.max(0.0, constraints.maxHeight / 2 - _gapAboveCenter)
        : double.infinity;
    c.layout(
      BoxConstraints(
        minWidth: 0,
        maxWidth: constraints.maxWidth,
        minHeight: 0,
        maxHeight: halfMaxH,
      ),
      parentUsesSize: true,
    );
    final desiredHeight = 2 * (c.size.height + _gapAboveCenter);
    final w = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.constrainWidth(c.size.width);
    size = constraints.constrain(Size(w, desiredHeight));
    final childX = math.max(0.0, (size.width - c.size.width) / 2);
    final childY =
        math.max(0.0, size.height / 2 - _gapAboveCenter - c.size.height);
    (c.parentData! as BoxParentData).offset = Offset(childX, childY);
  }
}

/// 52poke 风格横向竖卡：居中缩略图 + 中文名 + 编号 + 形态微胶囊 + 属性徽章。
class _HorizontalEvolutionCard extends StatelessWidget {
  const _HorizontalEvolutionCard({
    required this.node,
    required this.selected,
    required this.width,
    required this.onTap,
  });

  final EvolutionNode node;
  final bool selected;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('evo_card_${node.resolvedFormId}'),
        borderRadius: BorderRadius.circular(AppRadius.input),
        onTap: selected ? null : onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.s,
          ),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NodeThumb(asset: node.thumbAsset, size: _kThumbSize),
              const SizedBox(height: AppSpacing.xs),
              Text(
                node.nameZh,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                formatDexNumber(node.nationalDex),
                style: AppTypography.tabularFigures(
                  textTheme.bodySmall ?? const TextStyle(),
                ).copyWith(color: scheme.onSurfaceVariant),
              ),
              if (node.formNameZh != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _FormTagPill(
                  label: node.formNameZh!,
                  onSelectedCard: selected,
                ),
              ],
              if (node.typeIds.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, typeId) in node.typeIds.indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        TypeBadge(type: typeId, size: TypeBadgeSize.sm),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 形态二 / 三：窄面板纵向布局（多根并行支持时间线与双子行零断线纵向树）
// ---------------------------------------------------------------------------

class _VerticalForest extends StatelessWidget {
  const _VerticalForest({
    required this.tree,
    required this.highlightedFormId,
    required this.onNodeTap,
    required this.dense,
  });

  final EvolutionTree tree;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final roots = tree.effectiveRoots;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, root) in roots.indexed) ...[
          if (index > 0) const _ForestDivider(),
          if (isLinearEvolutionSubtree(tree, root))
            _LinearTimeline(
              rows: flattenEvolutionSubtree(tree, root),
              highlightedFormId: highlightedFormId,
              onNodeTap: onNodeTap,
            )
          else
            _VerticalTree(
              rows: flattenEvolutionSubtree(tree, root),
              highlightedFormId: highlightedFormId,
              onNodeTap: onNodeTap,
              dense: dense,
            ),
        ],
      ],
    );
  }
}

/// 窄宽纯线性链：垂直时间线，卡片上下 0 外边距，竖线与下箭头从上卡底边直达下卡顶边。
class _LinearTimeline extends StatelessWidget {
  const _LinearTimeline({
    required this.rows,
    required this.highlightedFormId,
    required this.onNodeTap,
  });

  final List<EvolutionRow> rows;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0)
            _TimelineConnector(
              key: ValueKey('evo_timeline_conn_${row.node.resolvedFormId}'),
              conditionLabels: row.edgeFromParent == null
                  ? const <String>[]
                  : evolutionConditionLabels(
                      row.edgeFromParent!,
                      indicateOtherRegion: row.indicateOtherRegion,
                    ),
            ),
          _VerticalEvolutionCard(
            node: row.node,
            selected: row.node.resolvedFormId == highlightedFormId,
            onTap: () => onNodeTap(row.node),
          ),
        ],
      ],
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({
    super.key,
    required this.conditionLabels,
  });

  final List<String> conditionLabels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _kTimelineLineCenter,
            child: CustomPaint(
              painter: _VerticalTimelineLinePainter(
                lineColor: scheme.outlineVariant,
                arrowColor: scheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s,
                top: AppSpacing.s,
                bottom: AppSpacing.s,
              ),
              child: conditionLabels.isEmpty
                  ? const SizedBox(height: AppSpacing.s)
                  : Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final label in conditionLabels)
                          ConditionChip(label: label, maxLines: 2),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalTimelineLinePainter extends CustomPainter {
  const _VerticalTimelineLinePainter({
    required this.lineColor,
    required this.arrowColor,
  });

  final Color lineColor;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width - 1;
    const arrowLen = 6.0;
    const arrowHalfW = 4.0;
    final lineEnd = math.max(0.0, size.height - arrowLen);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, 0), Offset(x, lineEnd), linePaint);

    final arrowPath = Path()
      ..moveTo(x, size.height)
      ..lineTo(x - arrowHalfW, lineEnd)
      ..lineTo(x + arrowHalfW, lineEnd)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(_VerticalTimelineLinePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.arrowColor != arrowColor;
}

/// 窄宽分支纵向树：每条非根分支拆成紧贴的两行——
/// 1) [_VerticalTreeEdgeRow]：连续导引竖线 + 该边条件芯片；
/// 2) [_VerticalTreeCardRow]：动态 50% 卡高拐角 + 卡片。
/// 两行均为 0 外边距拼接，彻底消除硬编码高度偏差或断线。
class _VerticalTree extends StatelessWidget {
  const _VerticalTree({
    required this.rows,
    required this.highlightedFormId,
    required this.onNodeTap,
    this.dense = false,
  });

  final List<EvolutionRow> rows;
  final int? highlightedFormId;
  final ValueChanged<EvolutionNode> onNodeTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final guideWidth = dense ? _kGuideWidthDense : _kGuideWidth;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, row) in rows.indexed)
          if (row.depth == 0)
            _VerticalEvolutionCard(
              node: row.node,
              selected: row.node.resolvedFormId == highlightedFormId,
              dense: dense,
              onTap: () => onNodeTap(row.node),
            )
          else ...[
            _VerticalTreeEdgeRow(
              row: row,
              guideWidth: guideWidth,
              isFirstChildAfterParent: rows[index - 1].depth == row.depth - 1,
            ),
            _VerticalTreeCardRow(
              row: row,
              guideWidth: guideWidth,
              selected: row.node.resolvedFormId == highlightedFormId,
              dense: dense,
              onTap: () => onNodeTap(row.node),
            ),
          ],
      ],
    );
  }
}

class _VerticalTreeEdgeRow extends StatelessWidget {
  const _VerticalTreeEdgeRow({
    required this.row,
    required this.guideWidth,
    required this.isFirstChildAfterParent,
  });

  final EvolutionRow row;
  final double guideWidth;
  final bool isFirstChildAfterParent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labels = row.edgeFromParent == null
        ? const <String>[]
        : evolutionConditionLabels(
            row.edgeFromParent!,
            indicateOtherRegion: row.indicateOtherRegion,
          );
    return IntrinsicHeight(
      key: ValueKey('evo_tree_edge_${row.node.resolvedFormId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var level = 0; level < row.depth; level++)
            _TreePassThroughColumn(
              width: guideWidth,
              // `depth - 1` 是父节点连往本分支拐角的主干竖线，必须贯通本条件行。
              visible: level == row.depth - 1 || row.guides[level],
              lineColor: scheme.outlineVariant,
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirstChildAfterParent ? AppSpacing.s : AppSpacing.m,
                bottom: AppSpacing.xs,
              ),
              child: labels.isEmpty
                  ? const SizedBox(height: AppSpacing.xs)
                  : Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final label in labels)
                          ConditionChip(label: label, maxLines: 2),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalTreeCardRow extends StatelessWidget {
  const _VerticalTreeCardRow({
    required this.row,
    required this.guideWidth,
    required this.selected,
    required this.dense,
    required this.onTap,
  });

  final EvolutionRow row;
  final double guideWidth;
  final bool selected;
  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      key: ValueKey('evo_tree_card_row_${row.node.resolvedFormId}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var level = 0; level < row.depth - 1; level++)
            _TreePassThroughColumn(
              width: guideWidth,
              visible: row.guides[level],
              lineColor: scheme.outlineVariant,
            ),
          SizedBox(
            key: ValueKey('evo_tree_elbow_${row.node.resolvedFormId}'),
            width: guideWidth,
            child: CustomPaint(
              painter: _VerticalTreeElbowPainter(
                lineColor: scheme.outlineVariant,
                arrowColor: scheme.outline,
                continueDown: row.guides[row.depth - 1],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _VerticalEvolutionCard(
                node: row.node,
                selected: selected,
                dense: dense,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreePassThroughColumn extends StatelessWidget {
  const _TreePassThroughColumn({
    required this.width,
    required this.visible,
    required this.lineColor,
  });

  final double width;
  final bool visible;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return SizedBox(width: width);
    }
    return SizedBox(
      width: width,
      child: CustomPaint(
        painter: _VerticalPassThroughPainter(lineColor: lineColor),
      ),
    );
  }
}

class _VerticalPassThroughPainter extends CustomPainter {
  const _VerticalPassThroughPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
  }

  @override
  bool shouldRepaint(_VerticalPassThroughPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor;
}

class _VerticalTreeElbowPainter extends CustomPainter {
  const _VerticalTreeElbowPainter({
    required this.lineColor,
    required this.arrowColor,
    required this.continueDown,
  });

  final Color lineColor;
  final Color arrowColor;
  final bool continueDown;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final midY = size.height / 2;
    const arrowLen = 6.0;
    const arrowHalfH = 4.0;
    final horizEnd = math.max(x, size.width - arrowLen);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawLine(
      Offset(x, 0),
      Offset(x, continueDown ? size.height : midY),
      linePaint,
    );
    canvas.drawLine(Offset(x, midY), Offset(horizEnd, midY), linePaint);

    final arrowPath = Path()
      ..moveTo(size.width, midY)
      ..lineTo(horizEnd, midY - arrowHalfH)
      ..lineTo(horizEnd, midY + arrowHalfH)
      ..close();
    canvas.drawPath(arrowPath, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(_VerticalTreeElbowPainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.arrowColor != arrowColor ||
      oldDelegate.continueDown != continueDown;
}

/// 窄面板节点横卡（0 上下外边距，支持完整名称 + 编号 + 形态胶囊 + 属性徽章，无溢出）。
class _VerticalEvolutionCard extends StatelessWidget {
  const _VerticalEvolutionCard({
    required this.node,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  final EvolutionNode node;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final thumbSize = dense ? _kThumbSizeDense : _kThumbSize;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('evo_card_${node.resolvedFormId}'),
        borderRadius: BorderRadius.circular(AppRadius.input),
        onTap: selected ? null : onTap,
        child: Container(
          padding: EdgeInsets.all(dense ? AppSpacing.m : AppSpacing.s),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _NodeThumb(asset: node.thumbAsset, size: thumbSize),
              const SizedBox(width: AppSpacing.s),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            node.nameZh,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          formatDexNumber(node.nationalDex),
                          style: AppTypography.tabularFigures(
                            textTheme.bodySmall ?? const TextStyle(),
                          ).copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (node.formNameZh != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _FormTagPill(
                        label: node.formNameZh!,
                        onSelectedCard: selected,
                      ),
                    ],
                    if (node.typeIds.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs / 2,
                        children: [
                          for (final typeId in node.typeIds)
                            TypeBadge(type: typeId, size: TypeBadgeSize.sm),
                        ],
                      ),
                    ],
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

/// 形态副标题微胶囊（遵守 DESIGN.md 对比度规范，全 6 种主题明暗均 ≥ 4.5:1）。
class _FormTagPill extends StatelessWidget {
  const _FormTagPill({
    required this.label,
    required this.onSelectedCard,
  });

  final String label;
  final bool onSelectedCard;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bg = onSelectedCard ? scheme.surface : scheme.primaryContainer;
    final fg = onSelectedCard ? scheme.onSurface : scheme.onPrimaryContainer;
    final shape = onSelectedCard
        ? StadiumBorder(side: BorderSide(color: scheme.outlineVariant))
        : const StadiumBorder();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: ShapeDecoration(color: bg, shape: shape),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
          fontSize: 10,
          height: 1.2,
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// 圆形缩略图（[size] 直径，内图四周留 2px 边距）；资产缺失回退占位图标。
class _NodeThumb extends StatelessWidget {
  const _NodeThumb({required this.size, this.asset});

  final double size;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final innerSize = size - 4;
    final placeholder = Icon(
      Icons.catching_pokemon,
      size: 24,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      width: size,
      height: size,
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
                width: innerSize,
                height: innerSize,
                cacheWidth: (innerSize * dpr).round(),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}
