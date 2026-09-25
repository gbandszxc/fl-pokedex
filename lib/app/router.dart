import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/favorites/favorites_page.dart';
import '../features/pokedex/pokedex_home_page.dart';
import '../features/pokemon_detail/pokemon_detail_page.dart';
import '../features/settings/settings_page.dart';
import 'placeholder/move_detail_placeholder_page.dart';
import 'shell/adaptive_scaffold.dart';

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
        builder: (context, state) {
          final speciesId =
              int.tryParse(state.pathParameters['speciesId'] ?? '');
          return speciesId == null
              ? const PokemonDetailPage.notFound()
              : PokemonDetailPage(speciesId: speciesId);
        },
      ),
      GoRoute(
        path: '/move/:moveId',
        builder: (context, state) => MoveDetailPlaceholderPage(
          moveId: int.parse(state.pathParameters['moveId']!),
        ),
      ),
    ],
  );
});
