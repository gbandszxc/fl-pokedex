import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/core/update/update_release.dart';

/// `releases/expanded_assets/<tag>` 的真实结构（取自 v1.1.0 发布页，截取关键行）。
const String _assetsHtml = '''
<div data-view-component="true" class="Box Box--condensed tmp-mt-3">
  <ul data-view-component="true">
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-arm64-mac.dmg" rel="nofollow" data-turbo="false" class="wb-break-all">
        <span class="text-bold">Fl-PokeDex-1.1.0-arm64-mac.dmg</span>
      </a>
      <span class="Truncate text-mono text-small color-fg-muted">sha256:e3395fd253ddfc97</span>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-arm64-v8a-release.apk" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.1.0-arm64-v8a-release.apk</span>
      </a>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-armeabi-v7a-release.apk" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.1.0-armeabi-v7a-release.apk</span>
      </a>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-universal-mac.dmg" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.1.0-universal-mac.dmg</span>
      </a>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-x64.msi" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.1.0-x64.msi</span>
      </a>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.1.0/Fl-PokeDex-1.1.0-x86_64-release.apk" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.1.0-x86_64-release.apk</span>
      </a>
    </li>
    <li class="Box-row">
      <a href="/gbandszxc/fl-pokedex/releases/download/v1.0.0/Fl-PokeDex-1.0.0-x86_64-release.apk" rel="nofollow">
        <span class="text-bold">Fl-PokeDex-1.0.0-x86_64-release.apk</span>
      </a>
    </li>
  </ul>
</div>
''';

final Uri _repoUri = Uri.parse('https://github.com/gbandszxc/fl-pokedex');

