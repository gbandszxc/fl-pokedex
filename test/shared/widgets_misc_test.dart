import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/shared/widgets/adaptive_scaffold_util.dart';
import 'package:fl_pokedex/shared/widgets/condition_chip.dart';
import 'package:fl_pokedex/shared/widgets/section_title.dart';

import 'test_utils.dart';

void main() {
  group('ConditionChip', () {
    testWidgets('secondaryContainer 底 + onSecondaryContainer 字', (tester) async {
      await tester.pumpWidget(
        wrapTheme(child: const ConditionChip(label: 'Lv.16')),
      );

      final container = tester.widget<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is ShapeDecoration,
        ),
      );
      final decoration = container.decoration! as ShapeDecoration;
      expect(decoration.color, AppColors.light.secondaryContainer);
      expect(
        tester.widget<Text>(find.text('Lv.16')).style?.color,
        AppColors.light.onSecondaryContainer,
      );
    });
  });

  group('SectionTitle', () {
    testWidgets('标题渲染，无 action；有 action 时展示在尾部', (tester) async {
      await tester.pumpWidget(
        wrapTheme(
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionTitle(title: '进化链'),
              SectionTitle(title: '招式', action: Text('查看全部')),
            ],
          ),
        ),
      );

      expect(find.text('进化链'), findsOneWidget);
      expect(find.text('招式'), findsOneWidget);
      expect(find.text('查看全部'), findsOneWidget);
    });
  });

  group('pagePaddingFor', () {
    Future<double> paddingOf(WidgetTester tester, double logicalWidth) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = Size(logicalWidth, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      late double value;
      await tester.pumpWidget(
        wrapTheme(
          child: Builder(
            builder: (context) {
              value = pagePaddingFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return value;
    }

    testWidgets('compact(<600) = 16 / medium(600–840) = 16 / expanded(≥840) = 24',
        (tester) async {
      expect(await paddingOf(tester, 400), 16);
      expect(await paddingOf(tester, 700), 16);
      expect(await paddingOf(tester, 900), 24);
    });
  });
}
