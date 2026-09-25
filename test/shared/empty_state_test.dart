import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/shared/widgets/empty_state.dart';

import 'test_utils.dart';

void main() {
  testWidgets('渲染图标 + 标题 + 指引文案', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        child: const EmptyState(
          title: '没有匹配的宝可梦',
          message: '试试清除筛选条件，或换个关键词搜索',
        ),
      ),
    );

    expect(find.byIcon(Icons.search_off), findsOneWidget);
    expect(find.text('没有匹配的宝可梦'), findsOneWidget);
    expect(find.text('试试清除筛选条件，或换个关键词搜索'), findsOneWidget);
  });

  testWidgets('可选操作按钮可点击', (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      wrapTheme(
        child: EmptyState(
          title: '没有匹配的宝可梦',
          message: '试试清除筛选条件',
          action: TextButton(
            onPressed: () => pressed = true,
            child: const Text('清除筛选条件'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('清除筛选条件'));
    expect(pressed, isTrue);
  });

  testWidgets('自定义 outline 图标 + dark 主题渲染无异常', (tester) async {
    await tester.pumpWidget(
      wrapTheme(
        brightness: Brightness.dark,
        child: const EmptyState(
          icon: Icons.folder_off_outlined,
          title: '收藏夹是空的',
          message: '在宝可梦详情页点♡即可收藏',
        ),
      ),
    );
    expect(find.byIcon(Icons.folder_off_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
