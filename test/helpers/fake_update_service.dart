import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fl_pokedex/core/update/update_installer.dart';
import 'package:fl_pokedex/core/update/update_progress.dart';
import 'package:fl_pokedex/core/update/update_providers.dart';
import 'package:fl_pokedex/core/update/update_release.dart';
import 'package:fl_pokedex/core/update/update_service.dart';

/// 不触网的更新服务替身。
///
/// 既有 app 级用例（冒烟 / 验收 / 主题扫描）override 成默认「已是最新」，
/// 保证启动静默检查不发真实请求；更新流程用例用它驱动
/// 检查结果、下载进度序列与取消/失败分支。
class FakeUpdateService implements UpdateService {
  FakeUpdateService({
    this.checkResult = const UpdateUpToDate(),
    this.cachedFile,
    this.downloadedFile,
    this.progressScript = const [
      UpdateProgress(received: 0, total: 1024, bytesPerSecond: 0),
      UpdateProgress(received: 512, total: 1024, bytesPerSecond: 2048),
    ],
    this.downloadError,
  });

  final UpdateCheckResult checkResult;

  /// 非空时 [findCachedDownload] 命中（免二次下载分支）。
  File? cachedFile;

  /// [download] 返回的文件；为空时返回 [cachedFile] 或一个占位路径。
  File? downloadedFile;

  /// [download] 依次回调的进度快照。
  List<UpdateProgress> progressScript;

  /// 非空时 [download] 在回调完进度后抛出它。
  Object? downloadError;

  /// 非空时 [download] 回调完进度后等待放行（用例断言中间态用）。
  Completer<void>? downloadGate;

  int checkCalls = 0;

  int downloadCalls = 0;

  String? lastCheckedVersion;

  @override
  Future<UpdateCheckResult> checkForUpdate({
    required String currentVersion,
  }) async {
    checkCalls++;
    lastCheckedVersion = currentVersion;
    return checkResult;
  }

  @override
  Future<File?> findCachedDownload(UpdateRelease release) async => cachedFile;

  @override
  Future<File> download(
    UpdateRelease release, {
    required void Function(UpdateProgress progress) onProgress,
    required UpdateCancelToken cancelToken,
  }) async {
    downloadCalls++;
    for (final progress in progressScript) {
      onProgress(progress);
      await Future<void>.delayed(Duration.zero);
    }
    final gate = downloadGate;
    if (gate != null) {
      await gate.future;
    }
    if (cancelToken.isCanceled) {
      throw const UpdateDownloadCanceled();
    }
    final error = downloadError;
    if (error != null) {
      throw error;
    }
    return downloadedFile ??= File(release.assetName);
  }
}

/// 记录调用的安装器替身（不触碰平台通道 / 进程）。
class FakeUpdateInstaller extends UpdateInstaller {
  FakeUpdateInstaller({this.outcome = UpdateInstallOutcome.started});

  final UpdateInstallOutcome outcome;

  final List<File> openedFiles = <File>[];

  int permissionSettingsCalls = 0;

  @override
  Future<UpdateInstallOutcome> open(File file) async {
    openedFiles.add(file);
    return outcome;
  }

  @override
  Future<bool> openInstallPermissionSettings() async {
    permissionSettingsCalls++;
    return true;
  }
}

/// 既有 app 用例的默认替身：永远「已是最新」，且不触网。
UpdateService noUpdateService() => FakeUpdateService();

/// app 级用例（冒烟 / 验收 / 主题扫描）的更新通道 override：
/// 启动静默检查固定落在「已是最新」，用例全程不发真实请求。
List<Override> noUpdateOverrides() => [
  updateServiceProvider.overrideWithValue(noUpdateService()),
];

/// 样例发布（1.1.0 真实资产命名）。
UpdateRelease fakeRelease({
  String version = '1.1.0',
  String assetName = 'Fl-PokeDex-1.1.0-x86_64-release.apk',
}) => UpdateRelease(
  version: version,
  tag: 'v$version',
  assetName: assetName,
  downloadUrl: Uri.parse(
    'https://github.com/gbandszxc/fl-pokedex/releases/download/v$version/'
    '$assetName',
  ),
);
