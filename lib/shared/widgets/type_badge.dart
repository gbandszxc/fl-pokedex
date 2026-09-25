import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/app_colors.dart';
import 'package:fl_pokedex/app/theme/tokens.dart';

/// 18 属性 identifier → 简体中文名（官方译名，DESIGN.md §2 顺序）。
const Map<String, String> kTypeNamesZh = {
  'normal': '一般',
  'fire': '火',
  'water': '水',
  'electric': '电',
  'grass': '草',
  'ice': '冰',
  'fighting': '格斗',
  'poison': '毒',
  'ground': '地面',
  'flying': '飞行',
  'psychic': '超能力',
  'bug': '虫',
  'rock': '岩石',
  'ghost': '幽灵',
  'dragon': '龙',
  'dark': '恶',
  'steel': '钢',
  'fairy': '妖精',
};

/// 属性徽章尺寸档（DESIGN.md §3：badge 为全 pill）。
enum TypeBadgeSize {
  /// 高 20 / 字 11，用于卡片、列表行的紧凑场景。
  sm(height: 20, fontSize: 11, paddingH: AppSpacing.s),

  /// 高 26 / 字 13，用于详情页、筛选面板。
  md(height: 26, fontSize: 13, paddingH: AppSpacing.m);

  const TypeBadgeSize({
    required this.height,
    required this.fontSize,
    required this.paddingH,
  });

  final double height;
  final double fontSize;
  final double paddingH;
}

/// 属性徽章：solid pill，底色取 [AppColors.typeColors]，前景取
/// [AppColors.typeForeground]（DESIGN.md §2 显式表，未知 identifier 回退
/// 主题 outline 中性灰）。属性中文名见 [kTypeNamesZh]。
///
/// 属性色只允许出现在徽章这一层级（DESIGN.md §7 禁令）。
class TypeBadge extends StatelessWidget {
  const TypeBadge({
    super.key,
    required this.type,
    this.size = TypeBadgeSize.md,
    this.label,
    this.onTap,
  });

  /// 属性 identifier（snake 全小写，如 "fire"）。
  final String type;

  final TypeBadgeSize size;

  /// 覆盖显示文本；缺省时查 [kTypeNamesZh]，仍无则原样显示 identifier。
  final String? label;

  final VoidCallback? onTap;

  /// 徽章底色：属性表命中否则回退主题 outline（中性灰）。
  static Color backgroundOf(BuildContext context, String identifier) =>
      AppColors.typeColors[identifier] ?? Theme.of(context).colorScheme.outline;

  /// 徽章前景色：DESIGN.md §2 显式表优先，否则按底色亮度粗判（[typeFgOn]）。
  static Color foregroundOf(BuildContext context, String identifier) {
    final explicit = AppColors.typeForeground[identifier];
    if (explicit != null) {
      return explicit;
    }
    return typeFgOn(backgroundOf(context, identifier));
  }

  @override
  Widget build(BuildContext context) {
    final fg = foregroundOf(context, type);
    return Material(
      color: backgroundOf(context, type),
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: size.height,
          padding: EdgeInsets.symmetric(horizontal: size.paddingH),
          alignment: Alignment.center,
          child: Text(
            label ?? kTypeNamesZh[type] ?? type,
            maxLines: 1,
            style: TextStyle(
              fontSize: size.fontSize,
              height: 1.1,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
