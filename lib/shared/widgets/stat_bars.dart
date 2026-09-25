import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';

/// 种族值居中发散条形（design-ui.md §4）。
///
/// 每行：标签 → 数值（tabular、宽固定）→ 条形区。条形从中轴基线
/// （outlineVariant 细线）向右延伸，长度 = 值 / 255，primary 蜜金单色、
/// 高 8、圆角 4。顶部右侧显示总和徽章（primaryContainer pill）。
/// **刻意不做六色进度条**（DESIGN.md §7：属性色/多彩禁令之外的单色克制）。
class StatBars extends StatelessWidget {
  const StatBars({super.key, required this.stats, this.compact = false});

  final StatBlock stats;

  /// 竖排紧凑档：行距与字号收紧，供双栏详情侧栏等窄区域使用。
  final bool compact;

  static const double _maxStat = 255;
  static const double _labelWidth = 36;
  static const double _valueWidth = 32;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final rows = [
      ('HP', stats.hp),
      ('攻击', stats.attack),
      ('防御', stats.defense),
      ('特攻', stats.specialAttack),
      ('特防', stats.specialDefense),
      ('速度', stats.speed),
    ];

    final labelStyle = (textTheme.labelMedium ?? const TextStyle()).copyWith(
      fontWeight: FontWeight.w500,
      color: scheme.onSurfaceVariant,
    );
    final valueStyle = AppTypography.tabularFigures(
      (textTheme.labelMedium ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('种族值', style: textTheme.titleSmall),
            const Spacer(),
            _TotalBadge(total: stats.total),
          ],
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.m),
        for (final (label, value) in rows)
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 2 : AppSpacing.xs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(label, style: labelStyle),
                ),
                SizedBox(
                  width: _valueWidth,
                  child: Text(
                    '$value',
                    style: valueStyle,
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _Bar(
                    ratio: (value / _maxStat).clamp(0.0, 1.0),
                    barColor: scheme.primary,
                    axisColor: scheme.outlineVariant,
                    barHeight: compact ? 6 : 8,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 总和徽章：primaryContainer 底 + onPrimaryContainer 字的全 pill。
class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: ShapeDecoration(
        color: scheme.primaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Text(
        '总和 $total',
        style: AppTypography.tabularFigures(
          Theme.of(context).textTheme.labelMedium ?? const TextStyle(),
        ).copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// 单行条形：左缘中轴基线细线 + 从基线向右延伸的圆角条。
class _Bar extends StatelessWidget {
  const _Bar({
    required this.ratio,
    required this.barColor,
    required this.axisColor,
    required this.barHeight,
  });

  /// 0–1，相对可用宽度的条形长度。
  final double ratio;

  final Color barColor;
  final Color axisColor;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight + 4,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // 中轴基线（比条形上下各高 2，读作轴而不是条的一部分）。
          Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 1, color: axisColor),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(barHeight / 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
