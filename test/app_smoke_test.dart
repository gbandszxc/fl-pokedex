import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_pokedex/app/app.dart';

void main() {
  testWidgets('应用启动后导航含「图鉴」入口', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AmberDexApp()));
    await tester.pumpAndSettle();

    // 底部 NavigationBar（compact 视口）与侧边 NavigationRail（宽视口）
    // 至少其一渲染「图鉴」标签；默认测试视口为 compact。
    expect(find.text('图鉴'), findsWidgets);
    expect(find.text('琥珀图鉴'), findsOneWidget);
  });
}
