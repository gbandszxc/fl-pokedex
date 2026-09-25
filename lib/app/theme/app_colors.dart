import 'package:flutter/material.dart';

/// DESIGN.md §1 / §2 的颜色 Token（唯一事实来源）。
///
/// UI 代码禁止硬编码颜色；一律取 [AppColors.light] / [AppColors.dark]
/// 语义字段或经主题（ColorScheme / AmberSemanticColors）间接引用。
class AppColors {
  const AppColors({
    required this.bg,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.outlineVariant,
    required this.outline,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.favorite,
    required this.error,
    required this.onError,
  });

  /// 页面底色。
  final Color bg;

  /// 输入框、次级面板。
  final Color surfaceContainerLow;

  /// 卡片、栏容器。
  final Color surfaceContainer;

  /// 分隔线、描边弱。
  final Color outlineVariant;

  /// 描边强。
  final Color outline;

  /// 正文。
  final Color onSurface;

  /// 次级文字。
  final Color onSurfaceVariant;

  /// 蜂蜜琥珀 / 蜜金：选中、主按钮、焦点。
  final Color primary;

  /// primary 之上的文字。
  final Color onPrimary;

  /// 琥珀弱底。
  final Color primaryContainer;

  /// 琥珀弱底上的文字。
  final Color onPrimaryContainer;

  /// 墨青：链接、次级强调。
  final Color secondary;

  /// secondary 之上的文字。
  final Color onSecondary;

  /// 墨青弱底。
  final Color secondaryContainer;

  /// 墨青弱底上的文字。
  final Color onSecondaryContainer;

  /// 收藏（心形）。
  final Color favorite;

  /// 错误。
  final Color error;

  /// error 之上的文字。
  final Color onError;

  /// Light 语义 Token（DESIGN.md §1 Light 表）。
  static const AppColors light = AppColors(
    bg: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF9F6F2),
    surfaceContainer: Color(0xFFF3F0EA),
    outlineVariant: Color(0xFFE1DED7),
    outline: Color(0xFFAAA49A),
    onSurface: Color(0xFF221F19),
    onSurfaceVariant: Color(0xFF5F5A52),
    primary: Color(0xFFA26F00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5DBA5),
    onPrimaryContainer: Color(0xFF4D2E00),
    secondary: Color(0xFF29616B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCE7EC),
    onSecondaryContainer: Color(0xFF05343D),
    favorite: favoriteLight,
    error: Color(0xFFC92F33),
    onError: Color(0xFFFFFFFF),
  );

  /// Dark 语义 Token（DESIGN.md §1 Dark 表）。
  static const AppColors dark = AppColors(
    bg: Color(0xFF060606),
    surfaceContainerLow: Color(0xFF110F0D),
    surfaceContainer: Color(0xFF1A1814),
    outlineVariant: Color(0xFF302D28),
    outline: Color(0xFF59554E),
    onSurface: Color(0xFFEAE7E2),
    onSurfaceVariant: Color(0xFFA19E98),
    primary: Color(0xFFE5B64A),
    onPrimary: Color(0xFF271700),
    primaryContainer: Color(0xFF5C3B00),
    onPrimaryContainer: Color(0xFFF3DBA9),
    secondary: Color(0xFF77BAC6),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF0A3A41),
    onSecondaryContainer: Color(0xFFC8E4E9),
    favorite: favoriteDark,
    error: Color(0xFFED756E),
    onError: Color(0xFF060606),
  );

  /// 正文墨色（DESIGN.md §1 onSurface 的 light 值）。
  ///
  /// 用作浅色属性徽章上的"深字"（DESIGN.md §2 前景列 dark）。
  static const Color darkInk = Color(0xFF221F19);

  /// 收藏色（light）——const 中转，供 ThemeExtension 等常量场景引用。
  static const Color favoriteLight = Color(0xFFD23855);

  /// 收藏色（dark）——const 中转，供 ThemeExtension 等常量场景引用。
  static const Color favoriteDark = Color(0xFFF87584);

  /// 18 属性徽章底色，键为 identifier（snake 全小写，如 "fire"）。
  static const Map<String, Color> typeColors = {
    'normal': Color(0xFF7B705E),
    'fire': Color(0xFFD05320),
    'water': Color(0xFF3082B5),
    'electric': Color(0xFFE3C23B),
    'grass': Color(0xFF4E9A52),
    'ice': Color(0xFF87CBD7),
    'fighting': Color(0xFFB8492E),
    'poison': Color(0xFF9553A4),
    'ground': Color(0xFFB99056),
    'flying': Color(0xFF7E9FD7),
    'psychic': Color(0xFFC96598),
    'bug': Color(0xFF869A3E),
    'rock': Color(0xFFA0783E),
    'ghost': Color(0xFF725B9A),
    'dragon': Color(0xFF4F679D),
    'dark': Color(0xFF3A4258),
    'steel': Color(0xFF6197CD),
    'fairy': Color(0xFFE4A0BF),
  };

  /// 属性徽章前景色（DESIGN.md §2 前景列，white/dark 显式声明）。
  ///
  /// dark 前景取正文墨色 [darkInk]；此表为权威，
  /// 表外色值可用 tokens.dart 的 [typeFgOn] 粗判。
  static const Map<String, Color> typeForeground = {
    'normal': Colors.white,
    'fire': Colors.white,
    'water': Colors.white,
    'electric': darkInk,
    'grass': Colors.white,
    'ice': darkInk,
    'fighting': Colors.white,
    'poison': Colors.white,
    'ground': Colors.white,
    'flying': darkInk,
    'psychic': Colors.white,
    'bug': Colors.white,
    'rock': Colors.white,
    'ghost': Colors.white,
    'dragon': Colors.white,
    'dark': Colors.white,
    'steel': Colors.white,
    'fairy': darkInk,
  };
}
