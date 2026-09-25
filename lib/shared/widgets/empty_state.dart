import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';

/// 空状态：图标（outline 风格）+ 标题 + 指引文案 + 可选操作按钮。
///
/// 遵循 PRODUCT.md register：空状态必须给出下一步指引，
/// 如「没有匹配的宝可梦 / 试试清除筛选条件」。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.search_off,
    this.action,
  });

  final String title;

  /// 指引文案（告诉用户下一步做什么）。
  final String message;

  /// outline 风格图标。
  final IconData icon;

  /// 可选操作入口（如「清除筛选条件」TextButton）。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: ShapeDecoration(
                color: scheme.surfaceContainerLow,
                shape: const CircleBorder(),
              ),
              child: Icon(icon, size: 32, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.m),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.m),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
