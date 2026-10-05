import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_dialogs.dart';
import 'update_installer.dart';
import 'update_providers.dart';
import 'update_release.dart';
import 'update_service.dart';

/// 检查更新 → 反馈结果 →（用户确认后）下载并在模态里回显进度/速度 → 拉起安装流程。
///
/// [silent] = true（应用启动的自动检查）：失败与「已是最新」都不打扰用户，
/// 只有命中新版本才弹对话框；用户点「稍后」后本次运行不再自动提示。
/// [silent] = false（设置页手动入口）：每个结果都有反馈。
Future<void> runUpdateCheckFlow(
  BuildContext context,
  WidgetRef ref, {
  required String currentVersion,
  required bool silent,
}) async {
  final service = ref.read(updateServiceProvider);
  final result = await service.checkForUpdate(currentVersion: currentVersion);
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case UpdateUpToDate():
      if (!silent) {
        _showMessage(context, '已是最新版本');
      }
    case UpdateAssetUnavailable(:final version):
      if (!silent) {
        _showMessage(
          context,
          version.isEmpty
              ? '未找到适用于当前系统的安装包'
              : '发现新版本 $version，但未找到适用于当前系统的安装包',
        );
      }
    case UpdateCheckFailed(:final message):
      if (!silent) {
        _showMessage(context, '检查更新失败：$message');
      }
    case UpdateAvailable(:final release):
      if (silent && ref.read(updatePromptSnoozedProvider)) {
        return;
      }
      final accepted = await showUpdateAvailableDialog(
        context,
        currentVersion: currentVersion,
        release: release,
        target: ref.read(updateTargetProvider),
      );
      if (!context.mounted) {
        return;
      }
      if (!accepted) {
        ref.read(updatePromptSnoozedProvider.notifier).snooze();
        return;
      }
      await _downloadAndInstall(context, ref, release);
  }
}

Future<void> _downloadAndInstall(
  BuildContext context,
  WidgetRef ref,
  UpdateRelease release,
) async {
  final installer = ref.read(updateInstallerProvider);
  final result = await showUpdateDownloadDialog(
    context,
    release: release,
    service: ref.read(updateServiceProvider),
  );
  if (!context.mounted) {
    return;
  }
  switch (result) {
    case UpdateDownloadCanceledByUser():
      _showMessage(context, '已取消下载');
    case UpdateDownloadFailed(:final message):
      _showMessage(context, '下载失败：$message');
    case UpdateDownloadSucceeded(:final file):
      final outcome = await installer.open(file);
      if (!context.mounted) {
        return;
      }
      switch (outcome) {
        case UpdateInstallOutcome.started:
          _showMessage(
            context,
            Platform.isWindows ? '安装程序已打开，应用将退出以完成更新' : '已打开安装程序，请按提示完成更新',
          );
        case UpdateInstallOutcome.permissionRequired:
          await _showInstallPermissionDialog(context, installer);
        case UpdateInstallOutcome.unsupportedPlatform:
        case UpdateInstallOutcome.failed:
          _showMessage(context, '无法自动打开安装程序，安装包已保存到 ${file.path}');
      }
  }
}

/// Android 8.0+ 首次应用内安装需用户授权「安装未知应用」。
Future<void> _showInstallPermissionDialog(
  BuildContext context,
  UpdateInstaller installer,
) async {
  final goToSettings = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('需要安装权限'),
      content: const Text(
        '请在系统设置中允许「Fl-PokeDex」安装应用，然后回到设置页重新点「检查更新」；'
        '安装包已下载完成，不会重复下载。',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('前往设置'),
        ),
      ],
    ),
  );
  if (goToSettings ?? false) {
    await installer.openInstallPermissionSettings();
  }
}

void _showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
