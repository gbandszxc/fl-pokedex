import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';

/// 进化条件 / 检索标签 pill：secondaryContainer 底 + onSecondaryContainer 字。
///
/// 如〔Lv.16〕〔亲密度 220〕〔王者之证+交换〕（design-ui.md §5）或〔化石宝可梦〕。
class ConditionChip extends StatelessWidget {
  const ConditionChip({
    super.key,
    required this.label,
    this.onTap,
    this.tooltip,
    this.maxLines = 1,
    this.textAlign,
  });

  final String label;
  final VoidCallback? onTap;
  final String? tooltip;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.s,
      vertical: AppSpacing.xs / 2,
    );
    final labelText = Text(
      label,
      maxLines: maxLines,
      softWrap: maxLines != 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
    );
    final Widget chip = onTap == null
        ? Container(
            padding: padding,
            decoration: ShapeDecoration(
              color: scheme.secondaryContainer,
              shape: const StadiumBorder(),
            ),
            child: labelText,
          )
        : Material(
            color: scheme.secondaryContainer,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const StadiumBorder(),
              child: Padding(padding: padding, child: labelText),
            ),
          );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}
