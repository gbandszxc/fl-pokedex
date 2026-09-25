import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../core/di.dart';
import '../../domain/models/pokemon_summary.dart';
import '../../shared/widgets/widgets.dart';
import 'providers.dart';

/// 收藏页（design-ui.md §1 视觉复用 + 个人数据）：
///
/// - 顶部「最近浏览」横向缩略图行（宽 76，最新 12 个，空则不显示）；
/// - 下方收藏网格 / 列表（跟随首页视图模式，maxCrossAxisExtent 200），
///   点按进详情并记录最近浏览，心形可直接取消收藏；
/// - 空态：「还没有收藏 / 去图鉴点亮心形吧」。
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('收藏')),
      body: Center(
        child: ConstrainedBox(
          // expanded 断点下内容最大宽 960 居中。
          constraints: const BoxConstraints(maxWidth: 960),
          child: const _FavoritesBody(),
        ),
      ),
    );
  }
}

class _FavoritesBody extends ConsumerWidget {
  const _FavoritesBody();

  static const double _gridMaxCrossAxisExtent = 200;
  static const double _gridAspectRatio = 0.82;
  static const double _recentThumbWidth = 76;
  static const double _recentsRowHeight = 102;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteSummariesProvider);
    final recentsAsync = ref.watch(recentSummariesProvider);
    final viewMode = ref.watch(favoritesViewModeProvider);

    final loading = favoritesAsync.isLoading;
    final favorites = favoritesAsync.valueOrNull;
    final recents = recentsAsync.valueOrNull ?? const <PokemonSummary>[];

    if (loading && favorites == null) {
      return viewMode == FavoritesViewMode.list
          ? SkeletonList(itemCount: 8)
          : SkeletonGrid(itemCount: 8);
    }
    if (favoritesAsync.hasError && favorites == null) {
      return EmptyState(
        title: '加载失败',
        message: '收藏数据读取出现问题，请重试。',
        icon: Icons.error_outline,
        action: FilledButton(
          onPressed: () => ref.invalidate(favoriteSummariesProvider),
          child: const Text('重试'),
        ),
      );
    }
    if (favorites == null) {
      return const SizedBox.shrink();
    }

    final pad = pagePaddingFor(context);
    final isGrid = viewMode == FavoritesViewMode.grid;

    if (favorites.isEmpty && recents.isEmpty) {
      return const EmptyState(
        title: '还没有收藏',
        message: '去图鉴点亮心形吧',
        icon: Icons.favorite_border,
      );
    }

    return CustomScrollView(
      slivers: [
        if (recents.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(pad, AppSpacing.m, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: pad),
                    child: const SectionTitle(title: '最近浏览'),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  SizedBox(
                    height: _recentsRowHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(
                        bottom: AppSpacing.xs,
                      ),
                      itemCount: recents.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.s),
                      itemBuilder: (context, index) => _RecentThumb(
                        summary: recents[index],
                        width: _recentThumbWidth,
                        onTap: () => _open(context, ref, recents[index]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (favorites.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              title: '还没有收藏',
              message: '去图鉴点亮心形吧',
              icon: Icons.favorite_border,
            ),
          )
        else
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              pad,
              recents.isEmpty ? AppSpacing.m : AppSpacing.l,
              pad,
              AppSpacing.m,
            ),
            sliver: isGrid
                ? SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: _gridMaxCrossAxisExtent,
                      mainAxisSpacing: AppSpacing.m,
                      crossAxisSpacing: AppSpacing.m,
                      childAspectRatio: _gridAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FavoriteCard(
                        summary: favorites[index],
                      ),
                      childCount: favorites.length,
                      addAutomaticKeepAlives: false,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _FavoriteTile(
                        summary: favorites[index],
                      ),
                      childCount: favorites.length,
                      addAutomaticKeepAlives: false,
                    ),
                  ),
          ),
      ],
    );
  }
}

/// 收藏网格卡片：恒为已收藏态，心形可直接取消收藏。
class _FavoriteCard extends ConsumerWidget {
  const _FavoriteCard({required this.summary});

  final PokemonSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PokemonCard(
      nationalDex: summary.nationalDex,
      nameZh: summary.nameZh,
      nameEn: summary.nameEn,
      typeIds: summary.typeIds,
      artworkAsset: summary.thumbAsset,
      isFavorite: true,
      onFavoriteToggle: (_) => unawaited(
        ref.read(favoritesRepositoryProvider).toggleFavorite(summary.speciesId),
      ),
      onTap: () => _open(context, ref, summary),
    );
  }
}

/// 收藏列表行：同上，列表视觉。
class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.summary});

  final PokemonSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PokemonListTile(
      nationalDex: summary.nationalDex,
      nameZh: summary.nameZh,
      nameEn: summary.nameEn,
      typeIds: summary.typeIds,
      thumbAsset: summary.thumbAsset,
      isFavorite: true,
      onFavoriteToggle: (_) => unawaited(
        ref.read(favoritesRepositoryProvider).toggleFavorite(summary.speciesId),
      ),
      onTap: () => _open(context, ref, summary),
    );
  }
}

/// 进入详情：记录最近浏览 + 路由跳转（与首页行为一致）。
void _open(BuildContext context, WidgetRef ref, PokemonSummary summary) {
  unawaited(
    ref.read(favoritesRepositoryProvider).addRecent(summary.speciesId),
  );
  context.push('/pokemon/${summary.speciesId}');
}

/// 「最近浏览」缩略图（图 + 名，宽 76）。
class _RecentThumb extends StatelessWidget {
  const _RecentThumb({
    required this.summary,
    required this.width,
    required this.onTap,
  });

  final PokemonSummary summary;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final placeholder = Container(
      width: width,
      height: width,
      color: scheme.surfaceContainerLow,
      alignment: Alignment.center,
      child: Icon(Icons.catching_pokemon, color: scheme.outline, size: 24),
    );
    final asset = summary.thumbAsset;

    return SizedBox(
      key: ValueKey('recent_thumb_${summary.speciesId}'),
      width: width,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Column(
            children: [
              SizedBox(
                width: width,
                height: width,
                child: Material(
                  color: scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  clipBehavior: Clip.antiAlias,
                  child: asset == null
                      ? placeholder
                      : Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          cacheWidth: (width * dpr).round(),
                          errorBuilder: (_, __, ___) => placeholder,
                        ),
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
      ),
    );
  }
}
