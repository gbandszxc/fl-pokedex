import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';

/// 六边形种族值雷达（design-ui.md §4，expanded 双栏详情用）。
///
/// 3 环网格（85 / 170 / 255，outlineVariant 细线）+ 6 轴线；数据多边形
/// primary 30% 填充 + primary 描边。顶点顺序：HP → 攻击 → 防御 → 特攻 →
/// 特防 → 速度（自顶部起顺时针）。单色克制，不引入属性色。
class StatRadar extends StatelessWidget {
  const StatRadar({
    super.key,
    required this.stats,
    this.size = 240,
    this.showValues = false,
  });

  final StatBlock stats;

  /// 画布边长（正方形）。
  final double size;

  /// 是否在顶点旁标注数值小标。
  final bool showValues;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StatRadarPainter(
          stats: stats,
          gridColor: scheme.outlineVariant,
          dataColor: scheme.primary,
          labelColor: scheme.onSurfaceVariant,
          showValues: showValues,
          textScaler: MediaQuery.textScalerOf(context),
        ),
      ),
    );
  }
}

class _StatRadarPainter extends CustomPainter {
  _StatRadarPainter({
    required this.stats,
    required this.gridColor,
    required this.dataColor,
    required this.labelColor,
    required this.showValues,
    required this.textScaler,
  });

  static const double _maxStat = 255;
  static const List<double> _rings = [85, 170, 255];

  final StatBlock stats;
  final Color gridColor;
  final Color dataColor;
  final Color labelColor;
  final bool showValues;
  final TextScaler textScaler;

  List<int> get _values => [
        stats.hp,
        stats.attack,
        stats.defense,
        stats.specialAttack,
        stats.specialDefense,
        stats.speed,
      ];

  // 顶点 i 的方向角：自顶部（-90°）起顺时针，每 60° 一个。
  double _angleOf(int i) => -math.pi / 2 + i * math.pi / 3;

  Offset _vertex(Offset center, double radius, int i) =>
      center + Offset.fromDirection(_angleOf(i), radius);

  Path _polygonAt(Offset center, double radius) => Path()
    ..addPolygon([
      for (var i = 0; i < 6; i++) _vertex(center, radius, i),
    ], true);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // showValues 时内缩，给顶点数值留出绘制空间。
    final radius = size.shortestSide / 2 - (showValues ? 14 : 0);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = gridColor
      ..isAntiAlias = true;

    // 3 环网格：85 / 170 / 255 等比映射到半径。
    for (final ring in _rings) {
      canvas.drawPath(
        _polygonAt(center, radius * ring / _maxStat),
        grid,
      );
    }

    // 6 条轴线。
    final axes = Path();
    for (var i = 0; i < 6; i++) {
      final v = _vertex(center, radius, i);
      axes
        ..moveTo(center.dx, center.dy)
        ..lineTo(v.dx, v.dy);
    }
    canvas.drawPath(axes, grid);

    // 数据多边形：primary 30% 填充 + primary 描边。
    final data = Path();
    for (var i = 0; i < 6; i++) {
      final ratio = (_values[i] / _maxStat).clamp(0.0, 1.0);
      final p = _vertex(center, radius * ratio, i);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(
      data,
      Paint()..color = dataColor.withValues(alpha: 0.30),
    );
    canvas.drawPath(
      data,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..color = dataColor,
    );

    if (showValues) {
      _paintValueLabels(canvas, center, radius);
    }
  }

  void _paintValueLabels(Canvas canvas, Offset center, double radius) {
    final style = AppTypography.tabularFigures(
      TextStyle(fontSize: 10, height: 1.2, color: labelColor),
    );
    for (var i = 0; i < 6; i++) {
      final direction = Offset.fromDirection(_angleOf(i));
      final pos =
          center + direction * (radius + 10) - direction * 4;
      final tp = TextPainter(
        text: TextSpan(text: '${_values[i]}', style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..textScaler = textScaler;
      tp.layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_StatRadarPainter oldDelegate) =>
      stats != oldDelegate.stats ||
      gridColor != oldDelegate.gridColor ||
      dataColor != oldDelegate.dataColor ||
      labelColor != oldDelegate.labelColor ||
      showValues != oldDelegate.showValues ||
      textScaler != oldDelegate.textScaler;
}
