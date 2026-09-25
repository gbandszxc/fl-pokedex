import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fl_pokedex/domain/models/filters.dart';
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
    test('主图鉴白名单过滤：只保留 kanto / johto / hoenn', () async {
      final container = makeContainer();

      final refs = await container.read(pokedexRefsProvider.future);

      expect(
        refs.pokedexes.map((e) => e.identifier),
        ['kanto', 'johto', 'hoenn'],
      );
      expect(refs.types, hasLength(5));
      expect(refs.generations, hasLength(9));
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