void main() {
  group('normalizeVersion', () {
    test('去掉 v 前缀与首尾空白', () {
      expect(normalizeVersion('v1.1.0'), '1.1.0');
      expect(normalizeVersion(' V2.0 '), '2.0');
      expect(normalizeVersion('1.0.0'), '1.0.0');
      expect(normalizeVersion(''), '');
    });
  });

  group('compareVersions', () {
    test('相同版本（含 v 前缀 / 构建号）相等', () {
      expect(compareVersions('v1.1.0', '1.1.0'), 0);
      expect(compareVersions('1.1.0+2', '1.1.0'), 0);
      expect(compareVersions('1.1', '1.1.0'), 0);
    });

    test('按数字段比较，不做字符串比较', () {
      expect(compareVersions('1.10.0', '1.9.9'), greaterThan(0));
      expect(compareVersions('1.2.0', '1.1.9'), greaterThan(0));
      expect(compareVersions('1.0.0', '1.1.0'), lessThan(0));
      expect(compareVersions('2.0', '1.9.9'), greaterThan(0));
    });

    test('预发布后缀按数字段 0 处理（不阻塞正式版提示）', () {
      expect(compareVersions('1.2.0-beta', '1.2.0'), 0);
    });
  });

  group('releaseTagFromUri', () {
    test('从重定向后的 releases/tag 路径取 tag', () {
      expect(
        releaseTagFromUri(
          Uri.parse('https://github.com/gbandszxc/fl-pokedex/releases/tag/v1.1.0'),
        ),
        'v1.1.0',
      );
    });

    test('非 tag 地址返回 null', () {
      expect(
        releaseTagFromUri(
          Uri.parse('https://github.com/gbandszxc/fl-pokedex/releases/latest'),
        ),
        isNull,
      );
    });
  });

  group('releaseTagFromHtml', () {
    test('从发布页 HTML 兜底解析 tag', () {
      const html = '<a href="/gbandszxc/fl-pokedex/releases/tag/v1.1.0">v1.1.0</a>';
      expect(releaseTagFromHtml(html), 'v1.1.0');
    });

    test('无 tag 链接返回 null', () {
      expect(releaseTagFromHtml('<html><body>Not Found</body></html>'), isNull);
    });
  });

  group('parseAssetHrefs', () {
    test('提取全部资产直链并反转义 &amp;', () {
      final hrefs = parseAssetHrefs(_assetsHtml);
      expect(hrefs, hasLength(7));
      expect(
        hrefs.first,
        '/gbandszxc/fl-pokedex/releases/download/v1.1.0/'
        'Fl-PokeDex-1.1.0-arm64-mac.dmg',
      );

      const escaped = '<a href="/o/r/releases/download/v1.0/a.apk?x=1&amp;y=2">a</a>';
      expect(parseAssetHrefs(escaped).single, endsWith('a.apk?x=1&y=2'));
    });
  });

  group('selectRelease 按平台/架构选包', () {
    UpdateRelease? select(String os, Abi abi, {String tag = 'v1.1.0'}) {
      final target = detectUpdateTarget(operatingSystem: os, currentAbi: abi);
      expect(target, isNotNull, reason: '$os/$abi 应有目标');
      return selectRelease(
        tag: tag,
        baseUri: _repoUri,
        assetsHtml: _assetsHtml,
        target: target!,
      );
    }

    test('Android x86_64 选 x86_64 release APK（MuMu 等模拟器）', () {
      final release = select('android', Abi.androidX64)!;
      expect(release.version, '1.1.0');
      expect(release.tag, 'v1.1.0');
      expect(release.assetName, 'Fl-PokeDex-1.1.0-x86_64-release.apk');
      expect(
        release.downloadUrl.toString(),
        'https://github.com/gbandszxc/fl-pokedex/releases/download/v1.1.0/'
        'Fl-PokeDex-1.1.0-x86_64-release.apk',
      );
    });

    test('Android arm64-v8a / armeabi-v7a 各取其包', () {
      expect(
        select('android', Abi.androidArm64)!.assetName,
        'Fl-PokeDex-1.1.0-arm64-v8a-release.apk',
      );
      expect(
        select('android', Abi.androidArm)!.assetName,
        'Fl-PokeDex-1.1.0-armeabi-v7a-release.apk',
      );
    });

    test('Windows 选 x64 MSI（Arm64 走 x64 模拟）', () {
      expect(select('windows', Abi.windowsX64)!.assetName, 'Fl-PokeDex-1.1.0-x64.msi');
      expect(select('windows', Abi.windowsArm64)!.assetName, 'Fl-PokeDex-1.1.0-x64.msi');
    });

    test('macOS arm64 选 arm64 dmg，x64 选 universal dmg', () {
      expect(
        select('macos', Abi.macosArm64)!.assetName,
        'Fl-PokeDex-1.1.0-arm64-mac.dmg',
      );
      expect(
        select('macos', Abi.macosX64)!.assetName,
        'Fl-PokeDex-1.1.0-universal-mac.dmg',
      );
    });

    test('不匹配其它版本 / 其它架构的资产', () {
      // 资产里没有 1.2.0。
      expect(select('android', Abi.androidX64, tag: 'v1.2.0'), isNull);
      // 资产里没有 arm64 的 Windows MSI。
      expect(
        selectRelease(
          tag: 'v1.1.0',
          baseUri: _repoUri,
          assetsHtml: _assetsHtml,
          target: const UpdateTarget(UpdatePlatform.windows, 'arm64'),
        ),
        isNull,
      );
    });

    test('debug 包不匹配（只认 -release.apk）', () {
      const html =
          '<a href="/gbandszxc/fl-pokedex/releases/download/v9.9.9/'
          'Fl-PokeDex-9.9.9-x86_64-debug.apk">x</a>';
      expect(
        selectRelease(
          tag: 'v9.9.9',
          baseUri: _repoUri,
          assetsHtml: html,
          target: const UpdateTarget(UpdatePlatform.android, 'x86_64'),
        ),
        isNull,
      );
    });
  });

  group('detectUpdateTarget', () {
    test('Android ABI 映射', () {
      expect(
        detectUpdateTarget(operatingSystem: 'android', currentAbi: Abi.androidX64),
        isA<UpdateTarget>()
            .having((t) => t.platform, 'platform', UpdatePlatform.android)
            .having((t) => t.arch, 'arch', 'x86_64'),
      );
      expect(
        detectUpdateTarget(operatingSystem: 'android', currentAbi: Abi.androidArm64)!.arch,
        'arm64-v8a',
      );
      expect(
        detectUpdateTarget(operatingSystem: 'android', currentAbi: Abi.androidArm)!.arch,
        'armeabi-v7a',
      );
    });

    test('不支持的组合返回 null（32 位 x86 / 未发布平台）', () {
      expect(
        detectUpdateTarget(operatingSystem: 'android', currentAbi: Abi.androidIA32),
        isNull,
      );
      expect(
        detectUpdateTarget(operatingSystem: 'windows', currentAbi: Abi.windowsIA32),
        isNull,
      );
      expect(
        detectUpdateTarget(operatingSystem: 'linux', currentAbi: Abi.linuxX64),
        isNull,
      );
    });

    test('本机（Windows x64）能识别出目标并展示中文平台标签', () {
      final target = detectUpdateTarget(
        operatingSystem: 'windows',
        currentAbi: Abi.windowsX64,
      )!;
      expect(target.label, 'Windows · x64');
    });
  });
}
