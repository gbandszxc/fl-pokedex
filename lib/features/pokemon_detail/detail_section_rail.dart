import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme/theme.dart';

/// 锚点轨固定宽（design-ui.md §2：expanded 详情面板右侧常驻一条）。
/// 与 pokemon_detail_page 的 `_kArtworkHeightExpanded` 同例——一次性布局
/// 常量就地定义，不进 tokens.dart。
const double _kSectionRailWidth = 56;

/// 锚点图标尺寸（与 labelSmall 文字同级，读作「图标 + 短名」一枚标签）。
const double _kRailIconSize = 20;

/// 激活指示条宽（DESIGN.md §7 允许的细线 accent，≤2px）。
const double _kActiveIndicatorWidth = 2;

/// 跳转落点 / 高亮判定的统一余量：分区标题落在 pinned SliverAppBar
/// 之下 8px（AppSpacing.s）。
///
/// 两者同源是刻意的——点击某项后，目标分区恰好是「最后一个已顶到内容
/// 区顶部」的那一段，高亮立即落在被点项上，不会错位一段。
const double _kAnchorSlack = AppSpacing.s;

/// 像素对齐容差：滚动位置 / sliver 几何换算后的浮点差控制在这一档内，
/// 「滚到底」与「分区顶已到判定线」两处判定共用。
const double _kPixelEpsilon = 1;

/// 分区锚点的滚动锚定：持五段分区的挂载点，提供「跳到第 i 段」与
/// 「按当前滚动位置求激活段」。
///
/// 与 [DetailSectionRail] 分工：rail 只负责渲染与回传点击，滚动几何
/// （偏移换算、激活判定）留在这里。页面私有 State 持有一个实例；单元
/// 测试可用受控 CustomScrollView 驱动同一实现，不必复刻几何算法。
class DetailSectionAnchorScroll {
  /// 五段分区的挂载点（顺序同 [kDetailSectionAnchors]）：包在分区外层
  /// （KeyedSubtree）上，跳转与高亮都按分区顶部定位。
  final List<GlobalKey> sectionKeys = [
    for (final anchor in kDetailSectionAnchors)
      GlobalKey(debugLabel: 'detail_section_${anchor.label}'),
  ];

  /// 本帧是否已登记过激活段判定（同一帧多次滚动通知只判一次）。
  var _checkScheduled = false;

  /// 滚动监听入口（挂到 ScrollController 的 listener 上）。
  ///
  /// 滚动通知先于本帧布局到达：此刻各 sliver 的 paintOffset 还是上一帧的，
  /// 立即判定会慢一帧——滚动停止时高亮会停在错误的项上。因此统一等本帧
  /// 布局完成后再判定，变化时回调 [onActiveChanged]（回调里再 setState）。
  void handleScroll(
    ScrollController controller,
    ValueChanged<int> onActiveChanged,
  ) {
    if (_checkScheduled) {
      return;
    }
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      if (!controller.hasClients) {
        return;
      }
      onActiveChanged(activeIndexFor(controller));
    });
  }

  /// 跳到第 [index] 段：目标顶部落在 pinned SliverAppBar 之下
  /// [_kAnchorSlack] 处。
  ///
  /// 不用 `Scrollable.ensureVisible(alignment: 0)`：它把目标顶到视口最
  /// 顶端，会被 pinned AppBar 盖住，必须自己让出 AppBar 高度。
  /// 系统「关闭动画」（[MediaQuery.disableAnimationsOf]）时直接跳，与
  /// 立绘淡入等动效同一偏好。
  ///
  /// 分区未挂载（currentContext 为 null / renderObject 未附着）或滚动
  /// 尚未 attach 时静默忽略，不抛异常。
  void jumpTo(BuildContext context, ScrollController controller, int index) {
    if (!controller.hasClients) {
      return;
    }
    final dy = _dyFromViewportTop(index);
    if (dy == null) {
      return;
    }
    final position = controller.position;
    final target = (controller.offset + dy - kToolbarHeight - _kAnchorSlack)
        .clamp(0.0, position.maxScrollExtent);
    if (MediaQuery.disableAnimationsOf(context)) {
      controller.jumpTo(target);
      return;
    }
    controller.animateTo(
      target,
      duration: AppMotion.slow,
      curve: AppMotion.curve,
    );
  }

  /// 当前激活段：最后一个「标题已顶到内容可见区顶部」的分区；都还没顶到
  /// 时取第一段。
  ///
  /// 五段规模，线性倒查即可（每帧至多 5 次坐标换算，无需缓存）。
  int activeIndexFor(ScrollController controller) {
    if (!controller.hasClients) {
      return 0;
    }
    final position = controller.position;
    // 底部兜底：末段之后的内容不足以为它让出整个视口（maxScrollExtent
    // 先到），若仍按「顶到内容区顶部」判定，点「资料」会落到底部却高亮
    // 上一段。到底即认末段，跳转落点与高亮才自洽。
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - _kPixelEpsilon) {
      return kDetailSectionAnchors.length - 1;
    }
    for (var index = kDetailSectionAnchors.length - 1; index >= 0; index--) {
      final dy = _dyFromViewportTop(index);
      if (dy == null) {
        // 未挂载（惰性构建尚未落地）：视为尚未顶到，继续往前找。
        continue;
      }
      // dy 自视口顶起算，减去 pinned AppBar 高度才是内容可见区顶部；
      // 容差与跳转落点同量级，避免浮点差把落点判成上一段。
      if (dy - kToolbarHeight <= _kAnchorSlack + _kPixelEpsilon) {
        return index;
      }
    }
    return 0;
  }

  /// 第 [index] 段顶部相对滚动视口顶部的 dy（未 clamp）。
  ///
  /// 未挂载 / renderObject 未附着 / 不在滚动视口内时返回 null —— 调用方
  /// 据此静默跳过，不得抛异常。
  double? _dyFromViewportTop(int index) {
    if (index < 0 || index >= sectionKeys.length) {
      return null;
    }
    final box = sectionKeys[index].currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) {
      return null;
    }
    final viewport = RenderAbstractViewport.maybeOf(box);
    if (viewport == null || !viewport.attached) {
      return null;
    }
    // 视口自身即参照系，取它的全局 top 而不是假设为 0：双栏嵌入时面板
    // 上沿还有壳层内边距。RenderAbstractViewport 是 interface class
    // （不能与 RenderBox 互推），走 RenderObject.getTransformTo 取原点。
    final viewportTop = MatrixUtils.transformPoint(
      viewport.getTransformTo(null),
      Offset.zero,
    ).dy;
    return box.localToGlobal(Offset.zero).dy - viewportTop;
  }
}

