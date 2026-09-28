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

/// Tooltip 弹出前的悬停等待：300ms（与 AppMotion.slow 同档的一次性数值，
/// 不属于动效序列故不进 tokens）。
///
/// 为什么不用默认 0ms：锚点轨是窄条上的纵向列表，鼠标横向扫过轨道去点
/// 别处时，0ms 即弹会让提示沿轨迹连环闪现；只有明确停留 300ms 才触发。
const Duration _kRailTooltipWait = Duration(milliseconds: 300);

/// 跳转落点 / 高亮判定的统一余量：分区标题落在 pinned SliverAppBar
/// 之下 8px（AppSpacing.s）。
///
/// 两者同源是刻意的——点击某项后，目标分区恰好是「最后一个已顶到内容
/// 区顶部」的那一段，高亮立即落在被点项上，不会错位一段。
const double _kAnchorSlack = AppSpacing.s;

/// 像素对齐容差：滚动位置 / sliver 几何换算后的浮点差控制在这一档内，
/// 「滚到底」与「分区顶已到判定线」两处判定共用。
const double _kPixelEpsilon = 1;

/// pinned SliverAppBar 实际占据的高度：toolbar + 系统顶部内边距。
///
/// SliverAppBar 默认 primary = true，其 collapse 高度含 MediaQuery 顶部 inset
/// （状态栏 / 刘海）；本页 Scaffold 无 appBar，body 保留该 inset 并原样传给
/// 内部 SliverAppBar，因此遮挡带是 kToolbarHeight + padding.top。跳转落点与
/// 高亮判定线都必须按它让位，否则在带状态栏的平台（Android 平板 / iPad）上
/// 跳转后分区标题会落进 AppBar 遮挡区。
double pinnedDetailHeaderHeight(BuildContext context) =>
    kToolbarHeight + MediaQuery.paddingOf(context).top;

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

  /// 本页 pinned header 的实际高度（见 [pinnedDetailHeaderHeight]）：
  /// 页面在 didChangeDependencies 里按当前 MediaQuery 顶部 inset 刷新，
  /// 状态栏出现 / 消失（旋转、全屏）后跳转与高亮随之对齐。
  var pinnedHeaderHeight = kToolbarHeight;

  /// 本帧是否已登记过激活段判定（同一帧多次滚动通知只判一次）。
  var _checkScheduled = false;

  /// 钉定段：程序性跳转后高亮固定在被点项。null = 未钉定（滚动跟随）。
  ///
  /// 为什么需要钉定：目标分区之后的内容可能不足一屏，跳转落点被
  /// maxScrollExtent 截断到页面底部——此时滚动跟随口径的「到底认末段」
  /// 会把高亮错给末段（点「招式」亮「资料」）。跳转一发起就钉住被点项，
  /// 直到用户手动滚动才交还跟随（解除条件见 [handleScrollNotification]）。
  int? _pinnedIndex;

  /// 尚未归还的程序性跳转计数：jumpTo 发起一次记一层，对应滚动活动的
  /// ScrollEnd 归还一层。
  ///
  /// 为什么用计数不用布尔：连点锚点时新 animateTo 会打断旧动画，被打断的
  /// 旧动画也各有一次 ScrollEnd（相对新动画的 Start 何时到达并无保证）；
  /// 布尔会被旧动画的结束提前复位，新跳转的滚动就被误判为用户滚动。
  int _programmaticDepth = 0;

  /// 滚动通知入口（挂在滚动视口外的 NotificationListener 上；返回 false
  /// 不拦截冒泡）。
  ///
  /// 为什么从 ScrollController.addListener 换成通知：钉定要区分「用户
  /// 拖拽」与「跳转动画自己产生的滚动」，controller listener 只看得到
  /// 像素变化，[ScrollNotification] 的 dragDetails 与 Start/End 活动边界
  /// 才带活动来源。通知先于本帧布局到达的时序问题与原 controller
  /// listener 相同：统一等本帧布局完成后再判定，变化时回调
  /// [onActiveChanged]（回调里再 setState）。
  bool handleScrollNotification(
    ScrollNotification notification,
    ScrollController controller,
    ValueChanged<int> onActiveChanged,
  ) {
    if (notification.depth != 0) {
      // 只认本视口（depth 0）的滚动：分区内部的嵌套可滚动（横向 chips 等）
      // 不得解除钉定，也不触发纵向高亮判定。
      return false;
    }
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        // 用户拖拽：随时解除钉定，高亮交还滚动跟随。
        _pinnedIndex = null;
      } else if (_programmaticDepth == 0) {
        // 非跳转发起的新滚动活动（滚轮 / 滚动条）：同样解除。跳转动画
        // 进行中自身的 Start 不会走到这里（计数未归零）。
        _pinnedIndex = null;
      }
    } else if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        _pinnedIndex = null; // 拖拽中途的更新（Start 已解除，幂等兜底）。
      }
    } else if (notification is ScrollEndNotification) {
      if (_programmaticDepth > 0) {
        _programmaticDepth--; // 动画结束；被打断的动画其 End 亦会到达。
      }
    }
    if (_pinnedIndex != null) {
      // 钉定期间高亮停在被点项：滚动跟随计算（含跳转动画的滚动）一律忽略。
      return false;
    }
    _scheduleCheck(controller, onActiveChanged);
    return false;
  }

  /// 滚动跟随的激活段判定：推迟到本帧布局完成后执行（见
  /// [handleScrollNotification] 的时序说明）。
  void _scheduleCheck(
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
      // 调度与回调之间可能已再次钉定（同一帧内先滚后点）：钉定优先，
      // 不得用跟随口径覆盖刚生效的被点项高亮。
      if (_pinnedIndex != null) {
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
  /// 尚未 attach 时静默忽略，不抛异常——这些提前返回的路径**不钉定**：
  /// 没有跳转发生，高亮与滚动跟随维持原状。
  ///
  /// 跳转真正发起时立即把高亮置为被点项（[onActiveChanged]）并进入钉定
  /// 状态：目标偏移可能被 maxScrollExtent 截断（目标之后内容不足一屏），
  /// 落底后按滚动跟随计算必然错改高亮，因此动画 / 直接到位期间的滚动
  /// 一律不参与判定，直到用户手动滚动才恢复跟随。
  void jumpTo(
    BuildContext context,
    ScrollController controller,
    int index,
    ValueChanged<int> onActiveChanged,
  ) {
    if (!controller.hasClients) {
      return;
    }
    final dy = _dyFromViewportTop(index);
    if (dy == null) {
      return;
    }
    final position = controller.position;
    final target = (controller.offset + dy - pinnedHeaderHeight - _kAnchorSlack)
        .clamp(0.0, position.maxScrollExtent);
    _pinnedIndex = index;
    _programmaticDepth++;
    onActiveChanged(index);
    if (MediaQuery.disableAnimationsOf(context)) {
      // 直接到位：Start/End 在本次调用栈内同步到达，End 归还计数后钉定
      // 仍在（用户之后再动才解除）。
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
      // dy 自视口顶起算，减去 pinned header 的实际高度（toolbar + 顶部
      // inset）才是内容可见区顶部；容差与跳转落点同量级，避免浮点差把
      // 落点判成上一段。
      if (dy - pinnedHeaderHeight <= _kAnchorSlack + _kPixelEpsilon) {
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
                // 项间距 s(8)：xs(4) 时相邻项几乎贴着（实机圈注），放宽一档
                // 呼吸感；轨道宽 56 与项内规格不变，Column 纵向居中不变。
                if (index > 0) const SizedBox(height: AppSpacing.s),
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
        // 向上弹出（默认 preferBelow: true 向下弹）：项间距仅 8px，向下弹
        // 的悬浮提示会盖住正下方相邻项（实机圈注「存在遮挡」）。放不下时
        // Flutter 自动回落向下，顶项「说明」不受影响。
        preferBelow: false,
        // 掠过不即弹：悬停满等待时长才出现（见 _kRailTooltipWait）。
        waitDuration: _kRailTooltipWait,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.input),
          hoverColor: scheme.surfaceContainerHigh,
          child: Stack(
            // 内容列（非定位子项）在整轨宽内水平居中：本 Stack 被父 Column
            // 的 stretch 拉到轨宽 56，而「图标 + 短名」只有固有宽（约 30px），
            // 默认 topLeft 对齐会把内容贴在轨左缘（实机反馈「贴左没居中」）。
            // center 让内容落在轨中线上；激活指示条是定位子项（left: 0），
            // 不参与 alignment，仍贴轨左缘。
            alignment: Alignment.center,
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
