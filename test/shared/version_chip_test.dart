import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/shared/widgets/version_chip.dart';

import 'test_utils.dart';

void main() {
  testWidgets('选中态：primary 填充 + onPrimary 白字、无描边', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: VersionChip(label: '朱', selected: true)),
    );

    final material = firstDescendantMaterial(tester, VersionChip);
    expect(material.color, AppColors.light.primary);
    expect(
      (material.shape as StadiumBorder).side,
      BorderSide.none,
    );
    expect(
      tester.widget<Text>(find.text('朱')).style?.color,
      AppColors.light.onPrimary,
    );
  });

  testWidgets('未选中态：透明底 + outlineVariant 描边 + 次级字', (tester) async {
    await tester.pumpWidget(
      wrapTheme(child: VersionChip(label: '紫', selected: false)),
    );

    final material = firstDescendantMaterial(tester, VersionChip);
    expect(material.color, Colors.transparent);
    expect(
      (material.shape as StadiumBorder).side.color,
      AppColors.light.outlineVariant,
    );
    expect(
      tester.widget<Text>(find.text('紫')).style?.color,
      AppColors.light.onSurfaceVariant,
    );
  });

  testWidgets('点击回调 + dark 主题渲染无异常（关键组件暗色跑一遍）', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: VersionChip(
          label: '剑盾',
          selected: false,
          onTap: () => tapped = true,
        ),
      ),
    );

    await tester.tap(find.text('剑盾'));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
