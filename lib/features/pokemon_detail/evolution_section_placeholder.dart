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

/// compact 纵向树导引列宽。
const double _kGuideWidth = 28;

/// dense 纵向树导引列宽（design-ui.md §5 密度放大）。
const double _kGuideWidthDense = 32;

/// compact 节点缩略图直径；dense 放大到 56。
const double _kThumbSize = 48;
const double _kThumbSizeDense = 56;

/// 横排箭头列宽：与 [linearChainRowWidth] 的估算常数（72）逐字对齐——
/// 「放得下」判定基于同一估算，列宽偏离即判定失真。该常数在
/// evolution_layout.dart 内私有且约定不改彼文件，故此处落对齐副本。
const double _kArrowColumnWidth = 72;

/// 横排节点卡的宽预算（作为 nodeMinWidth 喂给 [linearChainRowWidth]）：
/// 卡身固定部分（padding s×2 + 缩略图 48 + 间距 s）= 72，加名称列
/// 上限 6 字 × labelLarge 13 = 78。彼文件默认常数 120 只够 3 字名，
/// 4 字名实际卡宽已到 124——继续用默认值会出现「判定放得下、实际
/// 行溢出」（如飞天螳螂→劈斧螳螂落在窗口 376–383 区间）。150 覆盖
/// 至 6 字名，判定只会偏保守（多回退纵向树），不会漏判溢出。
const double _kLinearNodeCardWidth = 150;

/// 进化分区（design-ui.md §5）：数据定形态的双形态渲染——
/// - 纯线性链且分区本地宽 ≥ 估算行宽 → 横排一行（节点卡列 +
///   条件 chips 与箭头列交替）；
/// - 分支链或宽不足 → 纵向树（├ / └ 导引线 + 条件 chips）；
/// - 本地宽 ≥840（expanded）纵向树放大密度，形态结构不变。
/// 形态决策取 [LayoutBuilder] 的分区本地宽而非窗口宽：双栏
/// master-detail 的窄详情面板自动回退纵向树。无进化链显示空态；
/// 点击节点跳转对应详情；一切内容随页面自然滚动（无画布交互）。
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
    // 本地宽决策：maxWidth 是分区真实可用宽（双栏 master-detail 的窄
    // 详情面板自动回退纵向树），与窗口宽 MediaQuery 无关。
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
          if (tree == null || tree.root.children.isEmpty) {
            return const _NoEvolutionHint();
          }
          // 横排拦截：纯线性链且本地宽 ≥ 估算行宽；放不下即回退纵向
          // 树，横排行内不做 Wrap / FittedBox / 横向滚动。节点卡宽预算
          // 用校准过的 [_kLinearNodeCardWidth]（理由见其注释）。
          final rows = flattenEvolutionTree(tree);
          final useLinearRow = isLinearEvolutionChain(tree) &&
              maxWidth >=
                  linearChainRowWidth(
                    rows.length,
                    nodeMinWidth: _kLinearNodeCardWidth,
                  );
          return useLinearRow
              ? _LinearChainRow(tree: tree, currentSpeciesId: speciesId)
              : _VerticalTree(
                  tree: tree,
                  currentSpeciesId: speciesId,
                  dense: windowSizeFor(maxWidth) == WindowSize.expanded,
                );
        },
      );
    });
  }
}

/// 线性链横排一行（design-ui.md §5 形态一）：节点卡列（上卡、下该边
/// 条件 chips）与箭头列交替，整行随分区左对齐。启用与否由
/// [_EvolutionBody] 按本地宽与估算行宽拦截，行内不再自适应。
class _LinearChainRow extends StatelessWidget {
  const _LinearChainRow({required this.tree, required this.currentSpeciesId});

