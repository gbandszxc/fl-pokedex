import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/update/update_flow.dart';
import '../features/settings/providers.dart';

/// 应用启动时执行一次静默检查更新（PRODUCT.md：失败与「已是最新」都不打扰）。
///
/// 挂在外壳首帧之后，只跑一次；命中新版本才弹更新对话框（用户点「稍后」后
/// 本次运行不再自动提示）。放在 app 层是因为它同时依赖 core/update 的流程与
/// settings 的 [appVersionProvider]。
class UpdateStartupCheck extends ConsumerStatefulWidget {
  const UpdateStartupCheck({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<UpdateStartupCheck> createState() => _UpdateStartupCheckState();
}

class _UpdateStartupCheckState extends ConsumerState<UpdateStartupCheck> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_checkSilently()),
    );
  }

  Future<void> _checkSilently() async {
    if (!mounted) {
      return;
    }
    try {
      final version = await ref.read(appVersionProvider.future);
      if (!mounted) {
        return;
      }
      await runUpdateCheckFlow(
        context,
        ref,
        currentVersion: version,
        silent: true,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('[update] 启动检查更新失败（静默）: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
