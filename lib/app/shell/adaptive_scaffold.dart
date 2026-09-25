import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/di.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../features/pokedex/pokedex_home_page.dart';
import '../../features/pokedex/providers.dart';
import '../../features/pokemon_detail/pokemon_detail_page.dart';
import '../../shared/responsive/breakpoints.dart';
import '../../shared/widgets/widgets.dart';

/// 自适应壳：compact → 底部 NavigationBar；medium/expanded → 侧边 NavigationRail。
///
/// 断点取自 [windowSizeFor]（DESIGN.md §3）；导航三项：图鉴 / 收藏 / 设置。
/// 宽 ≥1080（[twoPaneFor]）且停留在图鉴分支时渲染 master-detail 双栏：
/// 列表面板 + 1px outlineVariant 分隔线 + 详情面板（design-ui.md §2）。
/// 双栏下点卡片写 [paneSelectionProvider] 而非导航；从双栏推入的
/// 招式 / 详情页仍走顶层路由覆盖全窗（预期行为）。
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (windowSizeFor(width) == WindowSize.compact) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: (index) => _goBranch(index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: '图鉴',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: '收藏',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: '设置',
            ),
          ],
        ),
      );
    }

    // 图鉴分支 + 宽 ≥1080 → 双栏 master-detail；其余分支 / 窗口走原样。
    final showTwoPane =
        twoPaneFor(width) && navigationShell.currentIndex == 0;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: Text('图鉴'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: Text('收藏'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('设置'),
              ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: showTwoPane ? const _PokedexTwoPane() : navigationShell,
          ),
        ],
      ),
    );
  }

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// 图鉴分支双栏：列表面板（宽 clamp(360, 可用宽×0.42, 560)，复用
/// [PokedexHomeListContent] 的全部列表能力）+ 分隔线 + 详情面板。
class _PokedexTwoPane extends ConsumerWidget {
  const _PokedexTwoPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedSpeciesId = ref.watch(paneSelectionProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        // 可用宽不含导航栏（constraints 已扣除），面宽按设计稿 §2 比例取。
        final paneWidth =
            (constraints.maxWidth * 0.42).clamp(360.0, 560.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: paneWidth,
              child: const PokedexHomeListContent(embeddedInPane: true),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              // 4px 顶部内边距：详情页自带头部（SliverAppBar + 立绘）。
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: selectedSpeciesId == null
                    ? const _DetailPaneEmpty()
                    : KeyedSubtree(
                        // 按 speciesId 重建：换选中项时详情页状态归零，
                        // 且 initState 的 addRecent 对新条目生效。
                        key: ValueKey<int>(selectedSpeciesId),
                        child: PokemonDetailPage(
                          speciesId: selectedSpeciesId,
                          showBackButton: false,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 双栏详情面板空态：引导文案 + 可选「最近浏览」缩略行
/// （点按缩略图即选中到面板，不导航）。
class _DetailPaneEmpty extends ConsumerWidget {
  const _DetailPaneEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recents = ref.watch(_paneRecentSummariesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(
          child: EmptyState(
            title: '从左侧选择宝可梦',
            message: '查看详情',
            icon: Icons.touch_app_outlined,
          ),
        ),
        // 引用数据未就绪 / 加载失败时静默隐藏缩略行（可选增强，不阻塞主流程）。
        recents.whenOrNull(
              data: (summaries) =>
                  summaries.isEmpty ? null : _RecentStrip(summaries: summaries),
            ) ??
            const SizedBox.shrink(),
      ],
    );
  }
}

/// 空态面板底部的「最近浏览」横向缩略行。
class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.summaries});

  final List<PokemonSummary> summaries;

  @override
  Widget build(BuildContext context) {
    final pad = pagePaddingFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Text(
            '最近浏览',
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        const SizedBox(height: AppSpacing.s),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(pad, 0, pad, AppSpacing.xs),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.s),
            itemBuilder: (context, index) =>
                _PaneRecentThumb(summary: summaries[index]),
          ),
        ),
      ],
    );
  }
}

/// 最近浏览缩略图：点按 → 写入双栏选中态（由详情页自行记录最近浏览）。
class _PaneRecentThumb extends ConsumerWidget {
  const _PaneRecentThumb({required this.summary});

  final PokemonSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    const thumbSize = 56.0;
    final placeholder = Icon(
      Icons.catching_pokemon,
      size: 24,
      color: scheme.outline,
    );
    final asset = summary.thumbAsset;

    return InkWell(
      onTap: () => ref.read(paneSelectionProvider.notifier).state =
          summary.speciesId,
      borderRadius: const BorderRadius.all(Radius.circular(AppRadius.input)),
      child: SizedBox(
        width: thumbSize,
        child: Column(
          children: [
            Container(
              width: thumbSize,
              height: thumbSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius:
                    const BorderRadius.all(Radius.circular(AppRadius.input)),
              ),
              child: asset == null
                  ? placeholder
                  : Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      cacheWidth: (thumbSize * dpr).round(),
                      errorBuilder: (_, __, ___) => placeholder,
                    ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary.nameZh,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// 双栏空态「最近浏览」ids：features 之间禁止互相 import，壳内直接
/// watch 仓储自建本地流（与收藏页数据一致）。
final _paneRecentIdsProvider = StreamProvider<List<int>>((ref) {
  return ref.watch(favoritesRepositoryProvider).watchRecentSpeciesIds();
});

/// 最近浏览摘要（最新在前，最多 8 个），空态缩略行用。
final _paneRecentSummariesProvider =
    FutureProvider<List<PokemonSummary>>((ref) async {
  final ids = await ref.watch(_paneRecentIdsProvider.future);
  if (ids.isEmpty) {
    return const <PokemonSummary>[];
  }
  final latest = ids.reversed.take(8).toList();
  return ref.watch(pokedexRepositoryProvider).getPokemonSummaries(latest);
});
