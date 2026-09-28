// Tristate 只从 dart:ui 暴露（SemanticsNode.flagsCollection 用三态而非 bool）。
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/features/pokemon_detail/detail_section_rail.dart';

import '../../shared/test_utils.dart';

/// 试验台每段区块高：远高于视口，滚过一段必然把下一段顶过判定线。
const double _kBlockHeight = 400;

/// 默认挂载段数（与 [kDetailSectionAnchors] 等长；首条用例断言两者同步）。
const int _kSectionCount = 5;

/// 受控试验台：pinned SliverAppBar + [sectionCount] 段高分区块 + 右侧
/// 锚点轨，接线方式与 pokemon_detail_page 的 `_ExpandedDetailBody` 一致
/// （同一 [DetailSectionAnchorScroll]）。
///
/// [sectionCount] < 5 用来复现「目标分区尚未挂载」——轨道仍在，但
/// 对应的 GlobalKey 没有挂载点。
class _RailHarness extends StatefulWidget {
  const _RailHarness({this.sectionCount = _kSectionCount});

  final int sectionCount;

  @override
  State<_RailHarness> createState() => _RailHarnessState();
}

class _RailHarnessState extends State<_RailHarness> {
  final ScrollController controller = ScrollController();
  final DetailSectionAnchorScroll anchors = DetailSectionAnchorScroll();
  var activeIndex = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleScroll() => anchors.handleScroll(controller, _setActive);

  void _setActive(int index) {
    if (mounted && index != activeIndex) {
      setState(() => activeIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return wrapTheme(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CustomScrollView(
              controller: controller,
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  automaticallyImplyLeading: false,
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      for (var index = 0; index < widget.sectionCount; index++)
                        KeyedSubtree(
                          key: anchors.sectionKeys[index],
                          child: SizedBox(
                            height: _kBlockHeight,
                            // 区块文案避开锚点短名，保证 find.text 无二义。
                            child: Text('第 $index 段'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DetailSectionRail(
            activeIndex: activeIndex,
            onSelected: (index) => anchors.jumpTo(context, controller, index),
          ),
        ],
      ),
    );
  }
}

void main() {
  Future<_RailHarnessState> pumpHarness(
    WidgetTester tester, {
    int sectionCount = _kSectionCount,
  }) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(_RailHarness(sectionCount: sectionCount));
    await tester.pumpAndSettle();
    return tester.state<_RailHarnessState>(find.byType(_RailHarness));
  }

  DetailSectionRail rail(WidgetTester tester) =>
      tester.widget<DetailSectionRail>(find.byType(DetailSectionRail));

  testWidgets('五段锚点：短名与完整名 Tooltip 齐备，轨道固定宽 56', (tester) async {
    await pumpHarness(tester);

    // 试验台默认段数与锚点表同步（否则挂载点错位，后续用例失真）。
    expect(kDetailSectionAnchors.length, _kSectionCount);
    for (final anchor in kDetailSectionAnchors) {
      // 短名两字（轨道仅 56 宽，放不下完整名）。
      expect(anchor.shortLabel.length, 2);
      expect(find.text(anchor.shortLabel), findsOneWidget);
      // 完整名走 Tooltip（hover / 长按）与无障碍标签。
      expect(find.byTooltip(anchor.label), findsOneWidget);
    }
    expect(
      tester.getSize(find.byType(DetailSectionRail)).width,
      56,
      reason: '锚点轨固定宽 56（一次性布局常量）',
    );
  });

  testWidgets('点击锚点：滚动到位且目标顶部落在 pinned AppBar 之下 8px', (tester) async {
    final state = await pumpHarness(tester);
    expect(state.controller.offset, 0);

    await tester.tap(find.text('招式')); // 第 4 段（下标 3）
    await tester.pumpAndSettle();

    expect(state.controller.offset, greaterThan(0));
    final viewportTop = tester.getRect(find.byType(CustomScrollView)).top;
    final blockTop = tester.getRect(find.byKey(state.anchors.sectionKeys[3])).top;
    // 目标顶 = 视口顶 + AppBar(kToolbarHeight) + 8px 余量：标题不被 pinned
    // AppBar 盖住，也不是 Scrollable.ensureVisible(alignment: 0) 的顶端对齐。
    expect(
      blockTop - viewportTop,
      moreOrLessEquals(kToolbarHeight + AppSpacing.s, epsilon: 1),
    );
    // 落点即激活项：点击后高亮不落后一段。
    expect(rail(tester).activeIndex, 3);
  });

  testWidgets('滚动越段：激活项随滚动切换，到底兜底到末段', (tester) async {
    final state = await pumpHarness(tester);
    expect(rail(tester).activeIndex, 0);

    // 滚过第 2 段（下标 1）的判定线。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(rail(tester).activeIndex, 1);
    expect(state.anchors.activeIndexFor(state.controller), 1);

    // 直到底部：末段之后没有足够内容把它顶到内容区顶部（maxScrollExtent
    // 先到），高亮兜底在末段。
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(
      state.controller.offset,
      moreOrLessEquals(state.controller.position.maxScrollExtent, epsilon: 1),
    );
    expect(rail(tester).activeIndex, kDetailSectionAnchors.length - 1);
  });

  testWidgets('目标分区未挂载：跳转静默忽略，不抛异常', (tester) async {
    // 只挂载前两段：下标 4（资料）没有挂载点。
    final state = await pumpHarness(tester, sectionCount: 2);

    state.anchors.jumpTo(
      tester.element(find.byType(DetailSectionRail)),
      state.controller,
      4,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.controller.offset, 0);

    // 轨道照常渲染，点击同一路径（jumpTo → key 无 currentContext）。
    await tester.tap(find.text('资料'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(state.controller.offset, 0);
    expect(state.anchors.activeIndexFor(state.controller), 0);
  });

  testWidgets('系统关闭动画：单帧内直接到位，不播 AppMotion.slow', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final state = await pumpHarness(tester);
    await tester.tap(find.text('招式'));
    // 一个泵帧：走动画的话此时才刚离开起点。
    await tester.pump();
    // 目标 = 第 4 段区块顶（56 + 3×400）− AppBar 56 − 8px 余量。
    expect(
      state.controller.offset,
      moreOrLessEquals(3 * _kBlockHeight - AppSpacing.s, epsilon: 1),
      reason: '关闭动画时应直接落到「招式」标题贴 AppBar 之下 8px 处',
    );
  });

  testWidgets('激活项以完整名暴露 button / selected 语义', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpHarness(tester);

    // 节点 label 是「完整名 + 短名」（Tooltip 的 Semantics 与短名文本合并），
    // 故按完整名做前缀匹配。
    Finder anchor(String label) => find.bySemanticsLabel(RegExp('^$label'));

    final active = tester.getSemantics(anchor('图鉴说明'));
    expect(active.flagsCollection.isButton, isTrue);
    expect(active.flagsCollection.isSelected, Tristate.isTrue);
    // 非激活项显式标注为未选中（selected: false），不是「无此状态」。
    expect(
      tester.getSemantics(anchor('资料')).flagsCollection.isSelected,
      Tristate.isFalse,
    );

    // 激活态跟随跳转更新。
    await tester.tap(find.text('资料'));
    await tester.pumpAndSettle();
    expect(
      tester.getSemantics(anchor('资料')).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    // 语义句柄须在测试体末尾释放（校验先于 tearDown 执行）。
    semantics.dispose();
  });
}
