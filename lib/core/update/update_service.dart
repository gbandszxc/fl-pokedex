import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../offline/blocking_http_overrides.dart';
import 'update_progress.dart';
import 'update_release.dart';

/// 检查更新结果（sealed：调用方按分支给出反馈，失败与「已是最新」区分开）。
sealed class UpdateCheckResult {
  const UpdateCheckResult();
}

/// 命中了比当前版本更新的发布，且找到当前系统的安装包。
final class UpdateAvailable extends UpdateCheckResult {
  const UpdateAvailable(this.release);

  final UpdateRelease release;
}

/// 当前已是最新版本。
final class UpdateUpToDate extends UpdateCheckResult {
  const UpdateUpToDate();
}

/// 有新版本，但发布资产里没有当前系统的安装包（version 为空 = 当前系统不在发布矩阵内）。
final class UpdateAssetUnavailable extends UpdateCheckResult {
  const UpdateAssetUnavailable(this.version);

  final String version;
}

/// 检查失败（网络不可用 / 超时 / 网页结构异常等）。
final class UpdateCheckFailed extends UpdateCheckResult {
  const UpdateCheckFailed(this.message);

  final String message;
}

/// 更新通道的服务接口（检查 / 下载）。
///
/// 检查走 GitHub 发布**网页**（`releases/latest` 重定向 + `expanded_assets` HTML
/// 片段），不依赖 GitHub API、无 token、无速率限制；下载走资产直链
/// （`releases/download/...`，302 到 release-assets 域）。白名单见
/// [kUpdateChannelAllowedHosts]。
abstract class UpdateService {
  /// 与当前版本比较，返回检查结果（失败以 [UpdateCheckFailed] 返回，不抛异常）。
  Future<UpdateCheckResult> checkForUpdate({required String currentVersion});

  /// 已下载完成的安装包（权限补齐等场景免二次下载）；无则 null。
  Future<File?> findCachedDownload(UpdateRelease release);

  /// 下载安装包到缓存目录并返回文件。
  ///
  /// [onProgress] 在下载过程中周期回调（首帧 + 每 500ms + 收尾）；
  /// [cancelToken] 置位后中止下载、删除半成品并抛 [UpdateDownloadCanceled]。
  Future<File> download(
    UpdateRelease release, {
    required void Function(UpdateProgress progress) onProgress,
    required UpdateCancelToken cancelToken,
  });
}

/// 把更新通道的异常翻译成用户可读的一句话。
String describeUpdateError(Object error) {
  if (error is UpdateDownloadCanceled) {
    return '下载已取消';
  }
  if (error is OfflineRequestBlocked) {
    return '更新通道被离线守卫拦截';
  }
  if (error is SocketException) {
    return '网络连接失败';
  }
  if (error is TimeoutException) {
    return '连接超时';
  }
  if (error is _HttpStatusException) {
    return 'HTTP ${error.statusCode}';
  }
  if (error is HttpException) {
    return '网络异常：${error.message}';
  }
  if (error is FileSystemException) {
    return '写入安装包失败';
  }
  return error.toString();
}

/// GitHub 发布网页实现（PRODUCT.md：更新是运行时唯一被放行的联网用途）。
class GitHubUpdateService implements UpdateService {
  GitHubUpdateService({
    UpdateTarget? target,
    Uri? repoUrl,
    Future<Directory> Function()? cacheDirProvider,
    HttpClient Function()? clientFactory,
  })  : _target = target,
        _repoUrl = repoUrl ?? Uri.parse(kUpdateRepoUrl),
        _cacheDirProvider = cacheDirProvider ?? _defaultCacheDir,
        _clientFactory = clientFactory ?? HttpClient.new;

  /// 目标平台/架构；null = 当前系统不在发布矩阵内。
  final UpdateTarget? _target;

  final Uri _repoUrl;

  final Future<Directory> Function() _cacheDirProvider;

  final HttpClient Function() _clientFactory;

  static const Duration _connectTimeout = Duration(seconds: 10);

  /// 单次检查（两个网页请求）的总时限：启动静默检查不能拖住用户。
  static const Duration _checkTimeout = Duration(seconds: 15);

  /// 进度回调最小间隔（避免逐块刷新 UI）。
  static const Duration _progressInterval = Duration(milliseconds: 500);

  static const int _maxRedirects = 5;

  static const String _userAgent = 'Fl-PokeDex-Updater';

  static Future<Directory> _defaultCacheDir() async {
    final temp = await getTemporaryDirectory();
    return Directory(p.join(temp.path, 'updates'));
  }

