import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';

/// 进化条件 pill：secondaryContainer 底 + onSecondaryContainer 字。
///
/// 如〔Lv.16〕〔亲密度 220〕〔王者之证+交换〕（design-ui.md §5）。
class ConditionChip extends StatelessWidget {
  const ConditionChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: ShapeDecoration(
        color: scheme.secondaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}
