import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/shared/widgets/type_badge.dart';

import 'test_utils.dart';

void main() {
  testWidgets('fire：属性底色 + 白字（light）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: const TypeBadge(type: 'fire')),
    );

    final material = firstDescendantMaterial(tester, TypeBadge);
    expect(material.color, AppColors.typeColors['fire']);

    final text = tester.widget<Text>(find.text('火'));
    expect(text.style?.color, Colors.white);
  });

  testWidgets('electric：属性底色 + 深字（DESIGN.md §2 前景表）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: const TypeBadge(type: 'electric')),
    );

    expect(firstDescendantMaterial(tester, TypeBadge).color,
        AppColors.typeColors['electric']);
    expect(
      tester.widget<Text>(find.text('电')).style?.color,
      AppColors.darkInk,
    );
  });

  testWidgets('未知 identifier：回退中性灰（light = outline，白字）', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: const TypeBadge(type: 'unknown-type')),
    );

    final material = firstDescendantMaterial(tester, TypeBadge);
    expect(material.color, AppColors.light.outline);
    expect(
      tester.widget<Text>(find.text('unknown-type')).style?.color,
      typeFgOn(AppColors.light.outline),
    );
  });

  testWidgets('未知 identifier：dark 主题回退 dark outline（关键组件暗色跑一遍）',
      (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: const TypeBadge(type: 'unknown-type'),
      ),
    );

    expect(firstDescendantMaterial(tester, TypeBadge).color,
        AppColors.dark.outline);
  });

  testWidgets('尺寸档：sm 高20字11 / md 高26字13', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TypeBadge(type: 'water', size: TypeBadgeSize.sm),
            TypeBadge(type: 'water'),
          ],
        ),
      ),
    );

    final texts = tester.widgetList<Text>(find.text('水')).toList();
    expect(texts, hasLength(2));
    expect(texts[0].style?.fontSize, 11);
    expect(texts[1].style?.fontSize, 13);

    expect(tester.getSize(find.byType(TypeBadge).at(0)).height, 20);
    expect(tester.getSize(find.byType(TypeBadge).at(1)).height, 26);
  });

  testWidgets('onTap 可点击', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapTheme(
        child: TypeBadge(
          type: 'grass',
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.byType(TypeBadge));
    expect(tapped, isTrue);
  });
}
