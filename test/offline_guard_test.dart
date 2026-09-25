import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fl_pokedex/core/offline/blocking_http_overrides.dart';

void main() {
  tearDown(() {
    HttpOverrides.global = null;
  });

  test('HttpOverrides.global 下创建的客户端 openUrl 直接抛 OfflineRequestBlocked',
      () async {
    HttpOverrides.global = BlockingHttpOverrides();

    final client = HttpClient(); // 工厂走 HttpOverrides.global → 代理客户端
    expect(
      () => client.openUrl('GET', Uri.parse('https://example.com')),
      throwsA(isA<OfflineRequestBlocked>()),
    );
    client.close(force: true);
  });

  test('OfflineRequestBlocked 消息中包含被拦截的 URL', () async {
    HttpOverrides.global = BlockingHttpOverrides();

    final client = HttpClient();
    try {
      await client.openUrl('GET', Uri.parse('https://example.com/poke'));
      fail('离线守卫未拦截请求');
    } on OfflineRequestBlocked catch (e) {
      expect(e.url, contains('https://example.com/poke'));
    } finally {
      client.close(force: true);
    }
  });
}
