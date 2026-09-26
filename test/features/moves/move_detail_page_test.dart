import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fl_pokedex/app/theme/theme.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/domain/models/ability_ref.dart';
import 'package:fl_pokedex/domain/models/evolution.dart';
import 'package:fl_pokedex/domain/models/filters.dart';
import 'package:fl_pokedex/domain/models/flavor_entry.dart';
import 'package:fl_pokedex/domain/models/form_summary.dart';
import 'package:fl_pokedex/domain/models/manifest.dart';
import 'package:fl_pokedex/domain/models/move_detail.dart';
import 'package:fl_pokedex/domain/models/move_entry.dart';
import 'package:fl_pokedex/domain/models/pokemon_summary.dart';
import 'package:fl_pokedex/domain/models/refs.dart';
import 'package:fl_pokedex/domain/models/species_info.dart';
import 'package:fl_pokedex/domain/models/stat_block.dart';
import 'package:fl_pokedex/domain/repositories/pokedex_repository.dart';
import 'package:fl_pokedex/features/moves/move_detail_page.dart';
import 'package:fl_pokedex/shared/widgets/widgets.dart';

/// 招式详情 fixtures。
class FakeMoveRepository implements PokedexRepository {
  /// 非 null 时 getMoveDetail 抛出该错误（整页失败态测试用）。
  Object? moveDetailError;

  final _moveDetails = <int, MoveDetail?>{
    1: const MoveDetail(
      id: 1,
      nameZh: '撞击',
      nameEn: 'Tackle',
      nameJa: 'たいあたり',
      typeId: 'normal',
      damageClass: 'physical',
      power: 40,
      pp: 35,
      accuracy: 100,
      priority: 0,
      effectEn: 'A physical charging attack.',
      flavorZh: '用整个身体撞上去，简单可靠。',
      generationId: 1,
    ),
    2: const MoveDetail(
      id: 2,
      nameZh: '电击',
      nameEn: 'Thunder Shock',
      nameJa: 'でんきショック',
      typeId: 'electric',
      damageClass: 'special',
      power: 40,
      pp: 30,
      accuracy: 100,
      priority: 0,
      effectChance: 10,
      effectEn:
          'Has a \$effect_chance% chance to paralyze the target.',
      generationId: 1,
    ),
    3: const MoveDetail(
      id: 3,
      nameZh: '挣扎',
      nameEn: 'Struggle',
      nameJa: 'わるあがき',
      typeId: 'normal',
      damageClass: 'physical',
      pp: 1,
      priority: 0,
      generationId: 1,
    ),
  };

  @override
  Future<MoveDetail?> getMoveDetail(int moveId) async {
    final error = moveDetailError;
    if (error != null) throw error;
    return _moveDetails[moveId];
  }

  @override
  Future<List<PokemonSummary>> queryPokemon(
    FilterState f, {
    required int limit,
    required int offset,
  }) =>
      throw UnimplementedError();

  @override
  Future<int> countPokemon(FilterState f) => throw UnimplementedError();

  @override
  Future<List<FormSummary>> getForms(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<StatBlock> getFormStats(int formId) => throw UnimplementedError();

  @override
  Future<List<AbilityRef>> getFormAbilities(int formId) =>
      throw UnimplementedError();

  @override
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<FlavorEntry>> getFormFlavorTexts(int formId) =>
      throw UnimplementedError();

  @override
  Future<EvolutionTree?> getEvolutionTree(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId) =>
      throw UnimplementedError();

  @override
  Future<List<MoveEntry>> getLearnset(
    int formId,
    String versionGroup, {
    Set<String>? methods,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<TypeRef>> getTypes() => throw UnimplementedError();

  @override
  Future<List<GenerationRef>> getGenerations() => throw UnimplementedError();

  @override
  Future<List<PokedexRef>> getPokedexes() => throw UnimplementedError();

  @override
  Future<SpeciesInfo> getSpeciesInfo(int speciesId) =>
      throw UnimplementedError();

  @override
  Future<List<PokemonSummary>> getPokemonSummaries(List<int> speciesIds) =>
      throw UnimplementedError();

  @override
  Future<DataManifest> getManifest() => throw UnimplementedError();
}

void main() {
  late FakeMoveRepository repo;

  setUp(() {
    repo = FakeMoveRepository();
  });

  Future<void> pumpPage(WidgetTester tester, {required int? moveId}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pokedexRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: buildLightTheme(),
          home: moveId == null
              ? const MoveDetailPage.notFound()
              : MoveDetailPage(moveId: moveId),
        ),
      ),
    );
    // 有界泵帧代替 pumpAndSettle（加载骨架有循环动画）。
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 60));
  }

  group('招式详情渲染', () {
    testWidgets('渲染名称 / 属性徽章 / 分类 / 数据网格 / 世代 / 效果 / 引用块',
        (tester) async {
      await pumpPage(tester, moveId: 1);

      // AppBar 标题与正文标题各一处。
      expect(find.text('撞击'), findsNWidgets(2));
      expect(find.text('Tackle · たいあたり'), findsOneWidget);
      expect(find.byType(TypeBadge), findsOneWidget);
      expect(find.text('物理'), findsOneWidget);
      expect(find.text('威力'), findsOneWidget);
      expect(find.text('命中'), findsOneWidget);
      expect(find.text('PP'), findsOneWidget);
      expect(find.text('优先度'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('第一世代'), findsOneWidget);
      expect(find.text('暂无简体中文说明'), findsOneWidget);
      expect(find.text('A physical charging attack.'), findsOneWidget);
    });

    testWidgets('flavor 引用块：surfaceContainerLow 底 + 圆角 12', (tester) async {
      await pumpPage(tester, moveId: 1);

      expect(find.text('用整个身体撞上去，简单可靠。'), findsOneWidget);
      final container = tester.widget<Container>(
        find.byKey(MoveDetailPage.flavorQuoteKey),
      );
      final decoration = container.decoration! as ShapeDecoration;
      expect(decoration.color, AppColors.light.surfaceContainerLow);
      expect(
        (decoration.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(12),
      );
    });

    testWidgets('effectChance 占位替换为 (N%)，无 flavor 则无引用块', (tester) async {
      await pumpPage(tester, moveId: 2);

      expect(
        find.text('Has a 10% chance to paralyze the target.'),
        findsOneWidget,
      );
      expect(find.byKey(MoveDetailPage.flavorQuoteKey), findsNothing);
    });

    testWidgets('威力 / 命中 / 效果缺失时显示 —，且不出现语言提示', (tester) async {
      await pumpPage(tester, moveId: 3);

      // 威力、命中、效果三处缺省。
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('暂无简体中文说明'), findsNothing);
      expect(find.text('PP'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('异常态', () {
    testWidgets('notFound 构造渲染未找到空态', (tester) async {
      await pumpPage(tester, moveId: null);

      expect(find.text('未找到'), findsOneWidget);
      expect(find.text('返回图鉴'), findsOneWidget);
    });

    testWidgets('仓储异常显示「加载失败」与重试', (tester) async {
      repo.moveDetailError = StateError('boom');
      await pumpPage(tester, moveId: 1);

      expect(find.text('加载失败'), findsOneWidget);
      expect(find.text('重试'), findsOneWidget);
    });
  });
}
