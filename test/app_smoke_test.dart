import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_pokedex/app/app.dart';

import 'helpers/fake_update_service.dart';

void main() {
  testWidgets('应用启动后导航含「图鉴」入口', (tester) async {
    // 启动静默检查更新 override 为「已是最新」：用例不触网。
    await tester.pumpWidget(
      ProviderScope(
        overrides: noUpdateOverrides(),
        child: const AmberDexApp(),
      ),
    );
    // 首页首载走异步数据链，测试环境无平台插件时保持加载骨架（有
    // 循环动画，永不 settle），因此用有界泵帧代替 pumpAndSettle。
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 底部 NavigationBar（compact 视口）与侧边 NavigationRail（宽视口）
    // 至少其一渲染「图鉴」标签；默认测试视口为 compact。
    expect(find.text('图鉴'), findsWidgets);
    // E 单元实装后，顶栏为内嵌搜索框（原「Fl-PokeDex」占位标题移除）。
    expect(find.text('搜索 名称 / 编号'), findsOneWidget);
  });
}
