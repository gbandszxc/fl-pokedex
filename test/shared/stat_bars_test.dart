import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/shared/widgets/stat_bars.dart';

import 'test_utils.dart';

void main() {
  testWidgets('渲染 6 行标签 + 数值 + 总和徽章 534', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(width: 360, child: StatBars(stats: kStatFixture)),
      ),
    );

    for (final label in const ['HP', '攻击', '防御', '特攻', '特防', '速度']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final value in const ['84', '109', '85', '100']) {
      expect(find.text(value), findsOneWidget);
    }
    // 78 出现两次：HP 与防御。
    expect(find.text('78'), findsNWidgets(2));
    expect(find.text('总和 534'), findsOneWidget);
  });

  testWidgets('compact 档渲染无异常、行数一致', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: SizedBox(
          width: 280,
          child: StatBars(stats: kStatFixture, compact: true),
        ),
      ),
    );

    expect(find.text('总和 534'), findsOneWidget);
    expect(find.byType(StatBars), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark 主题渲染无异常（关键组件暗色跑一遍）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: SizedBox(width: 360, child: StatBars(stats: kStatFixture)),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
