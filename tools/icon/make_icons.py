# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.0", "numpy>=1.24"]
# ///
"""Fl-PokeDex 应用图标生成器：docs/icon/raw.png → assets/icon 三件套与预览。

白底-前景混合模型抠底（raw.png 为不透明白底源图，背景白逐次实测）：

    C = F·α + W·(1−α)

逐像素反解透明度 α，并还原去污染前景色 F = W + (C−W)/α：圆角方块与
精灵球边缘的抗锯齿半透明像素得以保留，白底抠图残留的白色半透明
像素（白圈）被除净。所有缩放均在预乘 alpha 域做 LANCZOS，避免
透明边缘出现颜色光晕。

自适应前景为书封中央精灵球（raw.png 中无钻石；沿用旧版前景 44% 画布
宽、居中的布局参数），采用解析圆掩码给出 α、仅边缘环带按上式对书封
米底还原 F，天然不含投影与米底残留。

用法:
    uv run tools/icon/make_icons.py

产物:
    assets/icon/app_icon_1024.png    完整 tile（圆角方块）裁紧 bbox 后贴满 1024 画布（RGBA）
    assets/icon/app_icon_fg_1024.png 自适应前景：仅精灵球，约 44% 画布宽、居中
    assets/icon/app_icon_bg_1024.png 自适应背景：纯色 #262115（与 pubspec 配置一致）
    .cache/icon_preview_dark.png     tile 深底(#262115) 256px 预览
    .cache/icon_preview_white.png    tile 纯白底 256px 预览
    .cache/icon_fg_preview_dark.png  精灵球前景深底 256px 诊断预览

自检（不达标即非零退出）:
    预览源 tile（256px 与所存 1024px）上「圆角方块边缘 2px 环带内
    近白(min RGB≥240) 且 alpha>10」的像素数必须为 0。

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
BG_COLOR = (0x26, 0x21, 0x15)
FG_BALL_WIDTH = 450  # 前景精灵球目标宽度 ≈ 44% 画布（旧版钻石 447px 布局参考）

# 精灵球提取参数
BALL_ROI = (300, 260, 900, 920)  # raw 坐标 (x0, y0, x1, y1)，须含整球、远离书签/徽章

# 自检参数：边缘环带宽 2px；近白 = min(R,G,B) ≥ 240；计入条件 alpha > 10
BAND_PX = 2
NEAR_WHITE_MIN = 240
ALPHA_MIN = 10


def border_white(raw: Image.Image) -> tuple[float, float, float]:
    """实测源图背景白：四周边框 6px 的逐通道中位数。"""
    a = np.asarray(raw.convert("RGB"), dtype=np.float64)
    border = np.concatenate(
        [
            a[:6].reshape(-1, 3),
            a[-6:].reshape(-1, 3),
            a[:, :6].reshape(-1, 3),
            a[:, -6:].reshape(-1, 3),
        ]
    )
    return np.median(border, axis=0)


def resize_premultiplied(img: Image.Image, size: int) -> Image.Image:
    """预乘 alpha 域 LANCZOS 缩放，返回 RGBA。"""
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


def _box_blur1(plane: np.ndarray) -> np.ndarray:
    """3×3 盒滤波（边缘复制填充），Pillow 的 BoxBlur 不支持 F 模式故自行实现。"""
    h, w = plane.shape
    p = np.pad(plane, 1, mode="edge")
    s = np.zeros_like(plane)
    for dy in range(3):
        for dx in range(3):
            s += p[dy : dy + h, dx : dx + w]
    return s / 9.0


def _flood(seed: np.ndarray, wall: np.ndarray, max_iter: int) -> np.ndarray:
    """4 邻域洪泛：从 seed 在 wall 内扩散。"""
    reach = seed & wall
    for _ in range(max_iter):
        grown = reach.copy()
        grown[1:, :] |= reach[:-1, :]
        grown[:-1, :] |= reach[1:, :]
        grown[:, 1:] |= reach[:, :-1]
        grown[:, :-1] |= reach[:, 1:]
        grown &= wall
        if (grown == reach).all():
            break
        reach = grown
    return reach


def _fill_nearest_interior(rgb: np.ndarray, interior: np.ndarray, steps: int = 6) -> np.ndarray:
    """将 interior 的颜色逐层外扩（3×3 均值），逼近每个像素的最近内部色。"""
    filled = rgb * interior[..., None]
    weight = interior.astype(np.float64)
    for _ in range(steps):
        f_blur = np.stack([_box_blur1(filled[..., c]) for c in range(3)], axis=-1)
        w_blur = _box_blur1(weight)
        fresh = (weight == 0) & (w_blur > 1e-6)
        filled[fresh] = f_blur[fresh] / w_blur[fresh, None]
        weight[fresh] = 1.0
    return filled


def unblend_from_white(raw: Image.Image) -> Image.Image:
    """整图白底抠底：tile 边缘反解 α 并去污染前景色，确信内部保持原色。

    tile 主体用「背景洪泛不可达连通域」判定（与颜色无关，内部奶白封面、
    书页等浅色区不会被误当背景抠穿），仅最外圈边界带按混合模型反解。
    """
    c = np.asarray(raw.convert("RGB"), dtype=np.float64)
    h, w = c.shape[:2]
    w0 = border_white(raw)

    # α 初判：暗端参考色取深色像素的 1% 分位；tileish 阈值须低于最浅内容像素
    dist_from_white = 255.0 - c.min(axis=2)
    f_ref = np.percentile(c[dist_from_white > 60], 1, axis=0)
    a0 = np.clip(((w0 - c) / np.maximum(w0 - f_ref, 8.0)).max(axis=2), 0.0, 1.0)
    tileish = a0 > 0.07

    border = np.zeros_like(tileish)
    border[0, :] = border[-1, :] = border[:, 0] = border[:, -1] = True
    bg = _flood(border & ~tileish, ~tileish, max(h, w))
    region = ~bg  # tile 全体（已填掉内部浅色"洞"）

    region_img = Image.fromarray(region.astype(np.uint8) * 255, mode="L")
    interior = np.asarray(region_img.filter(ImageFilter.MinFilter(7)), dtype=np.uint8) > 127
    ring = (
        np.asarray(region_img.filter(ImageFilter.MaxFilter(5)), dtype=np.uint8) > 127
    ) & ~interior & (a0 > 0.015)

    f_near = _fill_nearest_interior(c, interior)[ring]
    fw = f_near - w0
    cw = c[ring] - w0
    alpha = np.clip(
        (fw * cw).sum(axis=1) / np.maximum((fw * fw).sum(axis=1), 1e-6), 0.0, 1.0
    )

    out = np.zeros((h, w, 4), dtype=np.float64)
    out[..., :3][interior] = c[interior]
    out[..., 3][interior] = 255.0
    keep = alpha >= 0.02
    flat = out.reshape(-1, 4)
    idx = np.flatnonzero(ring.reshape(-1))[keep]
    a_ring = alpha[keep]
    # 去污染前景：F = W + (C−W)/α，白 fringe 由此除净
    flat[idx, :3] = np.clip(
        w0 + (c.reshape(-1, 3)[idx] - w0) / a_ring[:, None], 0.0, 255.0
    )
    flat[idx, 3] = np.round(a_ring * 255.0)
    return Image.fromarray(np.round(out).astype(np.uint8), mode="RGBA")


def crop_alpha_bbox(img: Image.Image) -> Image.Image:
    a = np.asarray(img)[..., 3]
    ys = np.flatnonzero((a > 0).any(axis=1))
    xs = np.flatnonzero((a > 0).any(axis=0))
    return img.crop((int(xs[0]), int(ys[0]), int(xs[-1]) + 1, int(ys[-1]) + 1))


def _cover_color(c: np.ndarray) -> np.ndarray:
    """实测书封米底：球顶上方带状区 + 球右侧窄条（均为纯封面区域）的中位数。"""
    x0, y0, x1, _ = BALL_ROI
    top = c[y0 : y0 + 40, x0 + 50 : x1 - 50].reshape(-1, 3)
    right = c[430:530, 868:893].reshape(-1, 3)
    return np.median(np.concatenate([top, right]), axis=0)


def _ball_mask(c: np.ndarray, b0: np.ndarray) -> np.ndarray:
    """精灵球掩码：与书封米底色距 >15 的像素（白下半球/反光全部入掩码，米底排除）。

    ROI 内自中心洪泛取连通域；书签、徽章、取景框角等均为独立色块不会并入。
    贴球阴影色距亦 >15 会并入，但圆拟合只取上半弧与两侧极值点，不受影响。
    """
    x0, y0, x1, y1 = BALL_ROI
    roi = c[y0:y1, x0:x1]
    mask = np.sqrt(((roi - b0) ** 2).sum(axis=2)) > 15.0

    h, w = mask.shape
    cy, cx = h // 2, w // 2  # ROI 中心落在球体按钮附近，必在掩码内
    win = mask[cy - 90 : cy + 90, cx - 90 : cx + 90]
    wy, wx = np.nonzero(win)
    assert wy.size > 0, "ROI 中心附近无特征像素，BALL_ROI 需复核"
    d2 = (wy - 90) ** 2 + (wx - 90) ** 2
    seed = np.zeros_like(mask)
    seed[cy - 90 + wy[d2.argmin()], cx - 90 + wx[d2.argmin()]] = True
    return _flood(seed, mask, max(h, w))


def _dilate4(m: np.ndarray) -> np.ndarray:
    d = m.copy()
    d[1:, :] |= m[:-1, :]
    d[:-1, :] |= m[1:, :]
    d[:, 1:] |= m[:, :-1]
    d[:, :-1] |= m[:, 1:]
    return d


def fit_ball_circle(c: np.ndarray, b0: np.ndarray) -> tuple[float, float, float]:
    """拟合精灵球外轮廓圆：掩码逐行左右极值点（天然只落在外轮廓上）→ Kasa 拟合。"""
    x0, y0, _, _ = BALL_ROI
    comp = _ball_mask(c, b0)

    rows = np.flatnonzero(comp.any(axis=1))
    pts = []
    for y in rows:
        xs = np.flatnonzero(comp[y])
        pts.append((x0 + xs[0], y0 + y))
        pts.append((x0 + xs[-1], y0 + y))
    pts = np.asarray(pts, dtype=np.float64)

    y_top = pts[:, 1].min()
    r0 = (pts[:, 0].max() - pts[:, 0].min()) / 2
    cx0 = (pts[:, 0].max() + pts[:, 0].min()) / 2
    cy0 = y_top + r0
    px = py = np.empty(0)
    for _ in range(3):
        # 只取上半弧与两侧极值柱（y < cy+0.45r），剔除贴球阴影行；迭代剔离群点
        keep = (pts[:, 1] < cy0 + 0.45 * r0) & (
            (pts[:, 1] < cy0 + 0.3 * r0) | (np.abs(pts[:, 0] - cx0) > 0.9 * r0)
        )
        px, py = pts[keep, 0], pts[keep, 1]
        m = np.stack([px, py, np.ones_like(px)], axis=1)
        sol, *_ = np.linalg.lstsq(m, -(px * px + py * py), rcond=None)
        cx0, cy0 = -sol[0] / 2, -sol[1] / 2
        r0 = float(np.sqrt(cx0 * cx0 + cy0 * cy0 - sol[2]))
        rad = np.hypot(px - cx0, py - cy0)
        inlier = np.abs(rad - r0) < 2.0
        if inlier.all():
            break
        px, py = px[inlier], py[inlier]

    resid = np.abs(np.hypot(px - cx0, py - cy0) - r0)
    print(
        f"  精灵球圆拟合: center=({cx0:.1f},{cy0:.1f}) r={r0:.2f}px "
        f"残差 p50={np.percentile(resid, 50):.2f}px max={resid.max():.2f}px (n={px.size})"
    )
    assert px.size >= 60 and resid.max() < 2.5 and resid.std() < 1.0, (
        "圆拟合残差过大：外轮廓非圆或掩码混入杂点，需人工复核"
    )
    return cx0, cy0, r0


def build_ball_fg(raw: Image.Image) -> Image.Image:
    """抠出精灵球并居中贴到 1024 画布：解析圆掩码给 α，环带按米底混合模型还原 F。"""
    c = np.asarray(raw.convert("RGB"), dtype=np.float64)
    b0 = _cover_color(c)
    print(f"  书封米底实测: {b0}")
    cx, cy, r = fit_ball_circle(c, b0)

    side = int(2 * r) + 8
    bx, by = int(cx - side / 2), int(cy - side / 2)
    crop = c[by : by + side, bx : bx + side]
    yy, xx = np.mgrid[by : by + side, bx : bx + side].astype(np.float64)
    sub = (np.arange(4) + 0.5) / 4 - 0.5
    cov = np.zeros((side, side))
    for dy in sub:
        for dx in sub:
            cov += (np.hypot(xx + dx - cx, yy + dy - cy) <= r) / sub.size

    # 边缘带 α = min(圆覆盖度, 米底色距软阈值)： artwork 轮廓有 ±2px 手绘抖动，
    # 软阈值连续剔除圆内混入的米底/圆外贴球阴影，覆盖度提供抗锯齿渐变
    edge_zone = np.hypot(xx - cx, yy - cy) > r - 6
    soft = np.clip((np.sqrt(((crop - b0) ** 2).sum(axis=2)) - 9.0) / 9.0, 0.0, 1.0)
    cov = np.where(edge_zone, np.minimum(cov, soft), cov)

    ring = (cov > 0.015) & (cov < 0.985)
    a_ring = cov[ring][:, None]
    f_ring = np.clip(b0 + (crop[ring] - b0) / a_ring, 0.0, 255.0)  # 去米底污染

    out = np.zeros((side, side, 4), dtype=np.float64)
    solid = cov >= 0.985
    out[..., :3][solid] = crop[solid]
    out[..., 3][solid] = 255.0
    out[..., :3][ring] = f_ring
    out[..., 3][ring] = np.round(cov[ring] * 255.0)
    ball = Image.fromarray(np.round(out).astype(np.uint8), mode="RGBA")

    fg = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    ball_scaled = resize_premultiplied(ball, FG_BALL_WIDTH)
    off = (CANVAS - FG_BALL_WIDTH) // 2
    fg.paste(ball_scaled, (off, off), ball_scaled)
    print(f"  精灵球原生直径 {2 * r:.0f}px → 前景 {FG_BALL_WIDTH}px @({CANVAS // 2},{CANVAS // 2})")
    return fg


def edge_band_white_count(img: Image.Image) -> tuple[int, int]:
    """「边缘 2px 环带」内近白且 alpha>10 的像素数，返回 (违规数, 环带总数)。"""
    a = np.asarray(img.convert("RGBA"), dtype=np.uint8)
    mask = (a[..., 3] > ALPHA_MIN).astype(np.uint8) * 255
    eroded = np.asarray(Image.fromarray(mask, mode="L").filter(ImageFilter.MinFilter(3)), dtype=np.uint8)
    for _ in range(BAND_PX - 1):
        eroded = np.asarray(Image.fromarray(eroded, mode="L").filter(ImageFilter.MinFilter(3)), dtype=np.uint8)
    band = (a[..., 3] > ALPHA_MIN) & (eroded == 0)
    near_white = a[..., :3].min(axis=2) >= NEAR_WHITE_MIN
    return int((band & near_white).sum()), int(band.sum())


def composite(img: Image.Image, bg: tuple[int, int, int], size: int) -> Image.Image:
    tile = resize_premultiplied(img, size)
    base = Image.new("RGBA", (size, size), bg + (255,))
    base.paste(tile, (0, 0), tile)
    return base.convert("RGB")


def main() -> None:
    raw = Image.open(RAW)
    assert raw.size == (1254, 1254), f"源图尺寸异常: {raw.size}"
    print(f"源图: {RAW.relative_to(ROOT)} {raw.size} 背景白={border_white(raw)}")

    tile_native = crop_alpha_bbox(unblend_from_white(raw))
    print(f"tile 原生内容 bbox: {tile_native.size}")

    fg = build_ball_fg(raw)

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    tile_1024 = resize_premultiplied(tile_native, CANVAS)
    bg = Image.new("RGBA", (CANVAS, CANVAS), BG_COLOR + (255,))
    tile_1024.save(OUT_DIR / "app_icon_1024.png")
    fg.save(OUT_DIR / "app_icon_fg_1024.png")
    bg.save(OUT_DIR / "app_icon_bg_1024.png")

    CACHE.mkdir(parents=True, exist_ok=True)
    composite(tile_native, BG_COLOR, PREVIEW).save(CACHE / "icon_preview_dark.png")
    composite(tile_native, (255, 255, 255), PREVIEW).save(CACHE / "icon_preview_white.png")
    fg_base = Image.new("RGBA", (PREVIEW, PREVIEW), BG_COLOR + (255,))
    fg_small = resize_premultiplied(fg, PREVIEW)
    fg_base.paste(fg_small, (0, 0), fg_small)
    fg_base.convert("RGB").save(CACHE / "icon_fg_preview_dark.png")

    bad, band = edge_band_white_count(resize_premultiplied(tile_native, PREVIEW))
    bad_1024, band_1024 = edge_band_white_count(tile_1024)
    print(
        f"自检(tile): 边缘 {BAND_PX}px 环带(256px 共 {band}px) 近白且 alpha>{ALPHA_MIN} = {bad}；"
        f"1024px 环带 {band_1024}px 同判 = {bad_1024}"
    )
    if bad > 0 or bad_1024 > 0:
        print("自检未达标：白圈残留，需迭代抠底算法")
        sys.exit(1)
    print("自检通过 → assets/icon/{app_icon_1024,app_icon_fg_1024,app_icon_bg_1024}.png + .cache 预览 ×3")


if __name__ == "__main__":
    main()
