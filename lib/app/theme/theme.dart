import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'tokens.dart';

export 'app_colors.dart';
export 'tokens.dart';

/// 自定义语义色扩展：暂只承载 favorite（收藏心形）。
///
/// 后续新增"表格里有但 ColorScheme 无槽位"的语义色时加到这里。
class AmberSemanticColors extends ThemeExtension<AmberSemanticColors> {
  const AmberSemanticColors({required this.favorite});

  final Color favorite;

  static const AmberSemanticColors light = AmberSemanticColors(
    favorite: AppColors.favoriteLight,
  );

  static const AmberSemanticColors dark = AmberSemanticColors(
    favorite: AppColors.favoriteDark,
  );

  @override
  AmberSemanticColors copyWith({Color? favorite}) => AmberSemanticColors(
        favorite: favorite ?? this.favorite,
      );

  @override
  AmberSemanticColors lerp(ThemeExtension<AmberSemanticColors>? other, double t) {
    if (other is! AmberSemanticColors) {
      return this;
    }
    return AmberSemanticColors(
      favorite: Color.lerp(favorite, other.favorite, t)!,
    );
  }
}

/// 品牌级取色入口：组件从这里拿 favorite（心形）等自定义语义色。
///
/// 用法：`AppBrand.favoriteOf(context)`。
abstract final class AppBrand {
  static Color favoriteOf(BuildContext context) {
    final semantic = Theme.of(context).extension<AmberSemanticColors>();
    if (semantic != null) {
      return semantic.favorite;
    }
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.light.favorite
        : AppColors.dark.favorite;
  }
}

/// Material 3 浅色主题（DESIGN.md §1 Light 表 → ColorScheme）。
///
/// [seed] 选择品牌种子色（默认琥珀）；中性梯度随 seed hue 派生，favorite/error 全 seed 固定。
ThemeData buildLightTheme({AppSeedColor seed = AppSeedColor.amber}) => _buildTheme(
      Brightness.light,
      AppColors.of(seed, Brightness.light),
      AppColors.of(seed, Brightness.dark).primary,
      AmberSemanticColors.light,
    );

/// Material 3 深色主题（DESIGN.md §1 Dark 表 → ColorScheme）。
///
/// [seed] 选择品牌种子色（默认琥珀）；中性梯度随 seed hue 派生，favorite/error 全 seed 固定。
ThemeData buildDarkTheme({AppSeedColor seed = AppSeedColor.amber}) => _buildTheme(
      Brightness.dark,
      AppColors.of(seed, Brightness.dark),
      AppColors.of(seed, Brightness.light).primary,
      AmberSemanticColors.dark,
    );

ThemeData _buildTheme(
  Brightness brightness,
  AppColors c,
  Color inversePrimary,
  AmberSemanticColors semantic,
) {
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    primaryContainer: c.primaryContainer,
    onPrimaryContainer: c.onPrimaryContainer,
    secondary: c.secondary,
    onSecondary: c.onSecondary,
    secondaryContainer: c.secondaryContainer,
    onSecondaryContainer: c.onSecondaryContainer,
    error: c.error,
    onError: c.onError,
    surface: c.bg,
    onSurface: c.onSurface,
    // DESIGN.md 只定义 Low / Container 两档容器色；High/Highest 复用
    // Container，保持"近中性纸面分层"策略，不引入新色值。
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surfaceContainerLow,
    surfaceContainer: c.surfaceContainer,
    surfaceContainerHigh: c.surfaceContainer,
    surfaceContainerHighest: c.surfaceContainer,
    onSurfaceVariant: c.onSurfaceVariant,
    outline: c.outline,
    outlineVariant: c.outlineVariant,
    inverseSurface: c.onSurface,
    onInverseSurface: c.bg,
    // 同 seed 对侧亮度的 primary（DESIGN.md §1.1：品牌族随 seed 成对切换）。
    inversePrimary: inversePrimary,
    surfaceTint: Colors.transparent,
    surfaceDim: brightness == Brightness.light ? c.surfaceContainer : c.bg,
    surfaceBright: c.bg,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    extensions: [semantic],
    textTheme: _buildTextTheme(c),
    iconTheme: IconThemeData(color: c.onSurface),
    dividerTheme: DividerThemeData(color: c.outlineVariant, thickness: 1),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: _t(22, 28, FontWeight.w600, c.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: c.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? c.onPrimaryContainer
                : c.onSurfaceVariant,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => _t(
            12,
            16,
            states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
            states.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
          )),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.surfaceContainerLow,
      elevation: 0,
      indicatorColor: c.primaryContainer,
      useIndicator: true,
      selectedIconTheme: IconThemeData(color: c.onPrimaryContainer),
      unselectedIconTheme: IconThemeData(color: c.onSurfaceVariant),
      selectedLabelTextStyle: _t(12, 16, FontWeight.w600, c.onSurface),
      unselectedLabelTextStyle: _t(12, 16, FontWeight.w500, c.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      color: c.surfaceContainer,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: _buildChipTheme(c),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: c.surfaceContainerLow,
      hintStyle: _t(15, 22, FontWeight.w400, c.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s + 2,
      ),
      border: _inputBorder(c.outlineVariant),
      enabledBorder: _inputBorder(c.outlineVariant),
      focusedBorder: _inputBorder(c.primary, width: 2),
      disabledBorder: _inputBorder(c.outlineVariant),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        )),
        side: WidgetStatePropertyAll(BorderSide(color: c.outlineVariant)),
        backgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.primaryContainer : Colors.transparent),
        foregroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? c.onPrimaryContainer : c.onSurfaceVariant),
        textStyle: WidgetStatePropertyAll(_t(13, 18, FontWeight.w500, c.onSurface)),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: c.primary,
      unselectedLabelColor: c.onSurfaceVariant,
      indicatorColor: c.primary,
      dividerColor: c.outlineVariant,
      labelStyle: _t(15, 22, FontWeight.w500, c.primary),
      unselectedLabelStyle: _t(15, 22, FontWeight.w500, c.onSurfaceVariant),
      indicatorSize: TabBarIndicatorSize.label,
      overlayColor: WidgetStatePropertyAll(c.surfaceContainerLow),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(c.primary),
        foregroundColor: WidgetStatePropertyAll(c.onPrimary),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        )),
        textStyle: WidgetStatePropertyAll(_t(15, 22, FontWeight.w500, c.onPrimary)),
        padding: WidgetStatePropertyAll(const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.s + 2,
        )),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(c.secondary),
        textStyle: WidgetStatePropertyAll(_t(15, 22, FontWeight.w500, c.secondary)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      titleTextStyle: _t(17, 24, FontWeight.w600, c.onSurface),
      contentTextStyle: _t(15, 22, FontWeight.w400, c.onSurface),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surfaceContainer,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
      dragHandleColor: c.outlineVariant,
    ),
  );
}

