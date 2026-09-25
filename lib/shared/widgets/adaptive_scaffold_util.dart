import 'package:flutter/material.dart';

import 'package:fl_pokedex/app/theme/tokens.dart';
import 'package:fl_pokedex/shared/responsive/breakpoints.dart';

/// 页面水平留白（DESIGN.md §3）：compact=16 / medium=16 / expanded=24。
double pagePaddingFor(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return switch (windowSizeFor(width)) {
    WindowSize.compact || WindowSize.medium => AppSpacing.l,
    WindowSize.expanded => AppPagePadding.expanded,
  };
}
