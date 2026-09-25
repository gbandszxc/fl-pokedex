import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/shared/widgets/favorite_button.dart';
import 'package:fl_pokedex/shared/widgets/type_badge.dart';

/// 编号显示格式：`#001`（三位补零，DESIGN.md §4 tabular 数字）。
String formatDexNumber(int nationalDex) =>
    '#${nationalDex.toString().padLeft(3, '0')}';

/// 网格卡片（design-ui.md §1）：surfaceContainer 底、r14、无阴影。
///
/// 布局：右上角编号（tabular）→ 立绘居中（缓存宽按 160 逻辑像素 × dpr）→
/// 底部中文名 + 英文名 + 属性徽章行（sm，最多 2 个）。收藏心形可选，
/// 未收藏时仅 hover / focus 显现（[FavoriteHeartButton]），因走 Stack
/// 定位，默认隐藏时布局不塌。
class PokemonCard extends StatelessWidget {
  const PokemonCard({
    super.key,
    required this.nationalDex,
    required this.nameZh,
    required this.nameEn,
    required this.typeIds,
    this.artworkAsset,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  final int nationalDex;
  final String nameZh;
  final String nameEn;

  /// 属性 identifier 列表，最多渲染 2 个。
  final List<String> typeIds;

  /// 立绘 asset 路径；null（或加载失败）时显示占位圆形色块。
  final String? artworkAsset;

  final bool isFavorite;

  /// 传了才启用收藏按钮。
  final ValueChanged<bool>? onFavoriteToggle;

  final VoidCallback? onTap;

  /// 立绘逻辑像素尺寸（缓存宽 = 此值 × devicePixelRatio）。
  static const double artworkSize = 104;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s),
              child: SizedBox(
                height: artworkSize,
                child: Stack(
                  children: [
                    Center(child: _artwork(context, dpr)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Text(
                        formatDexNumber(nationalDex),
                        style: AppTypography.tabularFigures(
                          textTheme.bodySmall ?? const TextStyle(),
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (isFavorite || onFavoriteToggle != null)
                      Positioned(
                        top: 22,
                        right: 0,
                        child: FavoriteHeartButton(
                          isFavorite: isFavorite,
                          onToggle: onFavoriteToggle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nameZh,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (i, typeId) in typeIds.take(2).indexed) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.xs),
                        TypeBadge(type: typeId, size: TypeBadgeSize.sm),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artwork(BuildContext context, double dpr) {
    final placeholder = Container(
      key: const ValueKey('pokemon_card_art_placeholder'),
      width: artworkSize,
      height: artworkSize,
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: const CircleBorder(),
      ),
    );
    final asset = artworkAsset;
    if (asset == null) {
      return placeholder;
    }
    return SizedBox(
      width: artworkSize,
      height: artworkSize,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        cacheWidth: (artworkSize * dpr).round(),
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
