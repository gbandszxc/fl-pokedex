# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.0", "numpy>=1.24"]
# ///
"""Fl-PokeDex 应用图标生成器：docs/icon/raw.png → assets/icon 三件套与预览。

源图 raw.png 为 1254×1254 带 alpha 通道的圆角矩形瓦片（瓦片外全透明、
边缘无白边），无需抠底，流程：

    1. 主图   按 alpha>ALPHA_BBOX 求内容 bbox → 裁除四周透明边距 →
              预乘 alpha 域 LANCZOS 拉伸到恰好 1024×1024（内容宽高比
              偏差 ~2.6% < 3%，直接拉伸视觉不可察），四面顶边、四角
              保留瓦片自身圆角透明；
    2. 自适应前景 launcher 遮罩只保证中心约 61% 圆形安全区可见，且
              flutter_launcher_icons 不做缩放，故自行把完整瓦片缩到
              FG_TILE_RATIO(60%) 画布宽、居中、透明补边，瓦片边中点
              恰落在安全区圆内；
    3. 背景   纯色 = 瓦片边缘主色（bbox 内缩 2px 环带不透明像素的
              中位色），须与 pubspec 的 adaptive_icon_background 一致。

所有缩放均在预乘 alpha 域做 LANCZOS，透明边缘不产生颜色光晕。

用法:
    export PYTHONUTF8=1; uv run tools/icon/make_icons.py

产物:
    assets/icon/app_icon_1024.png    完整瓦片裁紧 bbox 后贴满 1024 画布（RGBA）
    assets/icon/app_icon_fg_1024.png 自适应前景：完整瓦片 60% 画布宽、居中
    assets/icon/app_icon_bg_1024.png 自适应背景：纯色（实测边缘主色）
    .cache/icon_preview_dark.png     主图纯黑底 256px 预览
    .cache/icon_preview_white.png    主图纯白底 256px 预览
    .cache/icon_mask_preview.png     自适应圆形遮罩模拟（中心 61% 圆外涂灰）

自检（不达标即非零退出）:
    1. 主图内容 bbox 覆盖整幅画布（四边中点处存在 alpha>ALPHA_BBOX 像素）；
    2. 主图边缘 2px 环带内近白(min RGB≥240) 且 alpha>10 的像素数为 0；
    3. 自适应前景非透明内容完全落在中心 66% 方形内。

生成平台图标请在跑通本脚本后执行: dart run flutter_launcher_icons
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
RAW = ROOT / "docs" / "icon" / "raw.png"
OUT_DIR = ROOT / "assets" / "icon"
CACHE = ROOT / ".cache"

CANVAS = 1024
PREVIEW = 256

ALPHA_BBOX = 8  # 内容 bbox 判定阈值：alpha > 8 视为内容
FG_TILE_RATIO = 0.60  # 自适应前景：瓦片占画布宽度比例（边中点恰入 61% 安全区圆）
SAFE_ZONE_RATIO = 0.61  # launcher 保证可见的中心圆直径比例（66dp/108dp）
CONTAIN_RATIO = 0.66  # 自检：前景内容须完全落在中心 66% 方形内
MASK_PREVIEW_RATIO = 0.61  # 遮罩模拟图：可见圆直径比例

# 自检参数：边缘环带宽 2px；近白 = min(R,G,B) ≥ 240；计入条件 alpha > 10
BAND_PX = 2
NEAR_WHITE_MIN = 240
ALPHA_MIN = 10


def content_bbox(img: Image.Image) -> tuple[int, int, int, int]:
    """alpha > ALPHA_BBOX 的内容 bbox，返回 (x0, y0, x1_excl, y1_excl)。"""
    a = np.asarray(img.convert("RGBA"))[..., 3]
    mask = a > ALPHA_BBOX
    ys = np.flatnonzero(mask.any(axis=1))
    xs = np.flatnonzero(mask.any(axis=0))
    assert ys.size and xs.size, "源图无内容（alpha 全低于阈值）"
    return int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1


def edge_color(tile: Image.Image) -> tuple[int, int, int]:
    """瓦片边缘主色：bbox 内缩 2px 环带中不透明(alpha>128)像素的逐通道中位数。"""
    a = np.asarray(tile.convert("RGBA"), dtype=np.uint8)
    h, w = a.shape[:2]
    ring = np.ones((h, w), dtype=bool)
    ring[BAND_PX : h - BAND_PX, BAND_PX : w - BAND_PX] = False
    ring &= a[..., 3] > 128
    assert ring.sum() > 100, "边缘环带不透明像素过少，源图非预期布局"
    med = np.median(a[..., :3][ring], axis=0)
    return tuple(int(round(v)) for v in med)


def resize_premultiplied(img: Image.Image, size: int) -> Image.Image:
    """预乘 alpha 域 LANCZOS 缩放到 size×size，返回 RGBA。"""
    a = np.asarray(img, dtype=np.float64)
    prem = a[..., :3] * (a[..., 3:] / 255.0)
    planes = [prem[..., i] for i in range(3)] + [a[..., 3]]
    resized = [
        np.asarray(
            Image.fromarray(p.astype(np.float32), mode="F").resize(
                (size, size), Image.LANCZOS
            ),
            dtype=np.float64,
        )
        for p in planes
    ]
    prem_r = np.stack(resized[:3], axis=-1)
    a_r = np.clip(resized[3], 0.0, 255.0)
    scale = np.maximum(a_r, 1e-4) / 255.0
    rgb = np.clip(prem_r / scale[..., None], 0.0, 255.0)
    out = np.concatenate([rgb, a_r[..., None]], axis=-1)
    return Image.fromarray(np.round(out).astype(np.uint8), mode="RGBA")


def edge_band_white_count(img: Image.Image) -> tuple[int, int]:
    """「边缘 2px 环带」内近白且 alpha>10 的像素数，返回 (违规数, 环带总数)。"""
    a = np.asarray(img.convert("RGBA"), dtype=np.uint8)
    mask = (a[..., 3] > ALPHA_MIN).astype(np.uint8) * 255
    eroded = np.asarray(
        Image.fromarray(mask, mode="L").filter(ImageFilter.MinFilter(3)), dtype=np.uint8
    )
    for _ in range(BAND_PX - 1):
        eroded = np.asarray(
            Image.fromarray(eroded, mode="L").filter(ImageFilter.MinFilter(3)),
            dtype=np.uint8,
        )
    band = (a[..., 3] > ALPHA_MIN) & (eroded == 0)
    near_white = a[..., :3].min(axis=2) >= NEAR_WHITE_MIN
    return int((band & near_white).sum()), int(band.sum())


def composite(img: Image.Image, bg: tuple[int, int, int], size: int) -> Image.Image:
    tile = resize_premultiplied(img, size)
    base = Image.new("RGBA", (size, size), bg + (255,))
    base.paste(tile, (0, 0), tile)
    return base.convert("RGB")


def build_fg(tile: Image.Image) -> Image.Image:
    """完整瓦片缩至 FG_TILE_RATIO 画布宽，居中贴到透明画布（自适应前景）。"""
    width = round(CANVAS * FG_TILE_RATIO)
    fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    scaled = resize_premultiplied(tile, width)
    off = (CANVAS - width) // 2
    fg.paste(scaled, (off, off), scaled)
    print(f"  自适应前景: 瓦片 {width}px（{FG_TILE_RATIO:.0%} 画布宽）@({off},{off})")
    return fg


def mask_preview(fg: Image.Image, bg: tuple[int, int, int], size: int) -> Image.Image:
    """圆形遮罩模拟：中心 SAFE_ZONE_RATIO 圆内为可见区（前景贴 bg），圆外涂灰。"""
    arr = np.asarray(composite(fg, bg, size)).copy()
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    r = size * MASK_PREVIEW_RATIO / 2
    c = size / 2 - 0.5
    outside = (xx - c) ** 2 + (yy - c) ** 2 > r * r
    arr[outside] = (127, 127, 127)
    return Image.fromarray(arr)


def check_main(tile_1024: Image.Image) -> None:
    """自检 1+2：主图四面顶边、边缘无白边。"""
    a = np.asarray(tile_1024.convert("RGBA"))[..., 3]
    bbox = content_bbox(tile_1024)
    assert bbox == (0, 0, CANVAS, CANVAS), f"主图未顶满画布: bbox={bbox}"

    h, w = a.shape
    win = slice(w // 2 - 2, w // 2 + 2)  # 各边中点 ±2px 窗口
    touched = {
        "上": bool((a[0:2, win] > ALPHA_BBOX).any()),
        "下": bool((a[h - 2 : h, win] > ALPHA_BBOX).any()),
        "左": bool((a[win, 0:2] > ALPHA_BBOX).any()),
        "右": bool((a[win, w - 2 : w] > ALPHA_BBOX).any()),
    }
    assert all(touched.values()), f"主图四边中点未覆盖: {touched}"

    bad_1024, band_1024 = edge_band_white_count(tile_1024)
    bad_prev, band_prev = edge_band_white_count(resize_premultiplied(tile_1024, PREVIEW))
    print(
        f"  自检(主图): 四边中点覆盖={touched}；边缘 {BAND_PX}px 环带近白且 alpha>{ALPHA_MIN}"
        f"：1024px={bad_1024}/{band_1024}，256px={bad_prev}/{band_prev}"
    )
    assert bad_1024 == 0 and bad_prev == 0, "主图边缘存在白边残留"


def check_fg(fg: Image.Image) -> None:
    """自检 3：前景内容完全落在中心 66% 方形内。"""
    a = np.asarray(fg.convert("RGBA"))[..., 3]
    ys = np.flatnonzero((a > ALPHA_BBOX).any(axis=1))
    xs = np.flatnonzero((a > ALPHA_BBOX).any(axis=0))
    margin = int(CANVAS * (1 - CONTAIN_RATIO) / 2)
    lo, hi = margin, CANVAS - margin
    box = (int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1)
    print(f"  自检(前景): 内容 bbox={box}，须落在中心 {CONTAIN_RATIO:.0%} 方形 [{lo},{hi})")
    assert xs[0] >= lo and ys[0] >= lo and xs[-1] < hi and ys[-1] < hi, (
        f"前景内容超出中心 {CONTAIN_RATIO:.0%} 方形: bbox={box}"
    )

    # 诊断（非门禁）：内容最远点距中心 vs 61%/66.7% 遮罩圆半径
    yy, xx = np.nonzero(a > ALPHA_BBOX)
    r_max = float(np.hypot(xx - CANVAS / 2, yy - CANVAS / 2).max())
    r_safe = CANVAS * SAFE_ZONE_RATIO / 2
    print(
        f"  诊断: 前景内容最远距中心 {r_max:.0f}px（61% 安全区圆半径 {r_safe:.0f}px，"
        f"66.7% 圆 {CANVAS * 2 / 3 / 2:.0f}px）；圆角超出安全区属预期，直边中点均可见"
    )


def main() -> None:
    raw = Image.open(RAW)
    assert raw.mode == "RGBA" and raw.size == (1254, 1254), (
        f"源图异常: mode={raw.mode} size={raw.size}"
    )
    bbox = content_bbox(raw)
    tile = raw.crop(bbox)
    print(f"源图: {RAW.relative_to(ROOT)} {raw.size}，内容 bbox={bbox}，裁后 {tile.size}")

    bg_color = edge_color(tile)
    hex_color = "#%02X%02X%02X" % bg_color
    print(f"瓦片边缘主色: {hex_color}（须与 pubspec adaptive_icon_background 一致）")

    tile_1024 = resize_premultiplied(tile, CANVAS)
    fg = build_fg(tile)
    bg = Image.new("RGBA", (CANVAS, CANVAS), bg_color + (255,))

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tile_1024.save(OUT_DIR / "app_icon_1024.png")
    fg.save(OUT_DIR / "app_icon_fg_1024.png")
    bg.save(OUT_DIR / "app_icon_bg_1024.png")

    CACHE.mkdir(parents=True, exist_ok=True)
    composite(tile_1024, (0, 0, 0), PREVIEW).save(CACHE / "icon_preview_dark.png")
    composite(tile_1024, (255, 255, 255), PREVIEW).save(CACHE / "icon_preview_white.png")
    mask_preview(fg, bg_color, PREVIEW).save(CACHE / "icon_mask_preview.png")

    check_main(tile_1024)
    check_fg(fg)
    print("自检通过 → assets/icon/{app_icon_1024,app_icon_fg_1024,app_icon_bg_1024}.png + .cache 预览 ×3")


if __name__ == "__main__":
    main()
