import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/domain/models/filters.dart';
import 'package:fl_pokedex/domain/models/refs.dart';
import 'package:fl_pokedex/features/pokedex/providers.dart';

import 'fakes.dart';

void main() {
  late FakePokedexRepository pokedex;
  late FakeFavoritesRepository favorites;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    pokedex = FakePokedexRepository();
    favorites = FakeFavoritesRepository();
    addTearDown(favorites.dispose);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: fakeRepositoryOverrides(
        pokedex: pokedex,
        favorites: favorites,
      ),
    );
    addTearDown(container.dispose);
    return container;
  }

  /// 等依赖变更调度完成后重读列表状态。
  Future<PokemonPageState> settledState(ProviderContainer container) async {
    await Future<void>.delayed(Duration.zero);
    return container.read(pokemonListProvider.future);
  }

  group('pokemonListProvider', () {
    test('初始加载第 1 页 60 条，total 为全部 70', () async {
      final container = makeContainer();

      final state = await container.read(pokemonListProvider.future);

      expect(state.items, hasLength(60));
      expect(state.total, 70);
      expect(state.isLoadingMore, isFalse);
      expect(
        state.items.map((e) => e.nationalDex),
        everyElement(lessThanOrEqualTo(60)),
      );
    });

    test('loadMore 追加剩余 10 条且不重复', () async {
      final container = makeContainer();
      await container.read(pokemonListProvider.future);

      await container.read(pokemonListProvider.notifier).loadMore();

      final state = container.read(pokemonListProvider).requireValue;
      expect(state.items, hasLength(70));
      expect(state.items.map((e) => e.speciesId).toSet(), hasLength(70));
      expect(state.items.first.nationalDex, 1);
      expect(state.items.last.nationalDex, 70);
    });

    test('已加载全部后 loadMore 为 no-op', () async {
      final container = makeContainer();
      await container.read(pokemonListProvider.future);
      final notifier = container.read(pokemonListProvider.notifier);
      await notifier.loadMore();
      final before = container.read(pokemonListProvider).requireValue;

      await notifier.loadMore();
      await notifier.loadMore();

      final after = container.read(pokemonListProvider).requireValue;
      expect(after.items, same(before.items));
      expect(after.isLoadingMore, isFalse);
    });

    test('query 变更触发重载并传递 FilterState（§7 编号语义）', () async {
      final container = makeContainer();
      await container.read(pokemonListProvider.future);

      container.read(filterProvider.notifier).updateQuery('001');
      final state = await settledState(container);

      expect(pokedex.lastFilter?.query, '001');
      expect(state.items, hasLength(1));
      expect(state.items.single.nationalDex, 1);
      expect(state.total, 1);
    });

    test('文本 query 传递原文，由仓储负责匹配', () async {
      final container = makeContainer();
      await container.read(pokemonListProvider.future);

      container.read(filterProvider.notifier).updateQuery('皮卡');
      final state = await settledState(container);

      expect(pokedex.lastFilter?.query, '皮卡');
      expect(state.total, 1);
      expect(state.items.single.nameZh, '皮卡丘');
    });

    test('重载期间保留 isLoadingMore=false 语义：翻页标记不跨筛选泄漏', () async {
      final container = makeContainer();
      await container.read(pokemonListProvider.future);
      final notifier = container.read(pokemonListProvider.notifier);
      await notifier.loadMore();

      container.read(filterProvider.notifier).updateQuery('皮卡');
      final state = await settledState(container);

      expect(state.items, hasLength(1));
      expect(state.isLoadingMore, isFalse);
    });
  });

  group('filterProvider', () {
    test('toggle 语义：含则移除、否则添加', () {
      final container = makeContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.toggleType('fire');
      notifier.toggleType('water');
      expect(container.read(filterProvider).typeIds, {'fire', 'water'});
      expect(container.read(filterProvider).isEmpty, isFalse);

      notifier.toggleType('fire');
      expect(container.read(filterProvider).typeIds, {'water'});

      notifier.toggleType('water');
      expect(container.read(filterProvider).isEmpty, isTrue);
    });

    test('setDexRange 写入区间，clear 清空一切', () {
      final container = makeContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.setDexRange(min: 5, max: 20);
      notifier.toggleTag(SpecialTag.legendary);
      var filter = container.read(filterProvider);
      expect(filter.dexMin, 5);
      expect(filter.dexMax, 20);
      expect(filter.tags, {SpecialTag.legendary});

      notifier.clear();
      filter = container.read(filterProvider);
      expect(filter.isEmpty, isTrue);
      expect(filter.typeMatchMode, TypeMatchMode.any);
    });

    test('setTypeMatchMode 与同值 updateQuery 不产生无效通知', () {
      final container = makeContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.setTypeMatchMode(TypeMatchMode.all);
      expect(container.read(filterProvider).typeMatchMode, TypeMatchMode.all);

      final before = container.read(filterProvider);
      notifier.updateQuery(before.query);
      expect(identical(container.read(filterProvider), before), isTrue);
    });
  });

  group('listViewModeProvider', () {
    test('持久化 roundtrip：初始读取 list，切换后写回 grid', () async {
      SharedPreferences.setMockInitialValues({'view_mode': 'list'});
      final container = makeContainer();

      // 构建时同步为 grid，随后异步恢复持久化值。
      expect(container.read(listViewModeProvider), PokemonViewMode.grid);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(listViewModeProvider), PokemonViewMode.list);

      container
          .read(listViewModeProvider.notifier)
          .set(PokemonViewMode.grid);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('view_mode'), 'grid');
      expect(container.read(listViewModeProvider), PokemonViewMode.grid);
    });

    test('无持久化值时默认 grid；toggle 互换', () async {
      final container = makeContainer();
      expect(container.read(listViewModeProvider), PokemonViewMode.grid);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(listViewModeProvider), PokemonViewMode.grid);

      container.read(listViewModeProvider.notifier).toggle();
      expect(container.read(listViewModeProvider), PokemonViewMode.list);
      container.read(listViewModeProvider.notifier).toggle();
      expect(container.read(listViewModeProvider), PokemonViewMode.grid);
    });
  });

  group('pokedexRefsProvider', () {
    test('按地区分组聚合：10 地区各 1 组、标签唯一、成员按 id 升序', () async {
      final container = makeContainer();

      final refs = await container.read(pokedexRefsProvider.future);

      final labels = refs.regionGroups.map((g) => g.labelZh).toList();
      expect(
        labels,
        // 与真实 DB 组序一致（世代序）；fixture 覆盖全部 10 组，
        // 裸名 'johto' 行不得产生任何组。
        [
          '关都图鉴',
          '城都图鉴',
          '丰缘图鉴',
          '神奥图鉴',
          '合众图鉴',
          '卡洛斯图鉴',
          '阿罗拉图鉴',
          '伽勒尔图鉴',
          '洗翠图鉴',
          '帕底亚图鉴',
        ],
      );
      expect(labels.toSet(), hasLength(labels.length), reason: '标签唯一无重复');
      // 卡洛斯三条同名子图鉴恰聚合为 1 组（缺陷①防回归），
      // 成员按 getPokedexes 原序（id 升序）。
      final kalos = refs.regionGroups.singleWhere(
        (g) => g.labelZh == '卡洛斯图鉴',
      );
      expect(kalos.pokedexes.map((p) => p.identifier).toList(), [
        'kalos-central',
        'kalos-coastal',
        'kalos-mountain',
      ]);
      expect(kalos.ids, {12, 13, 14});
      expect(refs.types, hasLength(5));
      expect(refs.generations, hasLength(9));
    });

    test('城都/神奥/合众/阿罗拉组均出现（缺陷②防回归：裸名不再是匹配途径）',
        () async {
      final container = makeContainer();

      final refs = await container.read(pokedexRefsProvider.future);

      for (final label in ['城都图鉴', '神奥图鉴', '合众图鉴', '阿罗拉图鉴']) {
        expect(
          refs.regionGroups.map((g) => g.labelZh),
          contains(label),
          reason: '$label 应按 DB 真实 identifier 成组出现',
        );
      }
      // 城都组由 original-johto + updated-johto 两条同名行组成，
      // 而非裸名 'johto' 行（id=99）。
      final johto = refs.regionGroups.singleWhere(
        (g) => g.labelZh == '城都图鉴',
      );
      expect(johto.ids, {3, 7});
    });

    test('子图鉴（melemele）不入任何组', () async {
      final container = makeContainer();

      final refs = await container.read(pokedexRefsProvider.future);

      final allIds = refs.regionGroups.expand((g) => g.ids).toSet();
      expect(allIds, isNot(contains(17))); // original-melemele
    });

    test('组内部分 identifier 缺失仍成组；整组缺失不渲染', () async {
      // 仅 kanto 行（缺 letsgo-kanto）+ 仅 kalos-central（缺海岸/山岳），
      // 且不提供伽勒尔任何行。
      final container = ProviderContainer(
        overrides: fakeRepositoryOverrides(
          pokedex: _PartialPokedexesFake(),
          favorites: favorites,
        ),
      );
      addTearDown(container.dispose);

      final refs = await container.read(pokedexRefsProvider.future);

      final labels = refs.regionGroups.map((g) => g.labelZh).toList();
      expect(labels, contains('关都图鉴'), reason: '组内部分缺失仍成组');
      expect(labels, contains('卡洛斯图鉴'), reason: '组内部分缺失仍成组');
      expect(labels, isNot(contains('伽勒尔图鉴')), reason: '整组缺失不渲染');
      final kalos = refs.regionGroups.singleWhere(
        (g) => g.labelZh == '卡洛斯图鉴',
      );
      expect(kalos.ids, {12});
    });
  });

  group('primaryPokedexIdGroups 常量', () {
    test('各组 pokedex id 载荷两两不相交（成组开关互不误伤）', () {
      final seen = <String>{};
      for (final group in primaryPokedexIdGroups) {
        for (final identifier in group) {
          expect(
            seen.add(identifier),
            isTrue,
            reason: '$identifier 重复出现在多个分组',
          );
        }
      }
      expect(primaryPokedexIdGroups, hasLength(10));
    });
  });

  group('togglePokedexGroup', () {
    test('首次点选写入组内全部 id，再点全移除', () {
      final container = makeContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.togglePokedexGroup({12, 13, 14});
      expect(container.read(filterProvider).pokedexIds, {12, 13, 14});

      notifier.togglePokedexGroup({12, 13, 14});
      expect(container.read(filterProvider).pokedexIds, isEmpty);
    });

    test('两组可并存（多选并集），部分交集按整组移除', () {
      final container = makeContainer();
      final notifier = container.read(filterProvider.notifier);

      notifier.togglePokedexGroup({2, 26}); // 关都
      notifier.togglePokedexGroup({12, 13, 14}); // 卡洛斯
      expect(container.read(filterProvider).pokedexIds, {2, 26, 12, 13, 14});

      // 已含 12/13/14 的超集仍判为选中 → 整组移除卡洛斯，保留关都。
      notifier.togglePokedexGroup({12, 13, 14});
      expect(container.read(filterProvider).pokedexIds, {2, 26});
    });
  });

  group('favoriteSpeciesIdsProvider', () {
    test('推送仓储流的收藏集合', () async {
      final container = makeContainer();
      final events = <List<int>?>[];
      container.listen(
        favoriteSpeciesIdsProvider,
        (_, next) => events.add(next.valueOrNull),
      );

      // async* 生成器先推初始收藏（空）。
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(events.whereType<List<int>>(), contains(isEmpty));

      await favorites.toggleFavorite(25);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(events.last, [25]);
    });
  });
}

/// getPokedexes 只返回部分 identifier：验证上游漂移下的成组容错
/// （组内部分缺失仍成组、整组缺失不渲染）。
class _PartialPokedexesFake extends FakePokedexRepository {
  @override
  Future<List<PokedexRef>> getPokedexes() async => const [
        PokedexRef(id: 2, identifier: 'kanto', nameZh: '关都图鉴', generationId: 1),
        PokedexRef(
          id: 12,
          identifier: 'kalos-central',
          nameZh: '卡洛斯图鉴',
          generationId: 6,
        ),
      ];
}
