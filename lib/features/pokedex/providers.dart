import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di.dart';
import '../../domain/models/filters.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../domain/models/refs.dart';

/// 首页列表视图模式（design-ui.md §1：网格 / 列表）。
enum PokemonViewMode { grid, list }

/// 每页条数：首页 60 条，滚动近底部按页追加。
const int pokemonPageSize = 60;

/// 列表分页状态（architecture.md §5：{items, total, isLoadingMore}）。
class PokemonPageState {
  const PokemonPageState({
    this.items = const [],
    this.total = 0,
    this.isLoadingMore = false,
  });

  /// 当前已加载条目（national_dex 升序，由仓储保证）。
  final List<PokemonSummary> items;

  /// 当前筛选下的总数（species 计）。
  final int total;

  /// 是否正在追加下一页（防重入标记）。
  final bool isLoadingMore;

  PokemonPageState copyWith({
    List<PokemonSummary>? items,
    int? total,
    bool? isLoadingMore,
  }) {
    return PokemonPageState(
      items: items ?? this.items,
      total: total ?? this.total,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// 筛选状态（搜索框 + 筛选面板的唯一事实来源）。
///
/// 变更即触发 [pokemonListProvider] 重建；语义化方法供 UI 调用。
class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  /// 搜索词（原样传入，trim / 编号识别由仓储按 §7 处理）。
  void updateQuery(String value) {
    if (state.query == value) {
      return;
    }
    state = state.copyWith(query: value);
  }

  void toggleGeneration(int id) {
    state = state.copyWith(generations: _toggled(state.generations, id));
  }

  void toggleType(String typeId) {
    state = state.copyWith(typeIds: _toggled(state.typeIds, typeId));
  }

  /// 双属性匹配模式（仅 typeIds 非空时有实际效果）。
  void setTypeMatchMode(TypeMatchMode mode) {
    if (state.typeMatchMode == mode) {
      return;
    }
    state = state.copyWith(typeMatchMode: mode);
  }

  void togglePokedex(int id) {
    state = state.copyWith(pokedexIds: _toggled(state.pokedexIds, id));
  }

  void toggleTag(SpecialTag tag) {
    state = state.copyWith(tags: _toggled(state.tags, tag));
  }

  /// 编号区间；传 null 表示不限制（全区间等价于无约束）。
  void setDexRange({required int? min, required int? max}) {
    if (state.dexMin == min && state.dexMax == max) {
      return;
    }
    state = state.copyWith(dexMin: min, dexMax: max);
  }

  /// 清空全部筛选（含搜索词）。
  void clear() => state = const FilterState();

  /// 含则移除、否则添加，返回新集合（freezed 不可变约定）。
  static Set<T> _toggled<T>(Set<T> source, T value) {
    final next = Set<T>.of(source);
    if (!next.remove(value)) {
      next.add(value);
    }
    return next;
  }
}

final filterProvider = NotifierProvider<FilterNotifier, FilterState>(
  FilterNotifier.new,
);

/// 首页列表：watch [filterProvider]，筛选/搜索变更自动重建（回到第 1 页）。
///
/// 重建期间的 AsyncLoading 保留旧数据（Riverpod copyWithPrevious 语义），
/// UI 据此显示「细进度条 + 旧列表」而非骨架。
///
/// 注意：Riverpod 2 中 Notifier 实例在依赖触发的重建间是复用的，
/// 因此用代数计数器识别「loadMore 进行中发生了重建」并丢弃过期写回。
class PokemonListNotifier extends AsyncNotifier<PokemonPageState> {
  /// 当前 build 代数；依赖变更触发重建时自增。
  int _generation = 0;

  @override
  Future<PokemonPageState> build() async {
    final generation = ++_generation;
    final filter = ref.watch(filterProvider);
    final repo = ref.watch(pokedexRepositoryProvider);
    final items = await repo.queryPokemon(
      filter,
      limit: pokemonPageSize,
      offset: 0,
    );
    final total = await repo.countPokemon(filter);
    if (generation != _generation) {
      // 已被更新的筛选重建取代（Riverpod 也会取消过期 build 的落库，
      // 这里再保险一次，避免任何路径的过期写回）。
      return state.valueOrNull ?? PokemonPageState(items: items, total: total);
    }
    return PokemonPageState(items: items, total: total);
  }

  /// 滚动近底部追加下一页；防重入：追加中重复调用直接返回。
  Future<void> loadMore() async {
    final generation = _generation;
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore) {
      return;
    }
    if (current.items.length >= current.total) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));

