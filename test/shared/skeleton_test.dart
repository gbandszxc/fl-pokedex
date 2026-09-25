import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/shared/widgets/skeleton.dart';

import 'test_utils.dart';

void main() {
  testWidgets('SkeletonBox 脉冲：透明度随时间变化（200ms 周期）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: const Skeleton(
          child: SkeletonBox(width: 100, height: 20),
        ),
      ),
    );

    final opacityFinder = find.byType(Opacity);
    final start = tester.widget<Opacity>(opacityFinder).opacity;
    await tester.pump(const Duration(milliseconds: 100));
    final mid = tester.widget<Opacity>(opacityFinder).opacity;

    expect(start, lessThan(1.0));
    expect(mid, greaterThan(start));
  });

  testWidgets('系统关闭动画：透明度恒为 1（可关）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Skeleton(
            child: SkeletonBox(width: 100, height: 20),
          ),
        ),
      ),
    );

    final opacityFinder = find.byType(Opacity);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Opacity>(opacityFinder).opacity, 1.0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Opacity>(opacityFinder).opacity, 1.0);
  });

  testWidgets('SkeletonGrid / SkeletonList 便捷组合冒烟', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: Column(
          children: [
            Expanded(
              child: SkeletonGrid(itemCount: 6, crossAxisCount: 3),
            ),
            Expanded(
              child: SkeletonList(itemCount: 3, shrinkWrap: false),
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
