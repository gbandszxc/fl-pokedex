import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/update/update_flow.dart';
import 'providers.dart';

/// 关于区「检查更新」行（design-ui.md §8：版本号下方的手动更新入口）。
///
/// 点击后：检查 → 结果反馈（SnackBar / 更新对话框）→ 下载模态（进度 + 速度）
/// → 拉起系统安装流程；检查期间行尾图标换成小转圈并防重复点击。
class CheckUpdateRow extends ConsumerStatefulWidget {
  const CheckUpdateRow({super.key});

  @override
  ConsumerState<CheckUpdateRow> createState() => _CheckUpdateRowState();
}

class _CheckUpdateRowState extends ConsumerState<CheckUpdateRow> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      final version = await ref.read(appVersionProvider.future);
      if (!mounted) {
        return;
      }
      await runUpdateCheckFlow(
        context,
        ref,
        currentVersion: version,
        silent: false,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('检查更新失败: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('检查更新失败：$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('检查更新'),
      titleTextStyle: Theme.of(context).textTheme.bodyMedium,
      trailing: _checking
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, size: 20),
      onTap: _checking ? null : _check,
    );
  }
}
