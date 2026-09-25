import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/shared/widgets/adaptive_scaffold_util.dart';

/// 骨架加载作用域：提供一个共享的透明度脉冲相位，避免每个骨架块各建
/// 一个动画控制器（一个网格几十个块时开销可观）。
///
/// 脉冲周期 [AppMotion.pulse]（200ms，DESIGN.md §6「≤200ms 循环可关」）；
/// 系统开启「减弱动态效果」（`MediaQuery.disableAnimationsOf`）时静止。
/// 骨架底色用 surfaceContainer，不做 shimmer 斜纹（DESIGN.md §7）。
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  /// 当前脉冲不透明度（无作用域时恒为 1，骨架静态显示）。
  static double phaseOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_SkeletonScope>();
    return scope?.opacity ?? 1.0;
  }

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  /// 脉冲谷值：surfaceContainer 在页面底上轻微变浅，克制不闪烁。
  static const double _minOpacity = 0.55;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.pulse,
  );

  late final Animation<double> _opacity = Tween<double>(
    begin: _minOpacity,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _controller.repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, _) => _SkeletonScope(
        opacity: _opacity.value,
        child: widget.child,
      ),
    );
  }
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.opacity, required super.child});

  final double opacity;

  @override
  bool updateShouldNotify(_SkeletonScope oldWidget) =>
      oldWidget.opacity != opacity;
}

/// 骨架块：surfaceContainer 圆角色块，跟随最近 [Skeleton] 作用域脉冲。
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppRadius.input)),
  });

  final double? width;
  final double? height;

  /// 默认取 [AppRadius.input]（文本块/输入块的圆角惯例）。
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: Skeleton.phaseOf(context),
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
      ),
    );
  }
}

/// 网格骨架：按 design-ui.md §1 卡片结构（图块 + 两行文字条）手绘形状。
class SkeletonGrid extends StatelessWidget {
  const SkeletonGrid({
    super.key,
    required this.itemCount,
    this.crossAxisCount = 3,
    this.shrinkWrap = false,
    this.physics,
  });

  final int itemCount;
  final int crossAxisCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final pad = pagePaddingFor(context);
    return Skeleton(
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, pad, AppSpacing.m),
        mainAxisSpacing: AppSpacing.m,
        crossAxisSpacing: AppSpacing.m,
        childAspectRatio: 0.78,
        shrinkWrap: shrinkWrap,
        physics: physics,
        children: List.generate(itemCount, (_) => const _SkeletonCardCell()),
      ),
    );
  }
}

class _SkeletonCardCell extends StatelessWidget {
  const _SkeletonCardCell();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SkeletonBox(
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadius.card)),
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        const SkeletonBox(height: 14, width: 72),
        const SizedBox(height: AppSpacing.xs),
        const SkeletonBox(height: 12, width: 48),
      ],
    );
  }
}

/// 列表骨架：按 design-ui.md §1 行结构（圆形 thumb + 两行文字条）手绘形状。
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    required this.itemCount,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  final int itemCount;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// 缺省上下 [AppSpacing.m]。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.builder(
        itemCount: itemCount,
        shrinkWrap: shrinkWrap,
        physics: physics,
        padding: padding ?? const EdgeInsets.symmetric(vertical: AppSpacing.m),
        itemBuilder: (_, __) => const _SkeletonTileCell(),
      ),
    );
  }
}

class _SkeletonTileCell extends StatelessWidget {
  const _SkeletonTileCell();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SkeletonBox(
            width: 48,
            height: 48,
            borderRadius: BorderRadius.all(Radius.circular(999)),
          ),
          const SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(height: 14, width: 120),
                const SizedBox(height: AppSpacing.xs),
                FractionallySizedBox(
                  widthFactor: 0.6,
                  child: const SkeletonBox(height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
