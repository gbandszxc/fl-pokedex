import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/shared/widgets/favorite_button.dart';
import 'package:fl_pokedex/shared/widgets/pokemon_card.dart';
import 'package:fl_pokedex/shared/widgets/type_badge.dart';

/// 列表行（design-ui.md §1，高 64）：
/// thumb（缓存宽 96）+ 编号 + 中文名/英文名同行 + 右列属性徽章 + 可选心形。
class PokemonListTile extends StatelessWidget {
  const PokemonListTile({
    super.key,
    required this.nationalDex,
    required this.nameZh,
    required this.nameEn,
    required this.typeIds,
    this.thumbAsset,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  final int nationalDex;
  final String nameZh;
  final String nameEn;

  /// 属性 identifier 列表，最多渲染 2 个。
  final List<String> typeIds;

  /// 缩略图 asset 路径；null（或加载失败）时显示占位圆形色块。
  final String? thumbAsset;

  final bool isFavorite;

  /// 传了才启用收藏按钮。
  final ValueChanged<bool>? onFavoriteToggle;

  final VoidCallback? onTap;

  /// 缩略图逻辑像素尺寸。
  static const double thumbSize = 48;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
            child: Row(
              children: [
                _thumb(context),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  width: 44,
                  child: Text(
                    formatDexNumber(nationalDex),
                    style: AppTypography.tabularFigures(
                      textTheme.bodySmall ?? const TextStyle(),
                    ).copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          nameZh,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          nameEn,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (i, typeId) in typeIds.take(2).indexed) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.xs),
                      TypeBadge(type: typeId, size: TypeBadgeSize.sm),
                    ],
                  ],
                ),
                if (isFavorite || onFavoriteToggle != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  FavoriteHeartButton(
                    isFavorite: isFavorite,
                    onToggle: onFavoriteToggle,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumb(BuildContext context) {
    final placeholder = Container(
      key: const ValueKey('pokemon_list_tile_thumb_placeholder'),
      width: thumbSize,
      height: thumbSize,
      decoration: ShapeDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        shape: const CircleBorder(),
      ),
    );
    final asset = thumbAsset;
    if (asset == null) {
      return placeholder;
    }
    return SizedBox(
      width: thumbSize,
      height: thumbSize,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        cacheWidth: 96,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
