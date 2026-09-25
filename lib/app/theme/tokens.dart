import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 几何 / 密度 / 动效 Token（DESIGN.md §3、§5 的唯一代码落点）。
///
/// UI 代码禁止硬编码间距 / 圆角 / 时长 / 曲线，一律引用本文件。
abstract final class AppSpacing {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// 页面水平留白（DESIGN.md §3：compact=16 / expanded=24）。
abstract final class AppPagePadding {
  static const double compact = 16;
  static const double expanded = 24;
}

/// 圆角（DESIGN.md §3；chip/badge 为全 pill，见组件主题）。
abstract final class AppRadius {
  static const double card = 14;
  static const double input = 10;
  static const double sheet = 20;
}

/// 动效时长与曲线（DESIGN.md §5，统一 easeOutCubic，禁止弹跳/回弹）。
abstract final class AppMotion {
  /// chip / 选中态切换。
  static const Duration fast = Duration(milliseconds: 150);

  /// 面板 / 页面进出。
  static const Duration normal = Duration(milliseconds: 220);

  /// 大图淡入。
  static const Duration slow = Duration(milliseconds: 300);

  /// 统一曲线。
  static const Curve curve = Curves.easeOutCubic;
}

/// 属性色上的自动前景（DESIGN.md §2：白 / 深由亮度决定）。
///
/// 注意：DESIGN.md §2 的显式前景表（[AppColors.typeForeground]）是权威；
/// 本 helper 仅用于表格之外的临时色值，取 WCAG 相对亮度阈值粗判。
Color typeFgOn(Color background) =>
    background.computeLuminance() > 0.45 ? AppColors.darkInk : Colors.white;

/// 固定字号阶梯的排版工具（DESIGN.md §4）。
abstract final class AppTypography {
  /// 数字与编号使用等宽数字（`FontFeature.tabularFigures`）。
  static TextStyle tabularFigures(TextStyle style) => style.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
