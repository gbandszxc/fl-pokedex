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

  group('更新通道白名单（唯一放行的联网用途）', () {
    test('仅 https 的 GitHub 发布页与资产域放行', () {
      expect(
        isUpdateChannelUriAllowed(
          Uri.parse('https://github.com/gbandszxc/fl-pokedex/releases/latest'),
        ),
        isTrue,
      );
      expect(
        isUpdateChannelUriAllowed(
          Uri.parse('https://release-assets.githubusercontent.com/x'),
        ),
        isTrue,
      );
      // 非 https 一律不放行。
      expect(
        isUpdateChannelUriAllowed(
          Uri.parse('http://github.com/gbandszxc/fl-pokedex'),
        ),
        isFalse,
      );
      // 图鉴数据接口与任意第三方域仍然禁止。
      expect(
        isUpdateChannelUriAllowed(
          Uri.parse('https://pokeapi.co/api/v2/pokemon/25'),
        ),
        isFalse,
      );
      expect(
        isUpdateChannelUriAllowed(Uri.parse('https://evil.example/github.com')),
        isFalse,
      );
    });

    test('空白名单下 GitHub 也被拦截（守卫口径可控）', () {
      HttpOverrides.global = BlockingHttpOverrides(allowedHosts: const {});

      final client = HttpClient();
      expect(
        () => client.getUrl(
          Uri.parse('https://github.com/gbandszxc/fl-pokedex/releases/latest'),
        ),
        throwsA(isA<OfflineRequestBlocked>()),
      );
      client.close(force: true);
    });

    test('消息指明只有更新通道可联网', () {
      const blocked = OfflineRequestBlocked('GET https://example.com');
      expect(blocked.toString(), contains('更新通道'));
    });
  });
}
