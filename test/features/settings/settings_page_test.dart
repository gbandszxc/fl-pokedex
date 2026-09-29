import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/features/settings/providers.dart';
import 'package:fl_pokedex/features/settings/settings_page.dart';

import '../favorites/fakes.dart';

typedef _Harness = (
  ProviderContainer container,
  FakeSummariesPokedexRepository pokedex,
);

/// 泵入设置页（覆盖仓储、SP 与包信息），等待 manifest 解析完成。
///
/// [size] 为逻辑 surface 尺寸（默认 400×1600）。
/// [appVersion] 为 mock 的平台版本号（刻意取与 pubspec 不同的合成值，
/// 以证明页面读的是平台报告值而非写死的字面量）。
/// [opener] 覆盖外链打开器，避免测试触碰真实平台通道。
Future<_Harness> _pumpSettings(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  Size size = const Size(400, 1600),
  String appVersion = '9.9.9',
  ExternalUrlOpener? opener,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  PackageInfo.setMockInitialValues(
    appName: 'Fl-PokeDex',
    packageName: 'com.github.gbandszxc.fl_pokedex',
    version: appVersion,
    buildNumber: '1',
    buildSignature: '',
  );
  final pokedex = FakeSummariesPokedexRepository(const {});
  final container = ProviderContainer(
    overrides: [
      pokedexRepositoryOverride(pokedex),
      if (opener != null) externalUrlOpenerProvider.overrideWithValue(opener),
    ],
  );
  addTearDown(container.dispose);

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return (container, pokedex);
}

