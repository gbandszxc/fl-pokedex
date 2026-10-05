import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 打开安装包的结果。
enum UpdateInstallOutcome {
  /// 已拉起系统安装流程（Android 安装器 / Windows Installer / macOS 磁盘映像）。
  started,

  /// Android 8.0+ 未授予「安装未知应用」权限，需要先跳系统设置授权。
  permissionRequired,

  /// 当前系统没有自动安装实现（安装包已下载，按文件路径提示用户）。
  unsupportedPlatform,

  /// 拉起失败（文件缺失 / 系统拒绝）。
  failed,
}

/// 把下载好的安装包交给系统安装流程。
///
/// - Android：MethodChannel 到宿主（FileProvider content:// + ACTION_VIEW），
///   安装由系统包安装器完成，进程不写任何文件；
/// - Windows：`msiexec /i <msi>` 拉起 Windows Installer（perMachine 安装会走
///   UAC），随后退出本应用——安装器要替换正在运行的 exe，应用不退会让
///   Restart Manager 卡在「文件被占用」；
/// - macOS：`open <dmg>` 在访达挂载磁盘映像，由用户拖入应用程序。
class UpdateInstaller {
  const UpdateInstaller();

  /// 与 android/app/src/main/kotlin/.../MainActivity.kt 中的通道名一致。
  static const MethodChannel _channel = MethodChannel(
    'com.github.gbandszxc.fl_pokedex/update_installer',
  );

  /// Windows 安装器启动后留给 UI 提示的时间，随后退出应用。
  static const Duration _quitDelay = Duration(milliseconds: 1500);

  Future<UpdateInstallOutcome> open(File file) async {
    try {
      if (Platform.isAndroid) {
        return await _openOnAndroid(file);
      }
      if (Platform.isWindows) {
        await Process.start('msiexec.exe', ['/i', file.path]);
        unawaited(
          Future<void>.delayed(_quitDelay, () => exit(0)),
        );
        return UpdateInstallOutcome.started;
      }
      if (Platform.isMacOS) {
        await Process.start('open', [file.path]);
        return UpdateInstallOutcome.started;
      }
      return UpdateInstallOutcome.unsupportedPlatform;
    } on Object catch (error, stackTrace) {
      debugPrint('[update] 拉起安装程序失败: $error\n$stackTrace');
      return UpdateInstallOutcome.failed;
    }
  }

  /// 跳系统「安装未知应用」授权页（Android 8.0+）。
  Future<bool> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) {
      return false;
    }
    try {
      final opened = await _channel.invokeMethod<bool>(
        'openInstallPermissionSettings',
      );
      return opened ?? false;
    } on Object catch (error, stackTrace) {
      debugPrint('[update] 打开安装权限设置失败: $error\n$stackTrace');
      return false;
    }
  }

  Future<UpdateInstallOutcome> _openOnAndroid(File file) async {
    final result = await _channel.invokeMethod<String>(
      'installApk',
      <String, Object?>{'path': file.path},
    );
    return switch (result) {
      'started' => UpdateInstallOutcome.started,
      'permission_required' => UpdateInstallOutcome.permissionRequired,
      _ => UpdateInstallOutcome.failed,
    };
  }
}
