import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/di.dart';
import '../../domain/models/pokemon_summary.dart';

/// 收藏 speciesId 流（仓储保证去重）。
final favoriteSpeciesIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchFavoriteSpeciesIds();
});

/// 最近浏览 speciesId 流（仓储保证去重 + 上限 30，最新在尾部）。
final recentIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchRecentSpeciesIds();
});

/// 「最近浏览」横向行最多展示条数。
const int recentDisplayLimit = 12;

/// 收藏摘要列表：ids → [PokedexRepository.getPokemonSummaries]
/// （按入参顺序返回，缺失的 species 自动跳过）。
///
/// ids 流每次推新（收藏/取消收藏）都会触发重建。
final favoriteSummariesProvider =
    FutureProvider<List<PokemonSummary>>((ref) async {
  final ids = await ref.watch(favoriteSpeciesIdsProvider.future);
  return ref.watch(pokedexRepositoryProvider).getPokemonSummaries(ids);
});

/// 最近浏览摘要列表：取最新 [recentDisplayLimit] 个，最新在前
/// （横向行从左到右即时间倒序）。
final recentSummariesProvider =
    FutureProvider<List<PokemonSummary>>((ref) async {
  final ids = await ref.watch(recentIdsProvider.future);
  final latest = ids.reversed.take(recentDisplayLimit).toList();
  return ref.watch(pokedexRepositoryProvider).getPokemonSummaries(latest);
});

/// 收藏页视图模式（design-ui.md §1：网格 / 列表）。
///
/// 与首页共享 SP key `view_mode`；features 之间禁止互相 import，
/// 故本 feature 自建（收藏页只读，不提供切换入口）。
enum FavoritesViewMode { grid, list }

/// 收藏页视图模式 Provider：启动异步恢复（key `view_mode`），默认网格。
class FavoritesViewModeNotifier extends Notifier<FavoritesViewMode> {
  bool _settled = false;

  bool _disposed = false;

  @override
  FavoritesViewMode build() {
    _settled = false;
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    unawaited(_restore());
    return FavoritesViewMode.grid;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _settled) {
        return;
      }
      _settled = true;
      state = prefs.getString('view_mode') == FavoritesViewMode.list.name
          ? FavoritesViewMode.list
          : FavoritesViewMode.grid;
    } on Object catch (error, stackTrace) {
      debugPrint('view_mode restore failed: $error\n$stackTrace');
    }
  }
}

/// 收藏页视图模式 Provider。
final favoritesViewModeProvider =
    NotifierProvider<FavoritesViewModeNotifier, FavoritesViewMode>(
  FavoritesViewModeNotifier.new,
);
