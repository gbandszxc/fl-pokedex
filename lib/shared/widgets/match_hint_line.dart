import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';

/// 搜索 / 跨形态筛选命中原因轻提示行：
///
/// 按中文冒号 `：` 将 `前缀：内容` 拆为「微胶囊前缀 + 次级文本」两段，
/// 对齐卡片/列表行底部的 [TypeBadge] 语言与暖色主题体系；缺少合法分隔符时
/// 退化为单行次级文本。胶囊高 16px，与 `bodySmall`（12/16）同高不增行高。
class MatchHintLine extends StatelessWidget {
  const MatchHintLine({
    super.key,
    required this.hint,
  });

  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sep = hint.indexOf('：');
    if (sep <= 0 || sep >= hint.length - 1) {
      return Text(
        hint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.bodySmall,
      );
    }

    final tag = hint.substring(0, sep);
    final value = hint.substring(sep + 1);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.xs / 2,
          ),
          decoration: ShapeDecoration(
            color: scheme.primaryContainer,
            shape: const StadiumBorder(),
          ),
          child: Text(
            tag,
            maxLines: 1,
            style: (textTheme.labelSmall ?? const TextStyle()).copyWith(
              fontSize: 10,
              height: 1.2,
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}
