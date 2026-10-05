import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'update_installer.dart';
import 'update_release.dart';
import 'update_service.dart';

/// 当前平台/架构（决定更新选包与弹窗展示）；当前系统不在发布矩阵内时为 null。
final updateTargetProvider = Provider<UpdateTarget?>(
  (ref) => detectUpdateTarget(),
);

/// 更新通道服务（检查 / 下载）。
///
/// 默认走 GitHub 发布网页；测试用 fake override，保证用例不触网。
final updateServiceProvider = Provider<UpdateService>(
  (ref) => GitHubUpdateService(target: ref.watch(updateTargetProvider)),
);

/// 安装包唤醒器（Android 平台通道 / Windows msiexec / macOS open）。
final updateInstallerProvider = Provider<UpdateInstaller>(
  (ref) => const UpdateInstaller(),
);

/// 会话内已忽略更新提示。
///
/// 启动静默检查命中新版本后用户点了「稍后」→ 置位，本次运行不再自动弹窗；
/// 设置页手动入口不读它（用户主动点的必须给结果）。
class UpdatePromptSnooze extends Notifier<bool> {
  @override
  bool build() => false;

  void snooze() => state = true;
}

final updatePromptSnoozedProvider =
    NotifierProvider<UpdatePromptSnooze, bool>(UpdatePromptSnooze.new);
