import 'dart:ffi';
import 'dart:io';

/// 更新仓库（与设置页「项目地址」同源，architecture.md §8）。
const String kUpdateRepoOwner = 'gbandszxc';
const String kUpdateRepoName = 'fl-pokedex';
const String kUpdateRepoUrl =
    'https://github.com/$kUpdateRepoOwner/$kUpdateRepoName';

/// 支持的更新平台（发布资产的命名前缀）。
enum UpdatePlatform { android, windows, macos }

/// 目标平台 + 架构：决定从发布资产里挑哪一个安装包。
///
/// 资产命名契约（tools/msi、android/app/build.gradle.kts、CI 发布同款）：
/// - Android：`Fl-PokeDex-<version>-<abi>-release.apk`（abi ∈ arm64-v8a / armeabi-v7a / x86_64）
/// - Windows：`Fl-PokeDex-<version>-x64.msi`
/// - macOS：`Fl-PokeDex-<version>-arm64-mac.dmg` / `Fl-PokeDex-<version>-universal-mac.dmg`
class UpdateTarget {
  const UpdateTarget(this.platform, this.arch);

  final UpdatePlatform platform;

  /// 资产命名里的架构标识（android 为 ABI 名，windows 固定 x64，macos 为 arm64/universal）。
  final String arch;

  /// 展示给用户的平台描述（更新对话框「目标安装包」行）。
  String get label => switch (platform) {
        UpdatePlatform.android => 'Android · $arch',
        UpdatePlatform.windows => 'Windows · $arch',
        UpdatePlatform.macos => 'macOS · $arch',
      };

  /// 资产名是否匹配当前平台/架构与发布版本。
  bool matchesAsset(String assetName, String releaseVersion) {
    final name = assetName.toLowerCase();
    final version = releaseVersion.toLowerCase();
    if (!name.contains('-$version-')) {
      return false;
    }
    return switch (platform) {
      UpdatePlatform.android => name.endsWith('-$arch-release.apk'),
      UpdatePlatform.windows => name.endsWith('-$arch.msi'),
      UpdatePlatform.macos => name.endsWith('-$arch-mac.dmg'),
    };
  }
}

/// 判定当前运行平台 + 进程架构；不支持的组合返回 null（例如 32 位 x86 Android、
/// 32 位 x86 Windows——发布资产里没有可运行的包）。
///
/// 架构取 `Abi.current()`（当前进程真实 ABI，Android 分包后即所装 APK 的 ABI），
/// 而不是设备支持列表——Android 上二者可能不同，安装包必须与运行进程一致。
/// [operatingSystem] / [currentAbi] 仅测试注入。
UpdateTarget? detectUpdateTarget({String? operatingSystem, Abi? currentAbi}) {
  final os = operatingSystem ?? Platform.operatingSystem;
  final abi = currentAbi ?? Abi.current();
  return switch (os) {
    'android' => switch (abi) {
        Abi.androidArm64 => const UpdateTarget(UpdatePlatform.android, 'arm64-v8a'),
        Abi.androidArm => const UpdateTarget(UpdatePlatform.android, 'armeabi-v7a'),
        Abi.androidX64 => const UpdateTarget(UpdatePlatform.android, 'x86_64'),
        _ => null,
      },
    // 只发布 x64 MSI：Windows on ARM 走系统 x64 模拟，32 位 Windows 无法运行。
    'windows' => switch (abi) {
        Abi.windowsX64 || Abi.windowsArm64 =>
          const UpdateTarget(UpdatePlatform.windows, 'x64'),
        _ => null,
      },
    'macos' => switch (abi) {
        Abi.macosArm64 => const UpdateTarget(UpdatePlatform.macos, 'arm64'),
        Abi.macosX64 => const UpdateTarget(UpdatePlatform.macos, 'universal'),
        _ => null,
      },
    _ => null,
  };
}

