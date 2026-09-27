import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';

/// 品牌种子色守门测试（DESIGN.md §1.1）：
///
/// 1. 完备性：6 seed × 2 brightness 的表全部取到、不透明、同族字段互异、
///    12 张表两两互异。
/// 2. 对比度：WCAG 门槛（onPrimary/primary ≥ 4.5 等 5 项）。例外：amber
///    light primary 白字 4.37 品牌锁定特批 ≥4.3；rose light primary/bg
///    2.64 为 B 站品牌粉特批 ≥2.6（粉色仅用于指示器/选中描边等非正文
///    文本场景，其上文字已用深字 #4A0E24 达标 ≥4.5）。
/// 3. 回归保护：amber 的 light/dark 表与现状逐字相等（写死期望值）。
/// 4. `AppColors.of`：每个枚举值 light/dark 两个方向取表与 DESIGN.md
///    §1.1 落地表逐字一致。
/// 5. 中性梯度随 seed 派生（OKLCH L/C 沿用琥珀系、hue=primary 的
///    OKLCH hue）；favorite/error 全 seed 固定，不参与 hue 旋转。
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

  /// primary/bg 的对比度下限。
  ///
  /// rose light 特批 ≥2.6：B 站品牌粉 #FB7299 对白底实测 2.64:1，低于
  /// 3.0 大文本档。品牌粉仅用于指示器、选中描边、FilledButton 底色等
  /// 非正文文本场景（UI 组件对其文字均用深字 onPrimary #4A0E24，
  /// 5.8:1 ≥4.5 达标），见 DESIGN.md §1.1 例外注记。
  double primaryBgFloor(AppSeedColor seed, Brightness brightness) =>
      seed == AppSeedColor.rose && brightness == Brightness.light ? 2.6 : 3.0;

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
        test('primary/bg ≥ ${primaryBgFloor(seed, brightness)}', () {
          expect(contrastRatio(c.primary, c.bg),
              greaterThanOrEqualTo(primaryBgFloor(seed, brightness)));
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
        // rose：B 站品牌粉 #FB7299 深浅同值（B 站深色模式同用此粉）。
        AppSeedColor.rose: Color(0xFFFB7299),
        AppSeedColor.forest: Color(0xFF2E6B4F),
        AppSeedColor.blue: Color(0xFF3B64C4),
        AppSeedColor.teal: Color(0xFF007B84),
        AppSeedColor.violet: Color(0xFF6F42C1),
      };
      const expectedDarkPrimary = {
        AppSeedColor.amber: Color(0xFFE5B64A),
        AppSeedColor.rose: Color(0xFFFB7299),
        AppSeedColor.forest: Color(0xFF8FD6B0),
        AppSeedColor.blue: Color(0xFFA8C8FF),
        AppSeedColor.teal: Color(0xFF4FD8C6),
        AppSeedColor.violet: Color(0xFFCFBCFF),
      };
      const expectedOnPrimary = {
        AppSeedColor.rose: Color(0xFF4A0E24),
      };
      const expectedDarkOnPrimary = {
        AppSeedColor.rose: Color(0xFF4A0E24),
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
        // rose 的 onPrimary 为深字 #4A0E24（对比度优先，非默认白/黑规则）。
        if (expectedOnPrimary.containsKey(seed)) {
          expect(light.onPrimary, expectedOnPrimary[seed],
              reason: '${seed.name} light onPrimary');
          expect(dark.onPrimary, expectedDarkOnPrimary[seed],
              reason: '${seed.name} dark onPrimary');
        }
        expect(light.secondary, expectedSecondary[seed],
            reason: '${seed.name} light secondary');
        expect(dark.secondary, expectedDarkSecondary[seed],
            reason: '${seed.name} dark secondary');
      }
    });

    test('同 seed 的 light/dark 表品牌族成对切换（rose primary 品牌粉深浅同值例外）',
        () {
      for (final seed in AppSeedColor.values) {
        final light = AppColors.of(seed, Brightness.light);
        final dark = AppColors.of(seed, Brightness.dark);
        // rose 为 B 站品牌粉锁定：#FB7299 深浅同值（DESIGN.md §1.1），
        // 其余 seed primary 须随亮度切换。
        if (seed != AppSeedColor.rose) {
          expect(
              light.primary, isNot(dark.primary), reason: '${seed.name} primary');
        }
        expect(light.secondary, isNot(dark.secondary),
            reason: '${seed.name} secondary');
        // 整表仍须不同（中性梯度随亮度/hue 派生，必然互异）。
        expect(
          snapshot(light).map((e) => e.$2),
          isNot(snapshot(dark).map((e) => e.$2)),
          reason: '${seed.name} light/dark 整表不得相同',
        );
      }
    });

    test('中性 7 token 每 seed × brightness 完备非空', () {
      List<Color> neutrals(AppColors c) => [
            c.bg,
            c.surfaceContainerLow,
            c.surfaceContainer,
            c.outlineVariant,
            c.outline,
            c.onSurface,
            c.onSurfaceVariant,
          ];
      for (final (seed, brightness, c) in allTables()) {
        final ns = neutrals(c);
        expect(ns, hasLength(7), reason: '$seed/$brightness 须有 7 个中性 token');
        for (final n in ns) {
          expect(n.a, 1.0, reason: '$seed/$brightness 中性 token 须非空不透明');
        }
      }
    });

    test('同亮度下各 seed surfaceContainer 互不相同（hue 旋转生效）', () {
      for (final brightness in Brightness.values) {
        final values = <Color>{
          for (final seed in AppSeedColor.values)
            AppColors.of(seed, brightness).surfaceContainer,
        };
        expect(values, hasLength(6),
            reason: '${brightness.name} 下 6 seed surfaceContainer 须互不相同');
      }
    });

    test('surfaceContainer 派生值逐字锁定（12 张，DESIGN.md §1.1 代表值）', () {
      const expected = {
        (AppSeedColor.amber, Brightness.light): Color(0xFFF3F0EA),
        (AppSeedColor.amber, Brightness.dark): Color(0xFF1A1814),
        (AppSeedColor.rose, Brightness.light): Color(0xFFF6EEF0),
        (AppSeedColor.rose, Brightness.dark): Color(0xFF1C1718),
        (AppSeedColor.forest, Brightness.light): Color(0xFFECF2EE),
        (AppSeedColor.forest, Brightness.dark): Color(0xFF151917),
        (AppSeedColor.blue, Brightness.light): Color(0xFFEDF0F6),
        (AppSeedColor.blue, Brightness.dark): Color(0xFF16181C),
        (AppSeedColor.teal, Brightness.light): Color(0xFFEAF2F3),
        (AppSeedColor.teal, Brightness.dark): Color(0xFF141A19),
        (AppSeedColor.violet, Brightness.light): Color(0xFFF1EFF6),
        (AppSeedColor.violet, Brightness.dark): Color(0xFF19171C),
      };
      for (final (seed, brightness, c) in allTables()) {
        expect(c.surfaceContainer, expected[(seed, brightness)],
            reason: '${seed.name}/${brightness.name} surfaceContainer');
      }
    });

    test('bg 两档为纯灰（C=0）派生不变形，全 seed 同值', () {
      for (final brightness in Brightness.values) {
        final amber = AppColors.of(AppSeedColor.amber, brightness);
        for (final seed in AppSeedColor.values) {
          expect(AppColors.of(seed, brightness).bg, amber.bg,
              reason: '${seed.name} ${brightness.name} bg 应与 amber 同值');
        }
      }
    });

    test('favorite/error 全 seed 固定（不参与 hue 旋转，DESIGN.md 设计分工）', () {
      for (final brightness in Brightness.values) {
        final amber = AppColors.of(AppSeedColor.amber, brightness);
        for (final seed in AppSeedColor.values) {
          expect(AppColors.of(seed, brightness).favorite, amber.favorite,
              reason: '${seed.name} ${brightness.name} favorite 应固定');
          expect(AppColors.of(seed, brightness).error, amber.error,
              reason: '${seed.name} ${brightness.name} error 应固定');
        }
      }
    });
  });
}
