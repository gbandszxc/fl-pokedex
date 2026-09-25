import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/shared/widgets/stat_radar.dart';

import 'test_utils.dart';

void main() {
  testWidgets('240×240 渲染：无异常且为单个 CustomPaint', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: StatRadar(stats: kStatFixture)),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(StatRadar),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.getSize(find.byType(StatRadar)), const Size(240, 240));
  });

  testWidgets('showValues：顶点数值小标由 painter 直绘（渲染无异常）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: StatRadar(stats: kStatFixture, showValues: true),
      ),
    );

    // 数值通过 TextPainter 画在 canvas 上，不产生 Text widget；
    // 以「无异常 + 正常布局尺寸」作为冒烟断言。
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(StatRadar)), const Size(240, 240));
  });

  testWidgets('小尺寸 + dark 主题渲染无异常（关键组件暗色跑一遍）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: StatRadar(stats: kStatFixture, size: 160, showValues: true),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
