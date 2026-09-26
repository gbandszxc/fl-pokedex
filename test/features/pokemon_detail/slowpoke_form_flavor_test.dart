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

/// 呆呆兽(#79) 真实资产库下的图鉴说明形态归属回归：
/// 剑/盾地区图鉴登记的是伽勒尔形态，其文本在 form_flavor_texts
/// （data-contract §6）——切到「伽勒尔的样子」应显示剑/盾文本，
/// 切回默认形态应显示 species 级文本（lets-go 简中）。
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
          initialLocation: '/pokemon/79',
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

  testWidgets('切换伽勒尔形态 → 剑/盾文本；切回默认 → species 文本', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // 默认形态：species 级最新含简中的版本（lets-go）文本。
    const speciesText = '非常呆，动作也很缓慢。从不在意时间的流逝，过着悠闲的生活。';
    expect(find.text(speciesText), findsOneWidget);

    // 切到伽勒尔的样子：图鉴说明即时刷新为盾版本文本，不残留旧文本。
    await tester.tap(find.widgetWithText(VersionChip, '伽勒尔的样子'));
    await tester.pumpAndSettle();
    const galarText = '把尾巴泡在水里后会有甜味渗出，因此它会以尾巴为诱饵吸引宝可梦并将其钓起。';
    expect(find.text(galarText), findsOneWidget);
    expect(find.text(speciesText), findsNothing);
    // 版本 chips 随数据自然变化：显示盾版本文本组（剑/盾属第八世代）。
    expect(find.widgetWithText(VersionChip, '盾'), findsOneWidget);

    // 切回默认形态：回到 species 级文本。
    await tester.tap(find.widgetWithText(VersionChip, '呆呆兽'));
    await tester.pumpAndSettle();
    expect(find.text(speciesText), findsOneWidget);
    expect(find.text(galarText), findsNothing);
  });
}