/// 去掉 tag/版本里的 `v` 前缀与首尾空白（`v1.1.0` → `1.1.0`）。
String normalizeVersion(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  final first = trimmed[0];
  return (first == 'v' || first == 'V') ? trimmed.substring(1) : trimmed;
}

/// 数字段版本比较：`v1.10.0` > `1.9.9`；非数字段按 0 处理，段数不齐补 0。
///
/// 与 pubspec `version` + Android versionName / Windows 版本资源一致，只比较
/// 数字部分（`1.1.0+2` 的构建号 `+2` 不参与，安装包 versionName 也只带 `1.1.0`）。
int compareVersions(String left, String right) {
  final a = _versionParts(left);
  final b = _versionParts(right);
  final length = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < length; i++) {
    final l = i < a.length ? a[i] : 0;
    final r = i < b.length ? b[i] : 0;
    if (l != r) {
      return l.compareTo(r);
    }
  }
  return 0;
}

List<int> _versionParts(String version) {
  // 构建元数据（`+2`）不参与比较：安装包 versionName 只带 `1.1.0`。
  final core = normalizeVersion(version).split('+').first;
  return core
      .split(RegExp(r'[.\-_]'))
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: false);
}

/// 一次已命中的更新：版本号、目标安装包与下载地址。
class UpdateRelease {
  const UpdateRelease({
    required this.version,
    required this.tag,
    required this.assetName,
    required this.downloadUrl,
  });

  /// 规范化版本号（无 `v` 前缀），如 `1.1.0`。
  final String version;

  /// 发布 tag，如 `v1.1.0`。
  final String tag;

  /// 资产文件名，如 `Fl-PokeDex-1.1.0-x86_64-release.apk`。
  final String assetName;

  /// 资产下载地址（github.com releases/download 直链）。
  final Uri downloadUrl;

  @override
  String toString() => 'UpdateRelease($version, $assetName)';
}

/// 从 `releases/latest` 跟随重定向后的最终地址取 tag（`.../releases/tag/v1.1.0`）。
String? releaseTagFromUri(Uri uri) {
  final segments = uri.pathSegments;
  final index = segments.indexOf('tag');
  if (index == -1 || index + 1 >= segments.length) {
    return null;
  }
  final tag = segments[index + 1];
  return tag.isEmpty ? null : tag;
}

/// 兜底：直接从发布页 HTML 里找 `/releases/tag/<tag>` 链接（重定向被 CDN
/// 处理掉时仍可用，纯网页解析，不碰 GitHub API）。
String? releaseTagFromHtml(String html) {
  return RegExp(r'''/releases/tag/([^"?#<\s]+)''')
      .firstMatch(html)
      ?.group(1);
}

/// 解析 `releases/expanded_assets/<tag>` 片段里的资产直链（相对路径）。
List<String> parseAssetHrefs(String html) {
  return RegExp(r'''href="([^"]*releases/download/[^"]+)"''')
      .allMatches(html)
      .map((match) => match.group(1)!.replaceAll('&amp;', '&'))
      .toList(growable: false);
}

/// 在资产列表里挑出匹配 [target] 与 [tag] 版本的安装包。
///
/// [baseUri] 为仓库地址（`https://github.com/<owner>/<repo>`），用于把相对
/// href 解析成绝对下载地址。无匹配返回 null（该版本没有当前系统的包）。
UpdateRelease? selectRelease({
  required String tag,
  required Uri baseUri,
  required String assetsHtml,
  required UpdateTarget target,
}) {
  final version = normalizeVersion(tag);
  if (version.isEmpty) {
    return null;
  }
  for (final href in parseAssetHrefs(assetsHtml)) {
    final uri = baseUri.resolve(href);
    final assetName = uri.pathSegments.isEmpty ? '' : uri.pathSegments.last;
    if (assetName.isEmpty || !target.matchesAsset(assetName, version)) {
      continue;
    }
    return UpdateRelease(
      version: version,
      tag: tag.trim(),
      assetName: assetName,
      downloadUrl: uri,
    );
  }
  return null;
}