    final repo = ref.read(pokedexRepositoryProvider);
    final filter = ref.read(filterProvider);
    try {
      final more = await repo.queryPokemon(
        filter,
        limit: pokemonPageSize,
        offset: current.items.length,
      );
      if (generation != _generation) {
        return; // 追加期间筛选已变更，结果作废。
      }
      final value = state.valueOrNull;
      if (value == null) {
        return;
      }
      final known = value.items.map((e) => e.speciesId).toSet();
      final merged = [
        ...value.items,
        ...more.where((e) => !known.contains(e.speciesId)),
      ];
      state = AsyncData(value.copyWith(items: merged, isLoadingMore: false));
    } on Object catch (error, stackTrace) {
      if (generation != _generation) {
        return;
      }
      // 追加失败不推翻已加载数据，仅复位防重入标记。
      debugPrint('loadMore failed: $error\n$stackTrace');
      final value = state.valueOrNull;
      if (value != null) {
        state = AsyncData(value.copyWith(isLoadingMore: false));
      }
    }
  }
}

final pokemonListProvider =
    AsyncNotifierProvider<PokemonListNotifier, PokemonPageState>(
  PokemonListNotifier.new,
);

const String _viewModePrefsKey = 'view_mode';

/// 列表视图模式：初始化异步读一次 SharedPreferences（key `view_mode`），
/// 之后内存态为准，切换时写回。
class ListViewModeNotifier extends Notifier<PokemonViewMode> {
  /// 用户已显式切换时忽略尚未完成的恢复读取，避免回跳。
  bool _settled = false;

  /// Provider 生命周期结束后不再回写 state（riverpod 2 无 ref.mounted）。
  bool _disposed = false;

  @override
  PokemonViewMode build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return PokemonViewMode.grid;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed || _settled) {
      return;
    }
    _settled = true;
    state = switch (prefs.getString(_viewModePrefsKey)) {
      'list' => PokemonViewMode.list,
      _ => PokemonViewMode.grid,
    };
  }

  void set(PokemonViewMode mode) {
    _settled = true;
    if (state == mode) {
      return;
    }
    state = mode;
    unawaited(_persist(mode));
  }

  /// 网格 / 列表一键互换。
  void toggle() => set(
        state == PokemonViewMode.grid
            ? PokemonViewMode.list
            : PokemonViewMode.grid,
      );

  Future<void> _persist(PokemonViewMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModePrefsKey, mode.name);
  }
}

final listViewModeProvider =
    NotifierProvider<ListViewModeNotifier, PokemonViewMode>(
  ListViewModeNotifier.new,
);

/// 筛选面板引用数据：属性 / 世代 / 图鉴（主图鉴白名单过滤后）。
class PokedexRefs {
  const PokedexRefs({
    required this.types,
    required this.generations,
    required this.pokedexes,
  });

  final List<TypeRef> types;
  final List<GenerationRef> generations;
  final List<PokedexRef> pokedexes;
}

/// 主图鉴 identifier 白名单（含子图鉴的全量 32 个中只留这 12 个）。
const Set<String> primaryPokedexIds = {
  'kanto',
  'johto',
  'hoenn',
  'sinnoh',
  'unova',
  'kalos-central',
  'kalos-coastal',
  'kalos-mountain',
  'alola',
  'galar',
  'hisui',
  'paldea',
};

/// 一次性取引用数据并缓存，供筛选面板（行 chips + BottomSheet）使用。
final pokedexRefsProvider = FutureProvider<PokedexRefs>((ref) async {
  final repo = ref.watch(pokedexRepositoryProvider);
  final types = await repo.getTypes();
  final generations = await repo.getGenerations();
  final allPokedexes = await repo.getPokedexes();
  final pokedexes =
      allPokedexes.where((p) => primaryPokedexIds.contains(p.identifier))
          .toList();
  return PokedexRefs(
    types: types,
    generations: generations,
    pokedexes: pokedexes,
  );
});

/// 已收藏 speciesId 集合（流式），首页心形状态展示用。
///
/// features 之间禁止互相 import，故在本单元内自建；与收藏页
/// （G 单元的 favoriteIdsProvider）共享同一仓储流，数据一致。
final favoriteSpeciesIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchFavoriteSpeciesIds();
});
