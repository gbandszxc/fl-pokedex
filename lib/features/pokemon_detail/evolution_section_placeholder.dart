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

/// 横排卡身高度（尺寸推算值，非 token 管辖的几何常数，风格同
/// evolution_layout.dart 的布局常数）：卡内上下 padding 各
/// AppSpacing.s(8) + 缩略图 48（横排卡不走 dense，固定 [_kThumbSize]）。
/// 名称 + 编号两行文字（labelLarge / bodySmall）合计约 34，textScale
/// 放大后仍小于 48，卡身由缩略图定高。
const double _kLinearCardHeight = AppSpacing.s * 2 + _kThumbSize;

/// 横排箭头图标尺寸。
const double _kArrowIconSize = 24;

/// 箭头顶部内边距：横排行改顶对齐后，箭头列顶部留出与 [_EvolutionTile]
/// 相同的外层 vertical xs（4），再下移半个「卡身高 − 图标高」，使
/// 图标垂直中心精确落在卡身中心：4 + (64 − 24) / 2 = 24。
const double _kArrowTopInset =
    AppSpacing.xs + (_kLinearCardHeight - _kArrowIconSize) / 2;

/// 进化分区（design-ui.md §5）：数据定形态的三分支渲染——
/// - 分支链 → 纵向树（├ / └ 导引线 + 条件 chips；本地宽 ≥840
///   expanded 放大密度，形态结构不变）：缩进承载分支结构；
/// - 纯线性链且分区本地宽 ≥ 估算行宽 → 横排一行（节点卡列 +
///   条件 chips 与箭头列交替）；
/// - 纯线性链且宽不足 → 垂直时间线（节点卡自上而下，连接段为
///   连续竖线 + 条件 chips）：线性链每层仅一条边，缩进树的 └ 阶梯
///   不携带任何分支信息，视觉支离破碎，故窄面板不再回退缩进树。
/// 形态决策取 [LayoutBuilder] 的分区本地宽而非窗口宽：双栏
/// master-detail 的窄详情面板自动回退纵向形态。无进化链显示空态；
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
          // 三分支决策：分支链走纵向树（缩进承载分支结构）；线性链按
          // 本地宽二选一——放得下估算行宽走横排一行，放不下走垂直
          // 时间线（缩进树不再承接线性链：每层仅一条边，└ 阶梯不携带
          // 分支信息）。
          final rows = flattenEvolutionTree(tree);
          if (!isLinearEvolutionChain(tree)) {
            return _VerticalTree(
              tree: tree,
              currentSpeciesId: speciesId,
              dense: windowSizeFor(maxWidth) == WindowSize.expanded,
            );
          }
          // 横排拦截：行内不做 Wrap / FittedBox / 横向滚动。节点卡宽
          // 预算用校准过的 [_kLinearNodeCardWidth]（理由见其注释）。
          final fitsLinearRow = maxWidth >=
              linearChainRowWidth(
                rows.length,
                nodeMinWidth: _kLinearNodeCardWidth,
              );
          return fitsLinearRow
              ? _LinearChainRow(tree: tree, currentSpeciesId: speciesId)
              : _LinearTimeline(tree: tree, currentSpeciesId: speciesId);
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
      // 顶对齐：三张卡身结构相同（等高 [_kLinearCardHeight]），顶对齐
      // 即卡身水平对齐，条件 chips 只向卡下方延伸、不参与对齐。此前
      // 行内居中会让带 chips 的列整体下移，卡身中心错开约 12px
      // （实机缺陷：横排行文字没对齐）。
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0)
            SizedBox(
              width: _kArrowColumnWidth,
              // 箭头对齐卡身垂直中心：顶部先补齐 [_EvolutionTile] 的
              // 外层 vertical xs，再下移 [_kArrowTopInset]；Center 在
              // 剩余空间内水平居中（列无固定高，收缩到图标尺寸）。
              child: Padding(
                padding: const EdgeInsets.only(top: _kArrowTopInset),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward,
                    size: _kArrowIconSize,
                    color: scheme.onSurfaceVariant,
                  ),
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

/// 时间线竖线的水平中轴 = 卡身内缩略图中心：卡内 padding s(8) +
/// 缩略图半径（compact 48 / 2 = 24）= 32。时间线不走 dense（时间线
/// 只出现在横排门槛之下，见 [_EvolutionBody] 的三分支决策），恒按
/// compact 缩略图 [_kThumbSize] 推算。尺寸推算值，非 token 管辖的
/// 几何常数，风格同 [_kLinearCardHeight]。
const double _kTimelineLineCenter = AppSpacing.s + _kThumbSize / 2;

/// 线性链垂直时间线（design-ui.md §5 横排行之外的窄面板形态）：节点卡
/// 自上而下排布，相邻两卡之间为「连接段」——一条 2px 连续竖线（与
/// 纵向树导引线同色 outlineVariant）+ 右侧该边条件 chips。窄面板回退
/// 不再用缩进树：线性链每层只有一条边，└ 缩进阶梯不携带分支信息；
/// 时间线的连续竖线直接表达「同一链上的下一步」。
///
/// 节点卡复用 [_EvolutionTile]（条件 chips 传空——条件语义移到连接段，
/// 挂在两条卡之间的边上）。不叠加方向箭头：垂直排布 + 贯穿连接段的
/// 连续竖线已无歧义表达自上而下演进（时间轴隐喻自带方向），且与纵向
/// 树「纵向形态不画箭头」的视觉约定一致；若叠图标需垫底色让位，反而
/// 打断线的连续感并引入多余颜色耦合。
class _LinearTimeline extends StatelessWidget {
  const _LinearTimeline({required this.tree, required this.currentSpeciesId});

  final EvolutionTree tree;
  final int currentSpeciesId;

  @override
  Widget build(BuildContext context) {
    // 线性链的先序展开即链序：第 i 行（i > 0）的连接段挂第 i 条边的
    // 条件 chips。
    final rows = flattenEvolutionTree(tree);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0)
            _TimelineConnector(
              conditionLabels: evolutionConditionLabels(row.edgeFromParent!),
            ),
          _EvolutionTile(
            node: row.node,
            selected: row.node.speciesId == currentSpeciesId,
            conditionLabels: const <String>[],
          ),
        ],
      ],
    );
  }
}

