import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/data/database/pokedex_database.dart';
import 'package:fl_pokedex/data/repository/pokedex_repository_impl.dart';
import 'package:fl_pokedex/features/pokemon_detail/pokemon_detail_page.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

import '../../helpers/sqlite_loader.dart';

/// 真实资产库（assets/database/pokedex.db）下的详情页冒烟：
/// 锁定「真机数据流」的关键行为——皮卡丘多形态 chips 渲染与切换
/// （Windows 宿主需 tool/sqlite3/windows/sqlite3.dll，见 §10）。
void main() {
  loadSqliteForHostTests();

  late PokedexDatabase db;

  setUp(() {
    db = PokedexDatabase(
      PokedexDatabase.readOnlyExecutor(File('assets/database/pokedex.db')),
    );
  });
  tearDown(() => db.close());

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        pokedexRepositoryProvider.overrideWithValue(
          PokedexRepositoryImpl(
            db,
            loadManifestJson: () async => jsonDecode(
                  await File('assets/database/manifest.json').readAsString(),
                ) as Map<String, dynamic>,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: buildLightTheme(),
        routerConfig: GoRouter(
          initialLocation: '/pokemon/25',
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

  testWidgets('皮卡丘渲染形态 chips（真实库 17 形态）', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 真实库：默认形态 + 超极巨化（10199）等非默认形态 → chips 行渲染。
    // 默认形态外的个别形态简中名也含「皮卡丘」字样，故用 findsWidgets。
    expect(find.widgetWithText(VersionChip, '皮卡丘'), findsWidgets);
    expect(find.widgetWithText(VersionChip, '超极巨化'), findsOneWidget);
  });

  testWidgets('点击超极巨化后资料页身高切换为 21.0 m', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    tester.takeException();

    await tester.tap(find.widgetWithText(VersionChip, '超极巨化'));
    await tester.pumpAndSettle();

    // 收起折叠头部，切到资料 tab。
    await tester.drag(find.text('#025'), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('资料'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('资料'));
    await tester.pumpAndSettle();

    // 真实库：超极巨化 height=210 → 21.0 m（默认形态 0.4 m）。
    expect(find.text('21.0 m'), findsOneWidget);
  });
}
