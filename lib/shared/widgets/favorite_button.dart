import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/theme.dart';

/// 收藏心形按钮（卡片 / 列表行共用）。
///
/// 状态语义（DESIGN.md §6）：已收藏时常显（favorite 实心 + 品牌收藏色）；
/// 未收藏时仅 hover / 键盘 focus 下显现描边心形，触屏端不出现——收藏
/// 入口在详情页。隐藏时不保留命中区域，避免不可见热区。
class FavoriteHeartButton extends StatefulWidget {
  const FavoriteHeartButton({
    super.key,
    required this.isFavorite,
    this.onToggle,
    this.size = 22,
  });

  final bool isFavorite;

  /// 切换回调（传目标状态）；为 null 时仅作状态展示、不可交互。
  final ValueChanged<bool>? onToggle;

  /// 心形图标尺寸。
  final double size;

  @override
  State<FavoriteHeartButton> createState() => _FavoriteHeartButtonState();
}

class _FavoriteHeartButtonState extends State<FavoriteHeartButton> {
  bool _revealed = false;

  bool get _interactive => widget.onToggle != null;

  void _setRevealed(bool value) {
    if (!_interactive || _revealed == value) {
      return;
    }
    setState(() => _revealed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!(widget.isFavorite || _revealed)) {
      // 未显现：保留 hover/focus 探测，但不占布局、不接收点击。
      return MouseRegion(
        onEnter: _interactive ? (_) => _setRevealed(true) : null,
        onExit: _interactive ? (_) => _setRevealed(false) : null,
        child: const SizedBox.shrink(),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      onEnter: _interactive ? (_) => _setRevealed(true) : null,
      onExit: _interactive ? (_) => _setRevealed(false) : null,
      child: Focus(
        canRequestFocus: _interactive,
        onFocusChange: _setRevealed,
        child: Tooltip(
          message: widget.isFavorite ? '取消收藏' : '收藏',
          child: IconButton(
            onPressed:
                _interactive ? () => widget.onToggle!(!widget.isFavorite) : null,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              minWidth: widget.size + 8,
              minHeight: widget.size + 8,
            ),
            icon: Icon(
              widget.isFavorite ? Icons.favorite : Icons.favorite_border,
              size: widget.size,
              color: widget.isFavorite
                  ? AppBrand.favoriteOf(context)
                  : scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
