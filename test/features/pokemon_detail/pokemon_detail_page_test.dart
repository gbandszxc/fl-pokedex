import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/features/pokemon_detail/detail_section_rail.dart';
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
    // 走 /pokemon/:speciesId 路由挂载：招式 / 进化分区从 GoRouterState
    // 解析 speciesId，纯 home: 挂载会落入其「无法识别」空态。
    return ProviderScope(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(repo),
        favoritesRepositoryProvider.overrideWithValue(favorites),
      ],
      child: MaterialApp.router(
        theme: brightness == Brightness.light
            ? buildLightTheme()
            : buildDarkTheme(),
        routerConfig: GoRouter(
          initialLocation: '/pokemon/$speciesId',
          routes: [
            GoRoute(
              path: '/pokemon/:speciesId',
              builder: (context, state) => PokemonDetailPage(
                speciesId:
                    int.tryParse(state.pathParameters['speciesId'] ?? '') ?? 0,
              ),
            ),
          ],
        ),
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

  /// 向上拖动收起折叠头部，让 TabBarView 内容区完整露出。
  Future<void> collapseHeader(
    WidgetTester tester, {
    int speciesId = 1,
  }) async {
    final dexLabel = '#${speciesId.toString().padLeft(3, '0')}';
    await tester.drag(find.text(dexLabel), const Offset(0, -600));
    await tester.pumpAndSettle();
  }

  group('详情页头部', () {
    testWidgets('渲染编号 / 中文名 / 英日文名 / 属性徽章 / 分类', (tester) async {
      await pumpPage(tester);

      expect(find.text('#001'), findsOneWidget);
      // 中文名（头部）+ 默认形态 chip 同名，共 2 处。
      expect(find.text('妙蛙种子'), findsNWidgets(2));
      expect(find.text('Bulbasaur · フシギダネ'), findsOneWidget);
      expect(find.text('草'), findsOneWidget);
      expect(find.text('毒'), findsOneWidget);
      // 头部分类 caption（SpeciesInfo.genusZh）。
      expect(find.text('种子宝可梦'), findsOneWidget);
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

      // 形态 chips 位于展开头部内：先点选，再收起头部切到种族值。
      await tester.tap(find.text('超级妙蛙花'));
      await tester.pumpAndSettle();
      await collapseHeader(tester);
      await tester.tap(find.text('种族值'));
      await tester.pumpAndSettle();

      expect(find.text('总和 525'), findsOneWidget);
      expect(find.text('总和 318'), findsNothing);
    });
  });

  group('种族值', () {
    testWidgets('默认形态显示 45/49/49/65/65/45 与总和 318', (tester) async {
      await pumpPage(tester);

      await collapseHeader(tester);
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

      await collapseHeader(tester);
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

    testWidgets('进化 / 招式为空态占位，资料 tab 展示身高体重与特性', (tester) async {
      await pumpPage(tester);
      await collapseHeader(tester);

      await tester.tap(find.text('进化'));
      await tester.pumpAndSettle();
      expect(find.text('该宝可梦没有进化关系'), findsOneWidget);

      await tester.tap(find.text('招式'));
      await tester.pumpAndSettle();
      // 招式分区有数据：版本组 chips（fake：朱/紫）与学习集条目。
      expect(find.widgetWithText(VersionChip, '朱/紫'), findsOneWidget);
      expect(find.text('撞击'), findsOneWidget);

      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      expect(find.text('身高'), findsOneWidget);
      expect(find.text('体重'), findsOneWidget);
      // 妙蛙种子默认形态：0.7m / 6.9kg（保留 1 位小数）。
      expect(find.text('0.7 m'), findsOneWidget);
      expect(find.text('6.9 kg'), findsOneWidget);
      expect(find.text('茂盛'), findsOneWidget);
      expect(find.text('叶绿素'), findsOneWidget);
      expect(find.text('隐藏'), findsOneWidget);
      // 未展开时不显示说明。
      expect(find.textContaining('草属性招式'), findsNothing);
    });

    testWidgets('特性行展开显示简中说明', (tester) async {
      await pumpPage(tester);
      await collapseHeader(tester);

      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('茂盛'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('茂盛'));
      await tester.pumpAndSettle();

      expect(find.text('HP 较低时，草属性招式威力提高。'), findsOneWidget);
      expect(find.text('暂无简体中文说明'), findsNothing);
    });

    testWidgets('仅英文说明的特性展开时出现语言提示', (tester) async {
      await pumpPage(tester);
      await collapseHeader(tester);

      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('叶绿素'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('叶绿素'));
      await tester.pumpAndSettle();

      expect(find.text('暂无简体中文说明'), findsOneWidget);
      expect(find.text('Boosts Speed in harsh sunlight.'), findsOneWidget);
    });

    testWidgets('身高为 0 / 体重缺失的形态显示 —', (tester) async {
      await pumpPage(tester);

      // 形态 chips 位于展开头部内：先点选，再收起头部。
      await tester.tap(find.text('帕底亚的妙蛙种子'));
      await tester.pumpAndSettle();
      await collapseHeader(tester);
      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();

      // 身高（0）与体重（缺失）均回退为 —。
      expect(find.text('—'), findsNWidgets(2));
      expect(find.text('0.7 m'), findsNothing);
    });
  });

  group('compact 折叠头占比', () {
    testWidgets('360×640：不滚动头部即可见招式版本组 chips 行', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpPage(tester);

      // 不做任何滚动，直接切到招式 tab。
      await tester.tap(find.text('招式'));
      await tester.pumpAndSettle();

      // 版本组 chips 行在首屏视口内（可发现性：无需先收起头部）。
      final groupChip = find.widgetWithText(VersionChip, '朱/紫');
      expect(groupChip, findsOneWidget);
      final rect = tester.getRect(groupChip);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(640));
    });
  });

  group('P1-b 头部徽章尺寸', () {
    // 徽章应为紧凑 pill（宽 < 屏宽 60%），不得被拉伸为全宽色带。
    for (final entry in {
      'iPhoneSE(360)': const Size(360, 640),
      'tablet(720)': const Size(720, 900),
    }.entries) {
      testWidgets('${entry.key}：徽章宽 < 屏宽 60% 且双徽章并排', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpPage(tester); // 妙蛙种子：草 / 毒双徽章

        final badges = find.byType(TypeBadge);
        expect(badges, findsNWidgets(2));
        final maxWidth = entry.value.width * 0.6;
        for (final element in badges.evaluate()) {
          final rect = tester.getRect(find.byWidget(element.widget));
          expect(rect.width, lessThan(maxWidth),
              reason: '属性徽章被拉伸为全宽（P1-b 回归）');
        }
        // 双徽章并排（同一水平线）。
        final first = tester.getRect(find.byType(TypeBadge).first);
        final last = tester.getRect(find.byType(TypeBadge).last);
        expect(first.top, last.top);
      });
    }
  });

  group('P1-c 形态切换（皮卡丘 fixture）', () {
    testWidgets('渲染超极巨化 / cosplay 形态 chips', (tester) async {
      await pumpPage(tester, speciesId: 25);

      expect(find.widgetWithText(VersionChip, '超极巨化'), findsOneWidget);
      expect(find.widgetWithText(VersionChip, 'Cosplay Pikachu'),
          findsOneWidget);
      // 默认形态 chip 选中。
      expect(
        tester
            .widget<VersionChip>(
              find.widgetWithText(VersionChip, '皮卡丘'),
            )
            .selected,
        isTrue,
      );
    });

    testWidgets('点击超极巨化后 formDetail 更新（身高/体重随形态变化）', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpPage(tester, speciesId: 25);

      await tester.tap(find.widgetWithText(VersionChip, '超极巨化'));
      await tester.pumpAndSettle();
      await collapseHeader(tester, speciesId: 25);
      // 360 宽下 5 个 tab 横向溢出：先把「资料」滚入 TabBar 视口。
      await tester.ensureVisible(find.text('资料'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('资料'));
      await tester.pumpAndSettle();

      // 超极巨化：21.0m / 1000.0kg（默认形态 0.4m / 6.0kg）。
      expect(find.text('21.0 m'), findsOneWidget);
      expect(find.text('1000.0 kg'), findsOneWidget);
      expect(find.text('0.4 m'), findsNothing);
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
      // 按组件定位：「资料」同时是锚点轨短名（find.text 会命中 2 处）。
      expect(find.widgetWithText(SectionTitle, '资料'), findsOneWidget);
      expect(find.byType(StatRadar), findsOneWidget); // 宽 ≥840 并排雷达
    });

    testWidgets('右侧锚点轨常驻：点击锚点把分区带到 pinned AppBar 之下', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpPage(tester);

      // 五段短名齐备（完整名在 Tooltip 里，见 detail_section_rail_test）。
      expect(find.byType(DetailSectionRail), findsOneWidget);
      for (final anchor in kDetailSectionAnchors) {
        expect(
          find.descendant(
            of: find.byType(DetailSectionRail),
            matching: find.text(anchor.shortLabel),
          ),
          findsOneWidget,
        );
      }

      Finder anchorItem(String shortLabel) => find.descendant(
            of: find.byType(DetailSectionRail),
            matching: find.text(shortLabel),
          );

      // 末段「资料」：内容在它之后不足一屏，跳转被 maxScrollExtent 截断
      // （无法顶到 AppBar 之下），此时仍须滚入视口 + 高亮末段。
      final infoTitle = find.widgetWithText(SectionTitle, '资料');
      expect(tester.getRect(infoTitle).top, greaterThan(900)); // 初始在视口外

      await tester.tap(anchorItem('资料'));
      await tester.pumpAndSettle();

      final infoTop = tester.getRect(infoTitle).top;
      expect(infoTop, greaterThanOrEqualTo(kToolbarHeight)); // 不被 AppBar 遮挡
      expect(infoTop, lessThan(900)); // 已进入视口
      expect(
        tester
            .widget<DetailSectionRail>(find.byType(DetailSectionRail))
            .activeIndex,
        kDetailSectionAnchors.length - 1,
      );

      // 反向上滚回首段：标题精确落在 AppBar 之下 8px（不是被顶到视口顶端）。
      final flavorTitle = find.widgetWithText(SectionTitle, '图鉴说明');
      await tester.tap(anchorItem('说明'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(flavorTitle).top,
        moreOrLessEquals(kToolbarHeight + AppSpacing.s, epsilon: 1),
      );
      expect(
        tester
            .widget<DetailSectionRail>(find.byType(DetailSectionRail))
            .activeIndex,
        0,
      );
      expect(tester.takeException(), isNull);
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