void main() {
  testWidgets('三组 SegmentedButton 与关于区块渲染', (tester) async {
    await _pumpSettings(tester);

    // 外观 / 首页布局 / 桌面卡片密度。
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('跟随系统'), findsOneWidget);
    expect(find.text('浅色'), findsOneWidget);
    expect(find.text('深色'), findsOneWidget);
    expect(find.text('首页布局'), findsOneWidget);
    expect(find.text('网格'), findsOneWidget);
    expect(find.text('列表'), findsOneWidget);
    expect(find.text('桌面卡片密度'), findsOneWidget);
    expect(find.text('舒适'), findsOneWidget);
    expect(find.text('紧凑'), findsOneWidget);
    expect(find.text('仅桌面宽屏生效'), findsOneWidget);

    // 关于区块。
    expect(find.text('关于'), findsOneWidget);
    expect(find.text('版本'), findsOneWidget);
    expect(find.text('9.9.9'), findsOneWidget);
    expect(find.text('pokeapi@test'), findsOneWidget);
    expect(find.text('2026-09-25'), findsOneWidget);
    expect(find.text('宝可梦 1025 只 · 招式 937 个'), findsOneWidget);
    expect(find.text('数据来源'), findsOneWidget);
    expect(find.text('PokéAPI'), findsOneWidget);
    expect(find.text('项目地址'), findsOneWidget);
    expect(find.text('开源许可'), findsOneWidget);
    // 无账号 / 网络相关项。
    expect(find.textContaining('账号'), findsNothing);
    expect(find.textContaining('登录'), findsNothing);
  });

  testWidgets('外观三选：点「深色」切换 themeModeProvider 并更新选中态',
      (tester) async {
    final (container, _) = await _pumpSettings(tester);

    await tester.tap(find.text('深色'));
    await tester.pump();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');

    // 段选中态联动：深色为选中段（SegmentedButton 内 checked 态）。
    final button = tester.widget<SegmentedButton<ThemeMode>>(
      find.byType(SegmentedButton<ThemeMode>),
    );
    expect(button.selected, {ThemeMode.dark});
  });

  testWidgets('主题色：6 个色块渲染，点「粉」切 seedColorProvider 并写 SP',
      (tester) async {
    final semantics = tester.ensureSemantics();
    final (container, _) = await _pumpSettings(tester);

    // 六个 swatch（琥珀/粉/墨绿/蓝/青/紫）与行标签。
    expect(find.text('主题色'), findsOneWidget);
    expect(find.bySemanticsLabel('琥珀'), findsOneWidget);
    expect(find.bySemanticsLabel('粉'), findsOneWidget);
    expect(find.bySemanticsLabel('墨绿'), findsOneWidget);
    expect(find.bySemanticsLabel('蓝'), findsOneWidget);
    expect(find.bySemanticsLabel('青'), findsOneWidget);
    expect(find.bySemanticsLabel('紫'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('粉'));
    await tester.pump();

    expect(container.read(seedColorProvider), AppSeedColor.rose);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('seed_color'), 'rose');
    // 语义句柄须在测试体末尾释放（校验先于 tearDown 执行）。
    semantics.dispose();
  });

  testWidgets('360dp 逻辑宽度下 6 个主题色 swatch 同一行（不换行）',
      (tester) async {
    final semantics = tester.ensureSemantics();
    // NW 屏（约 360dp 逻辑宽）：6 个 swatch 必须单行排列。
    await _pumpSettings(tester, size: const Size(360, 720));

    const labels = ['琥珀', '粉', '墨绿', '蓝', '青', '紫'];
    final rects = [
      for (final label in labels) tester.getRect(find.bySemanticsLabel(label)),
    ];

    // 同一行：全部 swatch 顶部 y 一致（换行则第二行 y 明显更大）。
    for (final rect in rects) {
      expect(rect.top, rects.first.top,
          reason: '6 个 swatch 必须同一行（360dp 宽约束）');
    }
    // 从左到右 x 递增（排列顺序 = seed 枚举顺序）。
    for (var i = 1; i < rects.length; i++) {
      expect(rects[i].left, greaterThan(rects[i - 1].left),
          reason: '${labels[i]} 应在 ${labels[i - 1]} 右侧');
    }
    // 整行不越出屏幕右缘（留 16dp compact 页边）。
    expect(rects.last.right, lessThanOrEqualTo(360 - 16));
    semantics.dispose();
  });

  testWidgets('首页布局：点「列表」写 SP view_mode', (tester) async {
    final (container, _) = await _pumpSettings(tester);

    await tester.tap(find.text('列表'));
    await tester.pump();

    expect(container.read(homeViewLayoutProvider), HomeViewLayout.list);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('view_mode'), 'list');
  });

  testWidgets('卡片密度：点「紧凑」切换 cardDensityProvider 并写 SP',
      (tester) async {
    final (container, _) = await _pumpSettings(tester);

    await tester.tap(find.text('紧凑'));
    await tester.pump();

    expect(container.read(cardDensityProvider), CardDensity.compact);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('card_density'), 'compact');
  });

  testWidgets('manifest 加载失败时数据行显示降级文案', (tester) async {
    SharedPreferences.setMockInitialValues(const {});
    PackageInfo.setMockInitialValues(
      appName: 'Fl-PokeDex',
      packageName: 'com.github.gbandszxc.fl_pokedex',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
    final pokedex = FakeSummariesPokedexRepository(
      const {},
      manifestError: StateError('manifest 不可用'),
    );
    final container = ProviderContainer(
      overrides: [
        pokedexRepositoryOverride(pokedex),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('信息不可用'), findsOneWidget);
    // 其余关于项不受影响。
    expect(find.text('9.9.9'), findsOneWidget);
  });

  testWidgets('版本行取平台报告的安装包版本（非硬编码常量）', (tester) async {
    final (container, _) = await _pumpSettings(tester, appVersion: '7.7.7');

    expect(container.read(appVersionProvider).valueOrNull, '7.7.7');
    expect(find.text('7.7.7'), findsOneWidget);
    // 与 pubspec 同步无关：换成别的值也照显，说明读的是运行时真值。
    expect(find.text('1.1.0'), findsNothing);
  });

  testWidgets('开源许可页带安装包版本号', (tester) async {
    await _pumpSettings(tester, appVersion: '7.7.7');

    await tester.tap(find.text('开源许可'));
    // 不用 pumpAndSettle：许可页加载态为循环动画，会一直不 settle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final page = tester.widget<LicensePage>(find.byType(LicensePage));
    expect(page.applicationName, 'Fl-PokeDex');
    expect(page.applicationVersion, '7.7.7');
  });

  testWidgets('项目地址行：GitHub 标志渲染，点按交给外链打开器', (tester) async {
    Uri? target;
    await _pumpSettings(
      tester,
      opener: (url) async {
        target = url;
        return true;
      },
    );

    expect(find.text('项目地址'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);

    // 布局锁：文案居左（与「开源许可」行同起点），GitHub 标志在右侧。
    final textRect = tester.getRect(find.text('项目地址'));
    final iconRect = tester.getRect(find.byType(SvgPicture));
    expect(iconRect.left, greaterThan(textRect.right),
        reason: 'GitHub 标志应在文案右侧');

    await tester.tap(find.text('项目地址'));
    // fake opener 走 Future，泵一帧 flush microtask 让其落地。
    await tester.pump();

    expect(target, isNotNull);
    // 字面量而非 kProjectRepoUrl：防止「常量写错、断言跟着错」的自证循环。
    expect(target.toString(), 'https://github.com/gbandszxc/fl-pokedex');
  });

  testWidgets('外链打开失败时提示无法打开', (tester) async {
    await _pumpSettings(tester, opener: (url) async => false);

    await tester.tap(find.text('项目地址'));
    await tester.pump();
    // SnackBar 入场动画。
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('无法打开'), findsOneWidget);

    // 推进 SnackBar 默认 4s 计时器与退场动画，避免测试遗留 pending timer。
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}
