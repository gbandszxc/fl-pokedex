import 'package:flutter/material.dart';

/// 区块标题：heading（17/24 w600）+ 可选尾部操作。
class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.action,
  });

  final String title;

  /// 尾部操作（如「查看全部」TextButton），可为 null。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}