  @override
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    final target = _target;
    if (target == null) {
      // 当前系统不在发布矩阵（32 位等）：无需发请求，直接报告无可用安装包。
      return const UpdateAssetUnavailable('');
    }
    final client = _clientFactory()..connectionTimeout = _connectTimeout;
    try {
      return await _check(client, target, currentVersion)
          .timeout(_checkTimeout);
    } on Object catch (error, stackTrace) {
      debugPrint('[update] 检查更新失败: $error\n$stackTrace');
      return UpdateCheckFailed(describeUpdateError(error));
    } finally {
      client.close(force: true);
    }
  }

  Future<UpdateCheckResult> _check(
    HttpClient client,
    UpdateTarget target,
    String currentVersion,
  ) async {
    final latest = await _getHtml(
      client,
      _repoUrl.replace(path: '${_repoUrl.path}/releases/latest'),
    );
    if (latest.statusCode != HttpStatus.ok) {
      throw _HttpStatusException(latest.statusCode);
    }
    final tag =
        releaseTagFromUri(latest.finalUri) ?? releaseTagFromHtml(latest.body);
    if (tag == null) {
      throw const HttpException('发布页未包含版本 tag');
    }
    if (compareVersions(tag, currentVersion) <= 0) {
      return const UpdateUpToDate();
    }
    final assets = await _getHtml(
      client,
      _repoUrl.replace(path: '${_repoUrl.path}/releases/expanded_assets/$tag'),
    );
    if (assets.statusCode != HttpStatus.ok) {
      throw _HttpStatusException(assets.statusCode);
    }
    final release = selectRelease(
      tag: tag,
      baseUri: _repoUrl,
      assetsHtml: assets.body,
      target: target,
    );
    if (release == null) {
      return UpdateAssetUnavailable(normalizeVersion(tag));
    }
    return UpdateAvailable(release);
  }

  @override
  Future<File?> findCachedDownload(UpdateRelease release) async {
    final dir = await _cacheDirProvider();
    final file = File(p.join(dir.path, release.assetName));
    if (await file.exists() && await file.length() > 0) {
      return file;
    }
    return null;
  }

  @override
  Future<File> download(
    UpdateRelease release, {
    required void Function(UpdateProgress progress) onProgress,
    required UpdateCancelToken cancelToken,
  }) async {
    final dir = await _cacheDirProvider();
    await dir.create(recursive: true);
    // 目录内只保留本次下载：清掉历史安装包与中断残留。
    await for (final entity in dir.list()) {
      if (entity is File) {
        await entity.delete();
      }
    }
    final file = File(p.join(dir.path, release.assetName));
    final client = _clientFactory()..connectionTimeout = _connectTimeout;
    try {
      final opened = await _open(client, release.downloadUrl);
      final response = opened.response;
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        throw _HttpStatusException(response.statusCode);
      }
      final total = response.contentLength > 0 ? response.contentLength : null;
      final sink = file.openWrite();
      var received = 0;
      var lastEmitAt = DateTime.now();
      var lastEmitBytes = 0;
      final startedAt = DateTime.now();
      onProgress(UpdateProgress(received: 0, total: total, bytesPerSecond: 0));
      try {
        await for (final chunk in response) {
          if (cancelToken.isCanceled) {
            throw const UpdateDownloadCanceled();
          }
          sink.add(chunk);
          received += chunk.length;
          final now = DateTime.now();
          final elapsed = now.difference(lastEmitAt);
          if (elapsed >= _progressInterval) {
            final elapsedMs =
                elapsed.inMilliseconds < 1 ? 1 : elapsed.inMilliseconds;
            onProgress(
              UpdateProgress(
                received: received,
                total: total,
                bytesPerSecond: (received - lastEmitBytes) * 1000 / elapsedMs,
              ),
            );
            lastEmitAt = now;
            lastEmitBytes = received;
          }
        }
        await sink.flush();
      } on Object {
        await sink.close();
        await _deleteQuietly(file);
        rethrow;
      }
      await sink.close();
      final totalMs = DateTime.now().difference(startedAt).inMilliseconds;
      onProgress(
        UpdateProgress(
          received: received,
          total: total,
          bytesPerSecond: received * 1000 / (totalMs < 1 ? 1 : totalMs),
        ),
      );
      return file;
    } finally {
      client.close(force: true);
    }
  }

  /// 取网页文本（仅 200 读正文）；每一跳都要求落在更新通道白名单内。
  Future<_HtmlPage> _getHtml(HttpClient client, Uri uri) async {
    final opened = await _open(client, uri);
    final response = opened.response;
    String body = '';
    if (response.statusCode == HttpStatus.ok) {
      body = await utf8.decodeStream(response);
    } else {
      await response.drain<void>();
    }
    return _HtmlPage(
      statusCode: response.statusCode,
      finalUri: opened.finalUri,
      body: body,
    );
  }

  /// 手动跟随重定向（而非交给 HttpClient.followRedirects）：redirect 目标
  /// 主机也要逐跳过白名单，离线守卫的口径才真正可控。
  Future<_OpenedResponse> _open(HttpClient client, Uri uri) async {
    var current = uri;
    for (var hop = 0; hop <= _maxRedirects; hop++) {
      if (!isUpdateChannelUriAllowed(current)) {
        throw OfflineRequestBlocked('GET $current');
      }
      final request = await client.getUrl(current);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close();
      final location = response.headers.value(HttpHeaders.locationHeader);
      final isRedirect =
          response.isRedirect && location != null && location.isNotEmpty;
      if (!isRedirect) {
        return _OpenedResponse(response: response, finalUri: current);
      }
      await response.drain<void>();
      current = current.resolve(location);
    }
    throw const HttpException('重定向次数过多');
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on Object catch (error) {
      debugPrint('[update] 清理半成品失败: $error');
    }
  }
}

/// https 状态码异常（网络层内部信号，经 [describeUpdateError] 转文案）。
class _HttpStatusException implements Exception {
  const _HttpStatusException(this.statusCode);

  final int statusCode;
}

/// 网页请求结果：状态码 / 最终地址（重定向后）/ HTML 正文。
class _HtmlPage {
  const _HtmlPage({
    required this.statusCode,
    required this.finalUri,
    required this.body,
  });

  final int statusCode;
  final Uri finalUri;
  final String body;
}

/// 非重定向的响应 + 其最终地址。
class _OpenedResponse {
  const _OpenedResponse({required this.response, required this.finalUri});

  final HttpClientResponse response;
  final Uri finalUri;
}
