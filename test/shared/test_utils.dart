import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';

/// 设计稿常见种族值（喷火龙，总和 534，见 design-ui.md §4）。
const StatBlock kStatFixture = StatBlock(
  hp: 78,
  attack: 84,
  defense: 78,
  specialAttack: 109,
  specialDefense: 85,
  speed: 100,
);

/// 用琥珀图鉴主题包装被测组件。
Widget wrapTheme({
  required Widget child,
  Brightness brightness = Brightness.light,
  Size size = const Size(800, 600),
}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? buildLightTheme()
        : buildDarkTheme(),
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}

/// 取后代里第一个 Material（深度优先，最外层最先出现）。
Material firstDescendantMaterial(WidgetTester tester, Type widgetType) {
  return tester.widgetList<Material>(
    find.descendant(
      of: find.byType(widgetType),
      matching: find.byType(Material),
    ),
  ).first;
}
