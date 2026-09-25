import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import 'fake_repositories.dart';

void main() {
  late FakePokedexRepository repo;
  late FakeFavoritesRepository favorites;

  setUp(() {
    repo = FakePokedexRepository();
    favorites = FakeFavoritesRepository();
  });

  tearDown(() {
    favorites.dispose();
  });

  Widget buildApp(Brightness brightness, {int speciesId = 1}) {
    return ProviderScope(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(repo),
        favoritesRepositoryProvider.overrideWithValue(favorites),
      ],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? buildLightTheme()
            : buildDarkTheme(),
        home: PokemonDetailPage(speciesId: speciesId),
      ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    Brightness brightness = Brightness.light,
    Set<int> initialFavorites = const {},
    int speciesId = 1,
  }) async {
    favorites.seed(initialFavorites);
    await tester.pumpWidget(
      buildApp(brightness, speciesId: speciesId),
    );
    await tester.pumpAndSettle();
  }

  group('详情页头部', () {
    testWidgets('渲染编号 / 中文名 / 英日文名 / 属性徽章', (tester) async {
      await pumpPage(tester);

      expect(find.text('#001'), findsOneWidget);
      // 中文名（头部）+ 默认形态 chip 同名，共 2 处。
      expect(find.text('妙蛙种子'), findsNWidgets(2));
      expect(find.text('Bulbasaur · フシギダネ'), findsOneWidget);
      expect(find.text('草'), findsOneWidget);
      expect(find.text('毒'), findsOneWidget);
    });

    testWidgets('light / dark 主题均正确渲染关键内容', (tester) async {
      for (final brightness in Brightness.values) {
        await pumpPage(tester, brightness: brightness);
        expect(find.text('#001'), findsOneWidget);
        expect(find.text('妙蛙种子'), findsNWidgets(2));
        expect(find.text('Bulbasaur · フシギダネ'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('dark 主题下已收藏心形使用收藏色', (tester) async {
      await pumpPage(
        tester,
        brightness: Brightness.dark,
        initialFavorites: {1},
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, const Color(0xFFF87584)); // AppColors.dark.favorite
    });

    testWidgets('打开页面记入最近浏览（addRecent）', (tester) async {
      await pumpPage(tester);

      expect(favorites.recentsAdded, [1]);
    });
  });

  group('收藏', () {
    testWidgets('点击心形调用仓储 toggleFavorite 并更新状态', (tester) async {
      await pumpPage(tester);

      expect(favorites.toggled, isEmpty);
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      expect(favorites.toggled, [1]);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('形态切换', () {
    testWidgets('切换到超级形态后种族值随之变化', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('超级妙蛙花'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('种族值'));
      await tester.pumpAndSettle();

      expect(find.text('总和 525'), findsOneWidget);
      expect(find.text('总和 318'), findsNothing);
    });
  });

  group('种族值', () {
    testWidgets('默认形态显示 45/49/49/65/65/45 与总和 318', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('种族值'));
      await tester.pumpAndSettle();

      expect(find.text('总和 318'), findsOneWidget);
      expect(find.text('45'), findsNWidgets(2)); // HP + 速度
      expect(find.text('49'), findsNWidgets(2)); // 攻击 + 防御
      expect(find.text('65'), findsNWidgets(2)); // 特攻 + 特防
    });
  });

  group('图鉴说明', () {
    testWidgets('默认选中最新含简体中文的版本', (tester) async {
      await pumpPage(tester);

      // fixture：gen9 朱仅英文，gen1 红含简中 → 默认选「红」。
      expect(find.text('第九世代'), findsOneWidget);
      expect(find.text('第一世代'), findsOneWidget);
      expect(find.text('种子在出生时埋在土里。'), findsOneWidget);
      expect(find.textContaining('暂无简体中文'), findsNothing);
    });

    testWidgets('选中仅英文版本时出现语言回退提示', (tester) async {
      await pumpPage(tester);

      await tester.ensureVisible(find.text('朱'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('朱'));
      await tester.pumpAndSettle();

      expect(find.text('It can go for days without eating.'), findsOneWidget);
      expect(find.text('该版本暂无简体中文资料 · 显示 English'), findsOneWidget);
    });
  });

  group('Tab 导航', () {
    testWidgets('五个 Tab 标题齐备', (tester) async {
      await pumpPage(tester);

      for (final title in ['图鉴说明', '种族值', '进化', '招式', '资料']) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('进化 / 招式为建设占位，资料 tab 展示特性', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.text('进化'));
      await tester.pumpAndSettle();
      expect(find.text('进化图 · 建设中'), findsOneWidget);

      await tester.tap(find.text('招式'));
      await tester.pumpAndSettle();
      expect(find.text('招式表 · 建设中'), findsOneWidget);

      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      expect(find.text('身高'), findsOneWidget);
      expect(find.text('体重'), findsOneWidget);
      expect(find.text('茂盛'), findsOneWidget);
      expect(find.text('叶绿素'), findsOneWidget);
      expect(find.text('隐藏'), findsOneWidget);
    });
  });

  group('宽屏（expanded）单页布局', () {
    testWidgets('无 TabBar、分区标题渲染并排雷达图', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpPage(tester);

      expect(find.byType(TabBar), findsNothing);
      expect(find.text('图鉴说明'), findsOneWidget); // SectionTitle（无 Tab）
      expect(find.text('资料'), findsOneWidget);
      expect(find.byType(StatRadar), findsOneWidget); // 宽 ≥840 并排雷达
    });
  });

  group('异常态', () {
    testWidgets('不存在的 speciesId 显示「未找到」', (tester) async {
      await pumpPage(tester, speciesId: 9999);

      expect(find.text('未找到'), findsOneWidget);
    });

    testWidgets('notFound 构造渲染未找到空态', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: PokemonDetailPage.notFound()),
      );
      await tester.pumpAndSettle();

      expect(find.text('未找到'), findsOneWidget);
      expect(find.text('返回图鉴'), findsOneWidget);
    });

    testWidgets('仓储异常显示「加载失败」与重试', (tester) async {
      repo.queryError = StateError('boom');
      await pumpPage(tester);

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });
  });
}
