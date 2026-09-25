/// 窗口宽度 → 尺寸档位（architecture.md §2 契约）。
///
/// 断点数值唯一来源：DESIGN.md §3。
/// 本文件是这些数值在代码里的唯一落点，UI 代码一律通过
/// [windowSizeFor] / [twoPaneFor] 取档，禁止散落硬编码断点。
enum WindowSize { compact, medium, expanded }

/// `<600 compact，<840 medium，else expanded`
WindowSize windowSizeFor(double width) {
  if (width < 600) {
    return WindowSize.compact;
  }
  if (width < 840) {
    return WindowSize.medium;
  }
  return WindowSize.expanded;
}

/// `>=1080 → 图鉴分支启用 master-detail 双栏`
bool twoPaneFor(double width) => width >= 1080;
