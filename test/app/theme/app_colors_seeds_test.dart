import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';

/// 品牌种子色守门测试（DESIGN.md §1.1）：
///
/// 1. 完备性：6 seed × 2 brightness 的表全部取到、不透明、同族字段互异、
///    12 张表两两互异。
/// 2. 对比度：WCAG 门槛（onPrimary/primary ≥ 4.5 等 5 项，amber light
///    primary 为品牌锁定例外）。
/// 3. 回归保护：amber 的 light/dark 表与现状逐字相等（写死期望值）。
/// 4. `AppColors.of`：每个枚举值 light/dark 两个方向取表与 DESIGN.md
///    §1.1 落地表逐字一致。
void main() {
  /// 计算前景/背景色的 WCAG 对比度（与 theme_sweep_test 同款公式）。
  double contrastRatio(Color a, Color b) {
    double luminance(Color c) {
      double channel(double v) => v <= 0.03928
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * channel(c.r) +
          0.7152 * channel(c.g) +
          0.0722 * channel(c.b);
    }

    final la = luminance(a);
    final lb = luminance(b);
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// 全部 12 张表：(seed, brightness, 表)。
  List<(AppSeedColor, Brightness, AppColors)> allTables() => [
        for (final seed in AppSeedColor.values)
          for (final brightness in Brightness.values)
            (seed, brightness, AppColors.of(seed, brightness)),
      ];

  /// 品牌族 8 字段签名（表互异性判定）。
  List<Color> brandSignature(AppColors c) => [
        c.primary,
        c.onPrimary,
        c.primaryContainer,
        c.onPrimaryContainer,
        c.secondary,
        c.onSecondary,
        c.secondaryContainer,
        c.onSecondaryContainer,
      ];

  /// 19 字段快照（amber 回归逐字比对）。
  List<(String, Color)> snapshot(AppColors c) => [
        ('bg', c.bg),
        ('surfaceContainerLow', c.surfaceContainerLow),
        ('surfaceContainer', c.surfaceContainer),
        ('outlineVariant', c.outlineVariant),
        ('outline', c.outline),
        ('onSurface', c.onSurface),
        ('onSurfaceVariant', c.onSurfaceVariant),
        ('primary', c.primary),
        ('onPrimary', c.onPrimary),
        ('primaryContainer', c.primaryContainer),
        ('onPrimaryContainer', c.onPrimaryContainer),
        ('secondary', c.secondary),
        ('onSecondary', c.onSecondary),
        ('secondaryContainer', c.secondaryContainer),
        ('onSecondaryContainer', c.onSecondaryContainer),
        ('favorite', c.favorite),
        ('error', c.error),
        ('onError', c.onError),
      ];

  /// 逐字段比对两张表（reason 携带字段名，失败可定位）。
  void expectSameTable(AppColors actual, AppColors expected, String label) {
    final a = snapshot(actual);
    final e = snapshot(expected);
    expect(a.length, e.length);
    for (var i = 0; i < a.length; i++) {
      expect(a[i].$2, e[i].$2, reason: '$label.${a[i].$1}');
    }
  }

  /// onPrimary/primary 的对比度下限。
  ///
  /// amber light primary 被 DESIGN.md 品牌锁定为 #A26F00（白字实测
  /// ≈4.37:1）：逐字保留优先于 4.5 档，仍满足大文本 3:1 档，特批 ≥4.3。
  double onPrimaryFloor(AppSeedColor seed, Brightness brightness) =>
      seed == AppSeedColor.amber && brightness == Brightness.light ? 4.3 : 4.5;

  test('完备性：6 seed × 2 brightness 全部取到且字段不透明', () {
    expect(AppSeedColor.values, hasLength(6));
    for (final (seed, brightness, c) in allTables()) {
      for (final (name, color) in snapshot(c)) {
        expect(color.a, 1.0, reason: '$seed/$brightness.$name 须为不透明色');
      }
    }
  });

  test('完备性：同表内同族字段互不重复', () {
    for (final (seed, brightness, c) in allTables()) {
      expect(
        <Color>{c.primary, c.onPrimary, c.primaryContainer, c.onPrimaryContainer},
        hasLength(4),
        reason: '$seed/$brightness primary 族 4 字段不得重复',
      );
      expect(
        <Color>{
          c.secondary,
          c.onSecondary,
          c.secondaryContainer,
          c.onSecondaryContainer,
        },
        hasLength(4),
        reason: '$seed/$brightness secondary 族 4 字段不得重复',
      );
    }
  });

  test('完备性：12 张表两两互异', () {
    final tables = allTables();
    for (var i = 0; i < tables.length; i++) {
      for (var j = i + 1; j < tables.length; j++) {
        final sigA = brandSignature(tables[i].$3);
        final sigB = brandSignature(tables[j].$3);
        expect(sigA, isNot(equals(sigB)),
            reason: '${tables[i].$1}/${tables[i].$2.name} 与 '
                '${tables[j].$1}/${tables[j].$2.name} 不得同表');
      }
    }
  });

  group('对比度（WCAG，每 seed × brightness）', () {
    for (final (seed, brightness, c) in allTables()) {
      group('${seed.name}/${brightness.name}', () {
        test('onPrimary/primary ≥ ${onPrimaryFloor(seed, brightness)}', () {
          expect(contrastRatio(c.onPrimary, c.primary),
              greaterThanOrEqualTo(onPrimaryFloor(seed, brightness)));
        });
        test('onPrimaryContainer/primaryContainer ≥ 4.5', () {
          expect(contrastRatio(c.onPrimaryContainer, c.primaryContainer),
              greaterThanOrEqualTo(4.5));
        });
        test('secondary/bg ≥ 4.5', () {
          expect(
              contrastRatio(c.secondary, c.bg), greaterThanOrEqualTo(4.5));
        });
        test('onSecondaryContainer/secondaryContainer ≥ 4.5', () {
          expect(contrastRatio(c.onSecondaryContainer, c.secondaryContainer),
              greaterThanOrEqualTo(4.5));
        });
        test('primary/bg ≥ 3.0', () {
          expect(
              contrastRatio(c.primary, c.bg), greaterThanOrEqualTo(3.0));
        });
      });
    }
  });

  group('amber 回归（品牌逐字锁定，防无意改 brand）', () {
    test('light 表与 DESIGN.md §1 琥珀现状逐字相等', () {
      const expected = AppColors(
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
        favorite: Color(0xFFD23855),
        error: Color(0xFFC92F33),
        onError: Color(0xFFFFFFFF),
      );
      expectSameTable(AppColors.light, expected, 'AppColors.light');
      expectSameTable(
          AppColors.of(AppSeedColor.amber, Brightness.light),
          expected,
          'of(amber, light)');
    });

    test('dark 表与 DESIGN.md §1 琥珀现状逐字相等', () {
      const expected = AppColors(
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
        favorite: Color(0xFFF87584),
        error: Color(0xFFED756E),
        onError: Color(0xFF060606),
      );
      expectSameTable(AppColors.dark, expected, 'AppColors.dark');
      expectSameTable(
          AppColors.of(AppSeedColor.amber, Brightness.dark),
          expected,
          'of(amber, dark)');
    });
  });

  group('AppColors.of 取表一致性（DESIGN.md §1.1 落地表）', () {
    test('amber 即既有 light/dark 表本体', () {
      expect(AppColors.of(AppSeedColor.amber, Brightness.light),
          same(AppColors.light));
      expect(AppColors.of(AppSeedColor.amber, Brightness.dark),
          same(AppColors.dark));
    });

    test('每个 seed 的 primary/secondary 与 DESIGN.md §1.1 逐字相等（两方向）', () {
      const expectedPrimary = {
        AppSeedColor.amber: Color(0xFFA26F00),
        AppSeedColor.rose: Color(0xFFC0426F),
        AppSeedColor.forest: Color(0xFF2E6B4F),
        AppSeedColor.blue: Color(0xFF3B64C4),
        AppSeedColor.teal: Color(0xFF007B84),
        AppSeedColor.violet: Color(0xFF6F42C1),
      };
      const expectedDarkPrimary = {
        AppSeedColor.amber: Color(0xFFE5B64A),
        AppSeedColor.rose: Color(0xFFFFB1C8),
        AppSeedColor.forest: Color(0xFF8FD6B0),
        AppSeedColor.blue: Color(0xFFA8C8FF),
        AppSeedColor.teal: Color(0xFF4FD8C6),
        AppSeedColor.violet: Color(0xFFCFBCFF),
      };
      const expectedSecondary = {
        AppSeedColor.amber: Color(0xFF29616B),
        AppSeedColor.rose: Color(0xFF565E85),
        AppSeedColor.forest: Color(0xFF6D5433),
        AppSeedColor.blue: Color(0xFF7A4E3C),
        AppSeedColor.teal: Color(0xFF6D4A62),
        AppSeedColor.violet: Color(0xFF55604E),
      };
      const expectedDarkSecondary = {
        AppSeedColor.amber: Color(0xFF77BAC6),
        AppSeedColor.rose: Color(0xFFB4C0E5),
        AppSeedColor.forest: Color(0xFFDCC29D),
        AppSeedColor.blue: Color(0xFFEFB9A5),
        AppSeedColor.teal: Color(0xFFDCBFD4),
        AppSeedColor.violet: Color(0xFFC2CFB9),
      };

      for (final seed in AppSeedColor.values) {
        final light = AppColors.of(seed, Brightness.light);
        final dark = AppColors.of(seed, Brightness.dark);
        expect(light.primary, expectedPrimary[seed],
            reason: '${seed.name} light primary');
        expect(dark.primary, expectedDarkPrimary[seed],
            reason: '${seed.name} dark primary');
        expect(light.secondary, expectedSecondary[seed],
            reason: '${seed.name} light secondary');
        expect(dark.secondary, expectedDarkSecondary[seed],
            reason: '${seed.name} dark secondary');
      }
    });

    test('同 seed 的 light/dark 表品牌族不同（成对切换）', () {
      for (final seed in AppSeedColor.values) {
        final light = AppColors.of(seed, Brightness.light);
        final dark = AppColors.of(seed, Brightness.dark);
        expect(light.primary, isNot(dark.primary), reason: '${seed.name} primary');
        expect(light.secondary, isNot(dark.secondary),
            reason: '${seed.name} secondary');
      }
    });

    test('中性色全 seed 共用（琥珀系中性梯度，不随 seed 变）', () {
      for (final brightness in Brightness.values) {
        final amber = AppColors.of(AppSeedColor.amber, brightness);
        for (final seed in AppSeedColor.values) {
          final c = AppColors.of(seed, brightness);
          expect(c.bg, amber.bg, reason: '${seed.name} bg 应共用');
          expect(c.surfaceContainerLow, amber.surfaceContainerLow,
              reason: '${seed.name} surfaceContainerLow 应共用');
          expect(c.surfaceContainer, amber.surfaceContainer,
              reason: '${seed.name} surfaceContainer 应共用');
          expect(c.outlineVariant, amber.outlineVariant,
              reason: '${seed.name} outlineVariant 应共用');
          expect(c.outline, amber.outline, reason: '${seed.name} outline 应共用');
          expect(c.onSurface, amber.onSurface,
              reason: '${seed.name} onSurface 应共用');
          expect(c.onSurfaceVariant, amber.onSurfaceVariant,
              reason: '${seed.name} onSurfaceVariant 应共用');
          expect(c.favorite, amber.favorite,
              reason: '${seed.name} favorite 应共用');
          expect(c.error, amber.error, reason: '${seed.name} error 应共用');
        }
      }
    });
  });
}
