import 'package:flutter/material.dart';

/// 主题品牌种子色维度（DESIGN.md §1.1）。
///
/// 仅 primary 族与 secondary 族随 seed 切换；中性色（bg / surface 族 /
/// outline 族 / onSurface 族）、favorite、error、属性色全 seed 共用。
enum AppSeedColor {
  /// 琥珀（默认）。
  amber,

  /// 粉。
  rose,

  /// 墨绿。
  forest,

  /// 蓝。
  blue,

  /// 青。
  teal,

  /// 紫。
  violet,
}

/// DESIGN.md §1 / §2 的颜色 Token（唯一事实来源）。
///
/// UI 代码禁止硬编码颜色；一律取 [AppColors.light] / [AppColors.dark]
/// 语义字段或经主题（ColorScheme / AmberSemanticColors）间接引用。
/// 需要非琥珀品牌色时用 [AppColors.of]（amber 即 [AppColors.light] /
/// [AppColors.dark]，向后兼容）。
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

  /// 种子主色：选中、主按钮、焦点（amber seed = 蜂蜜琥珀 / 蜜金）。
  final Color primary;

  /// primary 之上的文字。
  final Color onPrimary;

  /// primary 弱底。
  final Color primaryContainer;

  /// primary 弱底上的文字。
  final Color onPrimaryContainer;

  /// 次级伴随色：链接、次级强调（amber seed = 墨青）。
  final Color secondary;

  /// secondary 之上的文字。
  final Color onSecondary;

  /// secondary 弱底。
  final Color secondaryContainer;

  /// secondary 弱底上的文字。
  final Color onSecondaryContainer;

  /// 收藏（心形）。
  final Color favorite;

  /// 错误。
  final Color error;

  /// error 之上的文字。
  final Color onError;

  // ---- 琥珀系中性梯度（DESIGN.md §1：全 seed 共用，const 中转便于复用）----

  static const Color _bgLight = Color(0xFFFFFFFF);
  static const Color _surfaceContainerLowLight = Color(0xFFF9F6F2);
  static const Color _surfaceContainerLight = Color(0xFFF3F0EA);
  static const Color _outlineVariantLight = Color(0xFFE1DED7);
  static const Color _outlineLight = Color(0xFFAAA49A);
  static const Color _onSurfaceLight = Color(0xFF221F19);
  static const Color _onSurfaceVariantLight = Color(0xFF5F5A52);
  static const Color _errorLight = Color(0xFFC92F33);
  static const Color _onErrorLight = Color(0xFFFFFFFF);
  static const Color _bgDark = Color(0xFF060606);
  static const Color _surfaceContainerLowDark = Color(0xFF110F0D);
  static const Color _surfaceContainerDark = Color(0xFF1A1814);
  static const Color _outlineVariantDark = Color(0xFF302D28);
  static const Color _outlineDark = Color(0xFF59554E);
  static const Color _onSurfaceDark = Color(0xFFEAE7E2);
  static const Color _onSurfaceVariantDark = Color(0xFFA19E98);
  static const Color _errorDark = Color(0xFFED756E);
  static const Color _onErrorDark = Color(0xFF060606);

  /// Light 语义 Token（DESIGN.md §1 Light 表）。
  static const AppColors light = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFFA26F00),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFF5DBA5),
    onPrimaryContainer: Color(0xFF4D2E00),
    secondary: Color(0xFF29616B),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCCE7EC),
    onSecondaryContainer: Color(0xFF05343D),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// Dark 语义 Token（DESIGN.md §1 Dark 表）。
  static const AppColors dark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFFE5B64A),
    onPrimary: Color(0xFF271700),
    primaryContainer: Color(0xFF5C3B00),
    onPrimaryContainer: Color(0xFFF3DBA9),
    secondary: Color(0xFF77BAC6),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF0A3A41),
    onSecondaryContainer: Color(0xFFC8E4E9),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  // ---- 品牌种子色表（DESIGN.md §1.1）----
  //
  // 仅 primary 族与 secondary 族随 [AppSeedColor] 切换；中性色与
  // favorite、error 全 seed 共用琥珀系中性梯度，直接引用上方 const。
  // 命名约定：light 模式饱和中亮度填充一律白字、浅弱底配深字；dark 反向。
  // secondary 为与 primary 协调但色相可区分的低饱和伴随色
  // （保证 TextButton 前景与 FilledButton 底色肉眼可辨）。

  /// 粉（rose）：secondary 黛蓝。
  static const AppColors _roseLight = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFFC0426F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFFFD9E2),
    onPrimaryContainer: Color(0xFF3E001D),
    secondary: Color(0xFF565E85),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFE0E1F9),
    onSecondaryContainer: Color(0xFF141B3C),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// 粉（rose，dark）。
  static const AppColors _roseDark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFFFFB1C8),
    onPrimary: Color(0xFF3E001D),
    primaryContainer: Color(0xFF5C1132),
    onPrimaryContainer: Color(0xFFFFD9E2),
    secondary: Color(0xFFB4C0E5),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF2C3355),
    onSecondaryContainer: Color(0xFFE0E1F9),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  /// 墨绿（forest）：secondary 墨赭。
  static const AppColors _forestLight = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFF2E6B4F),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB8F0D0),
    onPrimaryContainer: Color(0xFF00391F),
    secondary: Color(0xFF6D5433),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF3E2C7),
    onSecondaryContainer: Color(0xFF241A04),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// 墨绿（forest，dark）。
  static const AppColors _forestDark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFF8FD6B0),
    onPrimary: Color(0xFF00391F),
    primaryContainer: Color(0xFF1E4E36),
    onPrimaryContainer: Color(0xFFB8F0D0),
    secondary: Color(0xFFDCC29D),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF43341B),
    onSecondaryContainer: Color(0xFFF3E2C7),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  /// 蓝（blue）：secondary 陶土。
  static const AppColors _blueLight = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFF3B64C4),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBE2FF),
    onPrimaryContainer: Color(0xFF001A41),
    secondary: Color(0xFF7A4E3C),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4DFD4),
    onSecondaryContainer: Color(0xFF2E150A),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// 蓝（blue，dark）。
  static const AppColors _blueDark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFFA8C8FF),
    onPrimary: Color(0xFF002D6B),
    primaryContainer: Color(0xFF22447F),
    onPrimaryContainer: Color(0xFFDBE2FF),
    secondary: Color(0xFFEFB9A5),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF5B3B2B),
    onSecondaryContainer: Color(0xFFF4DFD4),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  /// 青（teal）：secondary 梅紫。
  static const AppColors _tealLight = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFF007B84),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB0ECF0),
    onPrimaryContainer: Color(0xFF002023),
    secondary: Color(0xFF6D4A62),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFF4DCEC),
    onSecondaryContainer: Color(0xFF2A1224),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// 青（teal，dark）。
  static const AppColors _tealDark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFF4FD8C6),
    onPrimary: Color(0xFF003733),
    primaryContainer: Color(0xFF00504F),
    onPrimaryContainer: Color(0xFFB0ECF0),
    secondary: Color(0xFFDCBFD4),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF54364A),
    onSecondaryContainer: Color(0xFFF4DCEC),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  /// 紫（violet）：secondary 苔绿。
  static const AppColors _violetLight = AppColors(
    bg: _bgLight,
    surfaceContainerLow: _surfaceContainerLowLight,
    surfaceContainer: _surfaceContainerLight,
    outlineVariant: _outlineVariantLight,
    outline: _outlineLight,
    onSurface: _onSurfaceLight,
    onSurfaceVariant: _onSurfaceVariantLight,
    primary: Color(0xFF6F42C1),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFE9DEFF),
    onPrimaryContainer: Color(0xFF250058),
    secondary: Color(0xFF55604E),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFDCE7D6),
    onSecondaryContainer: Color(0xFF131A10),
    favorite: favoriteLight,
    error: _errorLight,
    onError: _onErrorLight,
  );

  /// 紫（violet，dark）。
  static const AppColors _violetDark = AppColors(
    bg: _bgDark,
    surfaceContainerLow: _surfaceContainerLowDark,
    surfaceContainer: _surfaceContainerDark,
    outlineVariant: _outlineVariantDark,
    outline: _outlineDark,
    onSurface: _onSurfaceDark,
    onSurfaceVariant: _onSurfaceVariantDark,
    primary: Color(0xFFCFBCFF),
    onPrimary: Color(0xFF2A0054),
    primaryContainer: Color(0xFF471C8B),
    onPrimaryContainer: Color(0xFFE9DEFF),
    secondary: Color(0xFFC2CFB9),
    onSecondary: Color(0xFF060606),
    secondaryContainer: Color(0xFF3B4536),
    onSecondaryContainer: Color(0xFFDCE7D6),
    favorite: favoriteDark,
    error: _errorDark,
    onError: _onErrorDark,
  );

  /// 品牌级取表入口：按 seed × 亮度返回语义 Token 表。
  ///
  /// amber 即 [light] / [dark] 本体（逐字向后兼容）；其余 seed 复用琥珀系
  /// 中性梯度，仅替换 primary 族与 secondary 族。
  static AppColors of(AppSeedColor seed, Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    return switch (seed) {
      AppSeedColor.amber => isLight ? light : dark,
      AppSeedColor.rose => isLight ? _roseLight : _roseDark,
      AppSeedColor.forest => isLight ? _forestLight : _forestDark,
      AppSeedColor.blue => isLight ? _blueLight : _blueDark,
      AppSeedColor.teal => isLight ? _tealLight : _tealDark,
      AppSeedColor.violet => isLight ? _violetLight : _violetDark,
    };
  }

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
