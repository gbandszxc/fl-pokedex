/// 下载进度快照（下载模态回显的原始数据）。
class UpdateProgress {
  const UpdateProgress({
    required this.received,
    required this.total,
    required this.bytesPerSecond,
  });

  /// 已接收字节数。
  final int received;

  /// 总字节数；服务端未给 Content-Length 时为 null（进度条走不确定态）。
  final int? total;

  /// 瞬时下载速度（字节/秒）；未知为 0。
  final double bytesPerSecond;
}

/// 下载取消令牌：进度模态的「取消」/返回键置位，下载循环逐块检查。
class UpdateCancelToken {
  bool _canceled = false;

  bool get isCanceled => _canceled;

  void cancel() => _canceled = true;
}

/// 下载被用户取消（服务层用它把「取消」与「失败」区分开）。
class UpdateDownloadCanceled implements Exception {
  const UpdateDownloadCanceled();

  @override
  String toString() => 'UpdateDownloadCanceled: 更新下载已取消。';
}

/// 字节数 → `84.7 MB`（小于 1 MB 显示 KB）。
String formatBytes(int bytes) {
  final value = bytes < 0 ? 0 : bytes;
  if (value < 1024 * 1024) {
    return '${(value / 1024).toStringAsFixed(0)} KB';
  }
  return '${(value / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// 速度 → `4.2 MB/s`；未知（0）显示 `-- MB/s`。
String formatSpeed(double bytesPerSecond) {
  if (bytesPerSecond <= 0) {
    return '-- MB/s';
  }
  if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(0)} KB/s';
  }
  return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
}

/// 进度条比例（0..1）；总长未知返回 null（LinearProgressIndicator 不确定态）。
double? progressFraction(UpdateProgress progress) {
  final total = progress.total;
  if (total == null || total <= 0) {
    return null;
  }
  return (progress.received / total).clamp(0.0, 1.0);
}

/// 进度文案：`12.3 MB / 84.7 MB · 4.2 MB/s`（总长未知时不带分母）。
String formatProgressLabel(UpdateProgress progress) {
  final received = formatBytes(progress.received);
  final total = progress.total;
  final amount = (total == null || total <= 0)
      ? '已下载 $received'
      : '$received / ${formatBytes(total)}';
  return '$amount · ${formatSpeed(progress.bytesPerSecond)}';
}
