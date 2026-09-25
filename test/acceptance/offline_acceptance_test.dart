import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/app/app.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/core/offline/blocking_http_overrides.dart';
import 'package:fl_pokedex/data/database/pokedex_database.dart';
import 'package:fl_pokedex/data/database/user_database.dart';
import 'package:fl_pokedex/features/settings/providers.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import '../helpers/sqlite_loader.dart';

/// 「运行时 0 网络请求」验收（PRODUCT.md 硬性契约 / architecture.md §8）：
///
/// 在 [BlockingHttpOverrides] 生效的前提下，用真实
/// `assets/database/pokedex.db`（只读）驱动完整核心链路——冷启动、搜索、
/// 详情三 tab、设置切主题。任何一步产生 HTTP 请求都会抛
/// [OfflineRequestBlocked] 并使测试失败；全程额外断言
/// `tester.takeException()` 为 null。
///
/// path_provider 在测试环境不可用：数据库 provider 全部 override
/// （图鉴库直连资产库文件、用户库用内存），不触碰 di.dart 的 open 工厂。
void main() {
  loadSqliteForHostTests();

  tearDown(() {
    HttpOverrides.global = null;
  });

  group('拦截器在线验证（反向证明）', () {
    test('overrides 生效下 HttpClient.openUrl 直接抛 OfflineRequestBlocked',
        () async {
      HttpOverrides.global = BlockingHttpOverrides();

      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      try {
        await client.openUrl(
          'GET',
          Uri.parse('https://pokeapi.co/api/v2/pokemon/25'),
        );
        fail('产生网络请求：离线守卫未拦截 pokeapi.co 的 HTTP 调用');
      } on OfflineRequestBlocked catch (error) {
        expect(error.url, contains('https://pokeapi.co'));
      }
    });
  });

  group('真实离线库全链路验收', () {
    late PokedexDatabase pokedexDb;
    late UserDatabase userDb;

    setUp(() {
      HttpOverrides.global = BlockingHttpOverrides();
      SharedPreferences.setMockInitialValues(const {});
      pokedexDb = PokedexDatabase(
        PokedexDatabase.readOnlyExecutor(File('assets/database/pokedex.db')),
      );
      userDb = UserDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      HttpOverrides.global = null;
      await pokedexDb.close();
      await userDb.close();
    });

    /// 冷启动真实 app（覆盖数据库 provider 为真实库 / 内存库，
    /// 仓储沿用 di.dart 默认工厂），视口 800×600（medium 单栏路径）。
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexDatabaseProvider.overrideWithValue(pokedexDb),
          userDatabaseProvider.overrideWithValue(userDb),
        ],
      );
      addTearDown(container.dispose);

      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const AmberDexApp(),
        ),
      );
      return container;
    }

    /// 有界轮询泵帧：等 [finder] 出现或超时报错。
    ///
    /// 首载骨架与 tab 切换都有循环动画，pumpAndSettle 永不结束，故用
    /// 固定步长推进 FakeAsync 时钟；真实库查询完成经真实事件循环，
    /// pump 之间的 await 足以让其落地。
    Future<void> pumpUntilFound(
      WidgetTester tester,
      Finder finder, {
      int maxMs = 5000,
    }) async {
      var waited = 0;
      while (finder.evaluate().isEmpty && waited < maxMs) {
        await tester.pump(const Duration(milliseconds: 50));
        waited += 50;
      }
      expect(finder, findsWidgets, reason: '等待 $maxMs 后仍未出现：$finder');
    }

    /// 常规推进：防抖（200ms）/ 路由与 tab 动画的一拍等待。
    Future<void> pumpFor(WidgetTester tester, [int ms = 320]) async {
      await tester.pump(Duration(milliseconds: ms));
    }

    /// 每个验收步骤的收尾：任何被拦截请求 / 运行时异常在此显现。
    void assertNoException(WidgetTester tester, String step) {
      final exception = tester.takeException();
      expect(
        exception,
        isNull,
        reason: '验收步骤「$step」产生异常（若为 '
            'OfflineRequestBlocked 即意味着产生了网络请求）：$exception',
      );
    }

    /// 切到详情页第 [label] 个 tab：tap 后分多帧泵足切换动画。
    ///
    /// TabController 动画约 300ms，且 TabBarView 在动画完成
    /// （indexIsChanging=false）后才真正挂载目标页；单帧 pump(320)
    /// 只推进一帧（约 60% 进度），动画会遗留挂起导致目标页永不出现。
    Future<void> openTab(WidgetTester tester, String label) async {
      await tester.tap(find.text(label).first);
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// 收起详情页折叠式 SliverAppBar。
    ///
    /// medium 视口（600 高）下头部初始完全展开（约 512px），tab 内容区
    /// 仅剩约 40px：chips 在视口内不可命中。注意拖动起点必须在**头部
    /// 区域**（y ≈ 250）——从 TabBarView 区域上拖会被内层滚动消费，
    /// 头部纹丝不动；从头部上拖才走外层滚动把 header 收起。
    Future<void> collapseHeader(WidgetTester tester) async {
      await tester.dragFrom(
        const Offset(400, 250),
        const Offset(0, -500),
      );
      await pumpFor(tester);
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('冷启动 → 搜索 → 详情 → 设置切深色：全程 0 网络请求',
        (tester) async {
      final container = await pumpApp(tester);

      // ---- 1) 冷启动：首页渲染出卡片，首载骨架消失。----
      await pumpFor(tester, 400);
      await pumpUntilFound(tester, find.byType(PokemonCard));
      expect(find.byType(SkeletonGrid), findsNothing);
      // medium 布局首页无总数标题行；卡片为真实库前 60 条（编号升序）。
      expect(find.text('#001'), findsOneWidget);
      assertNoException(tester, '冷启动首页');

      // ---- 2) 搜索：中文 / 编号 / 日文（真实 200ms 防抖）。----
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, '皮卡');
      await pumpFor(tester); // 防抖 200ms 落定
      await pumpUntilFound(tester, find.text('皮卡丘'));
      expect(find.byType(EmptyState), findsNothing);
      assertNoException(tester, '搜索「皮卡」');

      await tester.enterText(searchField, '25');
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('皮卡丘'));
      expect(find.text('#025'), findsOneWidget);
      assertNoException(tester, '搜索「25」');

      await tester.enterText(searchField, 'フシギダネ');
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('妙蛙种子'));
      assertNoException(tester, '搜索「フシギダネ」');

      // ---- 3) 点击妙蛙种子卡片 → push 详情页：头部名称 / 属性。----
      // 等待信号用头部特有文本（列表卡片的名称/编号同名，无法区分就绪）。
      await tester.tap(find.text('妙蛙种子').first);
      await pumpFor(tester);
      await pumpUntilFound(tester, find.textContaining('Bulbasaur · '));
      expect(find.text('妙蛙种子'), findsWidgets); // 头部中文名（+列表卡片）
      expect(find.textContaining('Bulbasaur · フシギダネ'), findsOneWidget);
      expect(find.byType(TypeBadge), findsAtLeastNWidgets(2)); // 草 / 毒
      expect(find.byType(BackButton), findsOneWidget); // 全页详情有返回
      assertNoException(tester, '详情页头部');

      // 种族值总和 318（45+49+49+65+65+45，真实库 form 1）。
      await openTab(tester, '种族值');
      await pumpUntilFound(tester, find.text('总和 318'));
      assertNoException(tester, '种族值 tab');

      // ---- 4) 进化 tab：伊布不可见，妙蛙种子三段链渲染。----
      await openTab(tester, '进化');
      await pumpUntilFound(tester, find.text('妙蛙草'));
      expect(find.text('妙蛙种子'), findsWidgets); // 链根（当前项）
      expect(find.text('妙蛙草'), findsOneWidget);
      expect(find.text('妙蛙花'), findsOneWidget);
      expect(find.text('伊布'), findsNothing);
      assertNoException(tester, '进化 tab');

      // ---- 4b) 招式 tab：学习集行出现；方法筛选生效（朱/紫无学习器招式）。----
      await openTab(tester, '招式');
      await collapseHeader(tester);
      await pumpUntilFound(tester, find.text('共 53 个招式'));
      expect(find.text('撞击'), findsOneWidget); // Lv.1 首个升级招式
      expect(find.widgetWithText(VersionChip, '朱/紫'), findsOneWidget);
      assertNoException(tester, '招式 tab 默认列表');

      // 来源筛选「学习器」：妙蛙种子在朱/紫无 machine 招式 → 空态。
      await tester.tap(find.text('学习器').first);
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('没有匹配的招式'));
      assertNoException(tester, '招式方法筛选');

      // ---- 4c) 图鉴说明 tab：官方简中文本渲染。----
      // 默认选中 gen8 组内最新的「盾」（version_id 34 > 剑 33），
      // 显示盾版官方简中文本。
      await openTab(tester, '图鉴说明');
      await pumpUntilFound(
        tester,
        find.textContaining('在出生后的一段时间内'),
      );
      // 有官方简中：不出现语言回退提示。
      expect(find.textContaining('暂无简体中文资料'), findsNothing);
      assertNoException(tester, '图鉴说明 tab');

      // ---- 5) 返回图鉴 → 导航到设置 → 切深色 → 返回图鉴。----
      // 详情页是 push 的全页路由，先 pop 回到图鉴首页；等 pop 转场
      // 完全结束再 tap（转场中路由层仍在命中范围内，会吃掉 tap）。
      expect(find.byType(BackButton), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await pumpFor(tester);
      final rail = find.byType(NavigationRail);
      await pumpUntilFound(tester, rail);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(
        find.descendant(of: rail, matching: find.text('设置')),
      );
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('桌面卡片密度'));

      await tester.tap(find.text('深色'));
      await pumpFor(tester, 100);
      expect(container.read(themeModeProvider), ThemeMode.dark);
      assertNoException(tester, '设置切深色');

      await tester.tap(
        find.descendant(of: rail, matching: find.text('图鉴')),
      );
      await pumpFor(tester);
      await pumpUntilFound(tester, find.text('搜索 名称 / 编号'));
      assertNoException(tester, '返回图鉴');

      // ---- 6) 终检：全程无未消费异常。----
      expect(tester.takeException(), isNull,
          reason: '产生网络请求（OfflineRequestBlocked）或其他运行时异常');
    });
  });
}
