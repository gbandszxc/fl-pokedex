import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';

/// 游戏版本 / 版本组选择 chip。
///
/// 选中：primary 填充 + onPrimary 文字；未选中：透明底 + outlineVariant
/// 描边 + onSurfaceVariant 文字。用于版本图鉴说明与招式版本组切换。
class VersionChip extends StatelessWidget {
  const VersionChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;

  final bool selected;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : Colors.transparent,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 13,
              height: 18 / 13,
              fontWeight: FontWeight.w500,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
