import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/favorites/favorites_page.dart';
import '../features/moves/move_detail_page.dart';
import '../features/pokedex/pokedex_home_page.dart';
import '../features/pokemon_detail/pokemon_detail_page.dart';
import '../features/settings/settings_page.dart';
import 'shell/adaptive_scaffold.dart';
import 'theme/theme.dart';

/// 路由表（architecture.md §9，路径锁死）：
/// ```
/// /                     图鉴（StatefulShellRoute branch 0）
/// /favorites            收藏（branch 1）
/// /settings             设置（branch 2）
/// /pokemon/:speciesId   详情
/// /move/:moveId         招式详情
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdaptiveScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const PokedexHomePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsPage(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/pokemon/:speciesId',
        pageBuilder: (context, state) {
          final speciesId =
              int.tryParse(state.pathParameters['speciesId'] ?? '');
          final child = speciesId == null
              ? const PokemonDetailPage.notFound()
              : PokemonDetailPage(speciesId: speciesId);
          // extra 携带切换方向时（滑动 / ←/→ 键切上一只下一只）播放
          // 方向性滑入：next 自右、prev 自左，旧页按自身进入方向滑出，
          // 合成翻页观感；列表点入 / deep link 无 extra，走平台默认过渡。
          final direction = state.extra;
          if (direction is! SpeciesSwitchDirection) {
            return MaterialPage(key: state.pageKey, child: child);
          }
          final begin = direction == SpeciesSwitchDirection.next
              ? const Offset(1, 0)
              : const Offset(-1, 0);
          return CustomTransitionPage(
            key: state.pageKey,
            child: child,
            transitionDuration: AppMotion.normal,
            transitionsBuilder: (context, animation, secondaryAnimation,
                child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: AppMotion.curve,
              );
              return SlideTransition(
                position:
                    Tween(begin: begin, end: Offset.zero).animate(curved),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/move/:moveId',
        builder: (context, state) {
          final moveId = int.tryParse(state.pathParameters['moveId'] ?? '');
          return moveId == null
              ? const MoveDetailPage.notFound()
              : MoveDetailPage(moveId: moveId);
        },
      ),
    ],
  );
});