/// 时间线连接段：定宽线列（宽 = 竖线中轴 [_kTimelineLineCenter]，2px
/// 竖线在中轴上左移 1px 居中，风格同 [_GuideColumn] 的 lineLeft）+
/// chips 列。IntrinsicHeight + stretch 让两列等高、竖线贯穿连接段
/// 全部高度（一笔到底，不允许线段断点）；chips 左缘固定「线列右
/// s(8)」，多条边的 chips 天然左对齐。
class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector({required this.conditionLabels});

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
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: _kTimelineLineCenter - 1,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: ColoredBox(color: scheme.outlineVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s,
                top: AppSpacing.xs,
                bottom: AppSpacing.xs,
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
          ),
        ],
      ),
    );
  }
}

/// 纵向树：根在上，子节点逐级缩进（├ / └ 导引线 + 条件 chips）。
/// 只服务分支树（伊布 8 分支、奇鲁莉安型等）：缩进承载分支结构；
/// 线性链改走时间线 / 横排行（缩进对单边链无信息量，见
/// [_LinearTimeline]）。[dense] 为 true（分区本地宽 ≥840，
/// [WindowSize.expanded]）时放大密度：缩略图 56、卡内 padding m、
/// 导引列 32，形态结构不变。
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
              // 祖先贯穿列（非拐角）：该层祖先竖线是否延续穿过本行。
              // 线性链中间行此处为 true（祖先子树还有后续行），竖线
              // 不再断连。
              showVLine: level < row.depth - 1 && row.guides[level],
              // 拐角列（本节点的 ├/└）：自身子树还有后续行时拐角竖线
              // 向下半行延续，衔接下一行同列导引；否则是 └ 端点。
              showDropLine: row.hasDescendantRows,
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
/// - 非拐角列（祖先列）：[showVLine] 为 true 画贯穿整行的竖线（该层
///   祖先的子树在本行之后还有行），为 false 留空（└ 端点之下）。
/// - 拐角列（├ / └）：上半竖线 + 横线常画；[showDropLine] 为 true 时
///   加下半竖线（├ 形，衔接下一行同列导引），为 false 是 └ 端点。
///
/// 用 Align + FractionallySizedBox 取半高（IntrinsicHeight 场景下
/// LayoutBuilder 不支持内在尺寸计算，不可用）。
class _GuideColumn extends StatelessWidget {
  const _GuideColumn({
    required this.width,
    required this.isElbow,
    required this.showVLine,
    required this.showDropLine,
    required this.lineColor,
  });

  final double width;

  final bool isElbow;
  final bool showVLine;
  final bool showDropLine;
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
      // 祖先导引：祖先子树在本行之后没有行时（└ 端点之下）不再画线。
      if (showVLine) {
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
      if (showDropLine) pieces.add(halfVLine(top: false));
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
