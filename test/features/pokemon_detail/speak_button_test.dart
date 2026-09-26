import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/features/pokemon_detail/speak_button.dart';

import 'fake_repositories.dart';

/// flutter_tts 平台通道 mock。
///
/// channel 名为插件内部实现（flutter_tts 4.2.5 lib/flutter_tts.dart:330，
/// `MethodChannel('flutter_tts')`）；升级插件后若 mock 不生效先核对该常量。
class FakeTts {
  final List<MethodCall> calls = [];

  /// setLanguage / speak 的返回值（1=成功，0=失败），默认成功。
  Object? setLanguageResult = 1;
  Object? speakResult = 1;

  Future<Object?> handle(MethodCall call) async {
    calls.add(call);
    return switch (call.method) {
      'setLanguage' => setLanguageResult,
      'speak' => speakResult,
      'getLanguages' => const <String>['zh-CN', 'zh-TW', 'en-US', 'ja-JP'],
      _ => 1,
    };
  }

  Iterable<MethodCall> named(String method) =>
      calls.where((call) => call.method == method);

  int count(String method) => named(method).length;
}

void main() {
  late FakeTts fake;

  setUp(() {
    fake = FakeTts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      fake.handle,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  Widget harness({
    String text = '种子在出生时埋在土里。',
    String language = 'zh_hans',
  }) =>
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SpeakButton(text: text, language: language),
          ),
        ),
      );

  group('SpeakButton 状态机', () {
    testWidgets('点击朗读：setLanguage / speak 被调且进入朗读态', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(fake.named('setLanguage').single.arguments, 'zh-CN');
      expect(fake.named('speak').single.arguments, '种子在出生时埋在土里。');
      // 乐观朗读态：图标切 stop。
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('语言映射：zh_hant / en / ja → zh-TW / en-US / ja-JP',
        (tester) async {
      const cases = {
        'zh_hant': 'zh-TW',
        'en': 'en-US',
        'ja': 'ja-JP',
      };
      var index = 0;
      for (final entry in cases.entries) {
        // 文本随迭代变化：didUpdateWidget 自动停止上一段，回到空闲。
        await tester.pumpWidget(
          harness(text: '文本 $index', language: entry.key),
        );
        await tester.pump();
        await tester.tap(find.byIcon(Icons.volume_up));
        await tester.pump();

        expect(fake.named('setLanguage').last.arguments, entry.value,
            reason: '${entry.key} 应映射到 ${entry.value}');
        expect(fake.named('speak').last.arguments, '文本 $index');
        fake.calls.clear();
        index++;
      }
    });

    testWidgets('朗读态再点击：调用 stop 并回到空闲', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.tap(find.byIcon(Icons.stop));
      await tester.pump();

      expect(fake.count('stop'), 1);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('平台完成事件（speak.onComplete）→ 回到空闲', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter_tts',
        const MethodChannel('flutter_tts')
            .codec
            .encodeMethodCall(const MethodCall('speak.onComplete')),
        (_) {},
      );
      await tester.pump();

      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('切换文本（物种 / 形态 / 版本切换）→ 自动 stop', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();
      expect(find.byIcon(Icons.stop), findsOneWidget);

      // 同位置换新文本：didUpdateWidget 停止朗读。
      await tester.pumpWidget(harness(text: '另一段说明'));
      await tester.pump();

      expect(fake.count('stop'), 1);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsNothing);
    });

    testWidgets('按钮卸载（页面退出）→ 控制器 autoDispose 停止', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      // ProviderScope 保持存活（同一根位置复用容器），仅按钮子树卸载。
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: Container()),
          ),
        ),
      );
      await tester.pump();

      expect(fake.count('stop'), 1);
    });

    testWidgets('引擎无该语言（setLanguage=0）→ SnackBar 提示一次且回空闲',
        (tester) async {
      fake.setLanguageResult = 0;
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();

      expect(find.text('当前设备没有可用的语音引擎'), findsOneWidget);
      // 回到空闲可重试。
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(fake.count('speak'), 0);

      // 等首条 SnackBar 自动退场后再次触发：同一会话不再刷屏。
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('当前设备没有可用的语音引擎'), findsNothing);

      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();
      expect(find.text('当前设备没有可用的语音引擎'), findsNothing);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
    });

    testWidgets('speak 结果 0（引擎丢弃 / 失败）→ 同样提示', (tester) async {
      fake.speakResult = 0;
      await tester.pumpWidget(harness());
      await tester.pump();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pumpAndSettle();

      expect(find.text('当前设备没有可用的语音引擎'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // 等待 SnackBar 自动退场，避免测试结束时残留 pending timer。
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('当前设备没有可用的语音引擎'), findsNothing);
    });
  });

  group('详情页集成', () {
    testWidgets('版本标题行行尾出现朗读按钮；点击朗读 zh-CN 的当前文本', (tester) async {
      final repo = FakePokedexRepository();
      final favorites = FakeFavoritesRepository();
      addTearDown(favorites.dispose);
      // 走 /pokemon/:speciesId 路由挂载（同 pokemon_detail_page_test）。
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pokedexRepositoryProvider.overrideWithValue(repo),
            favoritesRepositoryProvider.overrideWithValue(favorites),
          ],
          child: MaterialApp.router(
            theme: buildLightTheme(),
            routerConfig: GoRouter(
              initialLocation: '/pokemon/1',
              routes: [
                GoRoute(
                  path: '/pokemon/:speciesId',
                  builder: (context, state) => PokemonDetailPage(
                    speciesId: int.tryParse(
                          state.pathParameters['speciesId'] ?? '',
                        ) ??
                        0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 版本标题行：选中版本「红」在 chip 之外新增标题处，共 2 处。
      expect(find.text('红'), findsNWidgets(2));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      // 收起折叠头部让说明区可点（妙蛙种子默认选「红」= 简中文本）。
      await tester.drag(find.text('#001'), const Offset(0, -600));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.volume_up));
      await tester.pump();

      expect(fake.named('setLanguage').single.arguments, 'zh-CN');
      expect(fake.named('speak').single.arguments, '种子在出生时埋在土里。');
      expect(find.byIcon(Icons.stop), findsOneWidget);
    });
  });
}
