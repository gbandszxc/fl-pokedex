import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'update_progress.dart';
import 'update_release.dart';
import 'update_service.dart';

/// 「发现新版本」对话框：返回用户是否选择「下载并安装」。
Future<bool> showUpdateAvailableDialog(
  BuildContext context, {
  required String currentVersion,
  required UpdateRelease release,
  required UpdateTarget? target,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return AlertDialog(
        title: Text('发现新版本 ${release.version}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: '当前版本', value: currentVersion),
            _InfoRow(label: '最新版本', value: release.version),
            _InfoRow(label: '适用平台', value: target?.label ?? '当前系统'),
            const SizedBox(height: AppSpacing.s),
            Text(
              release.assetName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('稍后'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('下载并安装'),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// 下载结果（模态内回显进度/速度，关闭后按分支处理安装）。
sealed class UpdateDownloadResult {
  const UpdateDownloadResult();
}

/// 安装包已就绪（本次下载完成或命中缓存）。
final class UpdateDownloadSucceeded extends UpdateDownloadResult {
  const UpdateDownloadSucceeded(this.file);

  final File file;
}

/// 用户点了「取消」或按返回键。
final class UpdateDownloadCanceledByUser extends UpdateDownloadResult {
  const UpdateDownloadCanceledByUser();
}

/// 下载失败（网络中断 / 写入失败等）。
final class UpdateDownloadFailed extends UpdateDownloadResult {
  const UpdateDownloadFailed(this.message);

  final String message;
}

/// 下载模态：开始即下载，实时回显已下载/总量与瞬时速度；完成后由调用方拉起安装。
Future<UpdateDownloadResult> showUpdateDownloadDialog(
  BuildContext context, {
  required UpdateRelease release,
  required UpdateService service,
}) async {
  final result = await showDialog<UpdateDownloadResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        _UpdateDownloadDialog(release: release, service: service),
  );
  return result ?? const UpdateDownloadCanceledByUser();
}

class _UpdateDownloadDialog extends StatefulWidget {
  const _UpdateDownloadDialog({required this.release, required this.service});

  final UpdateRelease release;

  final UpdateService service;

  @override
  State<_UpdateDownloadDialog> createState() => _UpdateDownloadDialogState();
}

class _UpdateDownloadDialogState extends State<_UpdateDownloadDialog> {
  final UpdateCancelToken _cancelToken = UpdateCancelToken();

  UpdateProgress _progress = const UpdateProgress(
    received: 0,
    total: null,
    bytesPerSecond: 0,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final navigator = Navigator.of(context);
    try {
      final cached = await widget.service.findCachedDownload(widget.release);
      final file = cached ??
          await widget.service.download(
            widget.release,
            onProgress: (progress) {
              if (mounted) {
                setState(() => _progress = progress);
              }
            },
            cancelToken: _cancelToken,
          );
      if (!mounted) {
        return;
      }
      navigator.pop(UpdateDownloadSucceeded(file));
    } on UpdateDownloadCanceled {
      if (mounted) {
        navigator.pop(const UpdateDownloadCanceledByUser());
      }
    } on Object catch (error, stackTrace) {
      debugPrint('[update] 下载失败: $error\n$stackTrace');
      if (mounted) {
        navigator.pop(UpdateDownloadFailed(describeUpdateError(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      // 返回键不直接关模态：置位取消令牌，由下载循环收尾（删除半成品）。
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _cancelToken.cancel();
        }
      },
      child: AlertDialog(
        title: const Text('正在下载更新'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.release.assetName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            LinearProgressIndicator(value: progressFraction(_progress)),
            const SizedBox(height: AppSpacing.s),
            Text(
              formatProgressLabel(_progress),
              style: AppTypography.tabularFigures(theme.textTheme.bodySmall!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _cancelToken.cancel,
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}

/// 对话框内的「标签 + 值」两列行（标签列等宽对齐）。
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;

  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