/// 分区锚点：短名 + 完整名 + 图标。
@immutable
class DetailSectionAnchor {
  const DetailSectionAnchor({
    required this.label,
    required this.shortLabel,
    required this.icon,
  });

  /// 完整名（Tooltip 与无障碍标签）。
  final String label;

  /// 轨道上显示的短名（两字：轨道仅 56 宽）。
  final String shortLabel;

  final IconData icon;
}

/// 详情单页五段锚点，顺序与页面分区自上而下一致。
///
/// 图标同属一套线性风格（outlined），不复用属性色语义。
const List<DetailSectionAnchor> kDetailSectionAnchors = [
  DetailSectionAnchor(
    label: '图鉴说明',
    shortLabel: '说明',
    icon: Icons.menu_book_outlined,
  ),
  DetailSectionAnchor(
    label: '种族值',
    shortLabel: '种族',
    icon: Icons.bar_chart,
  ),
  DetailSectionAnchor(
    label: '进化',
    shortLabel: '进化',
    icon: Icons.account_tree_outlined,
  ),
  DetailSectionAnchor(
    label: '招式',
    shortLabel: '招式',
    icon: Icons.bolt_outlined,
  ),
  DetailSectionAnchor(
    label: '资料',
    shortLabel: '资料',
    icon: Icons.info_outline,
  ),
];

/// expanded 详情单页右侧的分区锚点轨（design-ui.md §2）。
///
/// 单页滚动下招式段很长，滚到「资料」代价高；常驻轨道把跳转降为 O(1)，
/// 并用高亮回答「现在在哪一段」。只在 expanded 单页分支出现——
/// compact/medium 用页签（见 pokemon_detail_page）。
class DetailSectionRail extends StatelessWidget {
  const DetailSectionRail({
    super.key,
    required this.activeIndex,
    required this.onSelected,
  });

  /// 当前激活段序号（[kDetailSectionAnchors] 下标）。
  final int activeIndex;

  /// 点按某项回传其下标。
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      // 与 SliverAppBar 同色（surface）：横向不出现色块断层。同时作为
      // 各项 InkWell 的 ink 承载面——hover 底色画在它上面、图标文字之下，
      // 若换成不透明的 ColoredBox 会把 ink 盖掉。
      color: scheme.surface,
      child: SizedBox(
        width: _kSectionRailWidth,
        child: DecoratedBox(
          // 只画左边 1px 分隔线（不铺底色，理由同上）。
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: scheme.outlineVariant, width: 1),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, anchor) in kDetailSectionAnchors.indexed) ...[
                if (index > 0) const SizedBox(height: AppSpacing.xs),
                _RailItem(
                  anchor: anchor,
                  isActive: index == activeIndex,
                  onTap: () => onSelected(index),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 单枚锚点：图标 + 短名，激活态 primary 着色 + 左缘 2px 指示条。
class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.anchor,
    required this.isActive,
    required this.onTap,
  });

  final DetailSectionAnchor anchor;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foreground = isActive ? scheme.primary : scheme.onSurfaceVariant;
    // 短名与图标同色，激活态整体读作一枚「已选中」标签（DESIGN.md §6）。
    final labelStyle = (textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: foreground,
    );

    return Semantics(
      button: true,
      selected: isActive,
      // 短名只是轨道上的占位；无障碍报读与 hover 提示都用完整名。
      label: anchor.label,
      child: Tooltip(
        message: anchor.label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.input),
          hoverColor: scheme.surfaceContainerHigh,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.s,
                  horizontal: AppSpacing.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(anchor.icon, size: _kRailIconSize, color: foreground),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      anchor.shortLabel,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _kActiveIndicatorWidth,
                  child: ColoredBox(color: scheme.primary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