/// chip/badge 全 pill；选中态琥珀底白字（DESIGN.md：选中 primary）。
ChipThemeData _buildChipTheme(AppColors c) {
  return ChipThemeData(
    shape: const StadiumBorder(),
    side: BorderSide(color: c.outlineVariant),
    backgroundColor: c.surfaceContainer,
    selectedColor: c.primary,
    checkmarkColor: c.onPrimary,
    disabledColor: c.surfaceContainer,
    elevation: 0,
    pressElevation: 0,
    labelStyle: _ChipLabelStyle(
      unselected: c.onSurfaceVariant,
      selected: c.onPrimary,
    ),
  );
}

OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: BorderSide(color: color, width: width),
    );

/// DESIGN.md §4 固定字号阶梯铺满 M3 槽位（比率 ≈1.18，不随窗口缩放）：
/// display 32/38 w600 · title 22/28 w600 · heading 17/24 w600 ·
/// body 15/22 w400 · label 13/18 w500 · caption 12/16 w400。
TextTheme _buildTextTheme(AppColors c) {
  TextStyle t(double size, double lineHeight, FontWeight w, Color color) =>
      _t(size, lineHeight, w, color);

  return TextTheme(
    displayLarge: t(32, 38, FontWeight.w600, c.onSurface),
    displayMedium: t(32, 38, FontWeight.w600, c.onSurface),
    displaySmall: t(32, 38, FontWeight.w600, c.onSurface),
    headlineLarge: t(22, 28, FontWeight.w600, c.onSurface),
    headlineMedium: t(22, 28, FontWeight.w600, c.onSurface),
    headlineSmall: t(17, 24, FontWeight.w600, c.onSurface),
    titleLarge: t(22, 28, FontWeight.w600, c.onSurface),
    titleMedium: t(17, 24, FontWeight.w600, c.onSurface),
    titleSmall: t(15, 22, FontWeight.w500, c.onSurface),
    bodyLarge: t(15, 22, FontWeight.w400, c.onSurface),
    bodyMedium: t(15, 22, FontWeight.w400, c.onSurface),
    bodySmall: t(12, 16, FontWeight.w400, c.onSurfaceVariant),
    labelLarge: t(13, 18, FontWeight.w500, c.onSurface),
    labelMedium: t(12, 16, FontWeight.w500, c.onSurfaceVariant),
    labelSmall: t(12, 16, FontWeight.w500, c.onSurfaceVariant),
  );
}

TextStyle _t(double size, double lineHeight, FontWeight w, Color color) => TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: w,
      color: color,
    );

/// chip 文字：未选中次级墨色 / 选中 onPrimary（白）。
class _ChipLabelStyle extends WidgetStateTextStyle {
  const _ChipLabelStyle({required this.unselected, required this.selected});

  final Color unselected;
  final Color selected;

  @override
  TextStyle resolve(Set<WidgetState> states) {
    if (states.contains(WidgetState.selected)) {
      return TextStyle(color: selected, fontWeight: FontWeight.w500);
    }
    return TextStyle(color: unselected, fontWeight: FontWeight.w500);
  }
}