  final EvolutionTree tree;
  final int currentSpeciesId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // 线性链的先序展开即链序：第 i 行的目标卡挂第 i 条边的条件 chips。
    final rows = flattenEvolutionTree(tree);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0)
            SizedBox(
              width: _kArrowColumnWidth,
              child: Center(
                child: Icon(
                  Icons.arrow_forward,
                  size: 24,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          _EvolutionTile(
            node: row.node,
            selected: row.node.speciesId == currentSpeciesId,
            conditionLabels: row.edgeFromParent == null
                ? const <String>[]
                : evolutionConditionLabels(row.edgeFromParent!),
          ),
        ],
      ],
    );
  }
}

/// 纵向树：根在上，子节点逐级缩进（├ / └ 导引线 + 条件 chips）。
/// [dense] 为 true（分区本地宽 ≥840，[WindowSize.expanded]）时放大
/// 密度：缩略图 56、卡内 padding m、导引列 32，形态结构不变。
class _VerticalTree extends StatelessWidget {
  const _VerticalTree({
    required this.tree,
    required this.currentSpeciesId,
    this.dense = false,
  });

  final EvolutionTree tree;
  final int currentSpeciesId;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final rows = flattenEvolutionTree(tree);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows)
          _VerticalRow(
            row: row,
            currentSpeciesId: currentSpeciesId,
            dense: dense,
          ),
      ],
    );
  }
}

class _VerticalRow extends StatelessWidget {
  const _VerticalRow({
    required this.row,
    required this.currentSpeciesId,
    this.dense = false,
  });

  final EvolutionRow row;
  final int currentSpeciesId;
  final bool dense;

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
              width: dense ? _kGuideWidthDense : _kGuideWidth,
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
              dense: dense,
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
    required this.width,
    required this.isElbow,
    required this.ancestorIsLast,
    required this.isLastChild,
    required this.lineColor,
  });

  final double width;

  final bool isElbow;
  final bool ancestorIsLast;
  final bool isLastChild;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    // 竖线 / 横线的横向落点：列宽中线左移半线宽，线随列宽居中
    //（28 → 13，32 → 15）。
    final lineLeft = width / 2 - 1;

    /// 半高竖线（[top] 为 true 取上半，否则取下半）。
    Widget halfVLine({required bool top}) {
      return Positioned.fill(
        child: Align(
          alignment: top ? Alignment.topLeft : Alignment.bottomLeft,
          child: FractionallySizedBox(
            heightFactor: 0.5,
            child: Padding(
              padding: EdgeInsets.only(left: lineLeft),
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
          left: lineLeft,
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
              margin: EdgeInsets.only(left: lineLeft),
              color: lineColor,
            ),
          ],
        ),
      ));
      if (!isLastChild) pieces.add(halfVLine(top: false));
    }

    return SizedBox(
      width: width,
      child: Stack(clipBehavior: Clip.none, children: pieces),
    );
  }
}

/// 节点行：横向卡（缩略图 + 名 + 编号）+ 节点下方条件 chips，横排 /
/// 纵向树两形态共用。[dense] 放大密度：缩略图 48→56、卡内 padding
/// s→m，chips 缩进随之对齐到名称列。
class _EvolutionTile extends StatelessWidget {
  const _EvolutionTile({
    required this.node,
    required this.selected,
    required this.conditionLabels,
    this.dense = false,
  });

  final EvolutionNode node;
  final bool selected;
  final List<String> conditionLabels;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final thumbSize = dense ? _kThumbSizeDense : _kThumbSize;
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
              padding: EdgeInsets.all(dense ? AppSpacing.m : AppSpacing.s),
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
                  _NodeThumb(asset: node.thumbAsset, size: thumbSize),
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
              padding: EdgeInsets.only(
                left: thumbSize + AppSpacing.s,
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

/// 圆形缩略图（[size] 直径，内图四周留 2px 边距）；资产缺失回退占位图标。
class _NodeThumb extends StatelessWidget {
  const _NodeThumb({required this.size, this.asset});

  final double size;

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
                width: size - 4,
                height: size - 4,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => placeholder,
              ),
            ),
    );
  }
}
