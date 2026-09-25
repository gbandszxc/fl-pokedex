# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests", "pillow"]
# ///
"""下载 official-artwork 并加工为 assets/pokemon/{full,thumb}/*.webp（契约 §7）。

- full：最长边 400px，WebP q76，全部形态
- thumb：最长边 192px，WebP q72，仅 is_default 形态
- variety 图缺失时回退该 species 默认形态 id；仍 404 记入 manifest.missingArtwork
- 1025 只默认形态缺图 ≥10 则构建失败
- 同时回填 forms.artwork_asset / thumb_asset 与 meta.missing_artwork

用法：export PYTHONUTF8=1 && uv run tools/data_builder/process_images.py
"""

from __future__ import annotations

import io
import json
import sqlite3
import sys
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import requests
from PIL import Image

import config as cfg

MAX_WORKERS = 12          # 契约要求并发 ≥8
RETRIES = 4
TIMEOUT = 45
FULL_SIZE, FULL_QUALITY = 400, 76
THUMB_SIZE, THUMB_QUALITY = 192, 72
DEFAULT_MISSING_LIMIT = 10

_local = threading.local()
_print_lock = threading.Lock()


def _session() -> requests.Session:
    if not hasattr(_local, "session"):
        s = requests.Session()
        s.headers["User-Agent"] = "amberdex-data-builder/1.0"
        _local.session = s
    return _local.session


def download_png(image_id: int, force: bool) -> Path | None:
    """下载 {image_id}.png 到 .cache/sprites（raw 失败走 jsdelivr），404 返回 None。"""
    dest = cfg.CACHE_SPRITES_DIR / f"{image_id}.png"
    if dest.exists() and dest.stat().st_size > 0 and not force:
        return dest
    urls = (cfg.sprites_raw_url(cfg.SPRITES_SHA, image_id),
            cfg.sprites_jsdelivr_url(cfg.SPRITES_SHA, image_id))
    for url in urls:
        for attempt in range(1, RETRIES + 1):
            try:
                resp = _session().get(url, timeout=TIMEOUT)
            except requests.RequestException:
                time.sleep(min(2 ** attempt, 8))
                continue
            if resp.status_code == 200 and resp.content:
                dest.write_bytes(resp.content)
                return dest
            if resp.status_code == 404:
                break  # 换下一个源
            time.sleep(min(2 ** attempt, 8))  # 429/5xx 退避重试
    return None


def resize_to(img: Image.Image, max_side: int) -> Image.Image:
    """RGBA、最长边压到 max_side（只缩不放，官方图基本为 475px 见方）。"""
    img = img.convert("RGBA")
    w, h = img.size
    side = max(w, h)
    if side > max_side:
        scale = max_side / side
        img = img.resize((max(1, round(w * scale)), max(1, round(h * scale))), Image.LANCZOS)
    return img


def process_form(form_id: int, species_id: int, is_default: int, force: bool) -> dict:
    """单个形态：解析图片源 id（variety → species 默认形态回退），产出 full/thumb。"""
    src = download_png(form_id, force) or download_png(species_id, force)
    if src is None:
        return {"form_id": form_id, "is_default": bool(is_default), "missing": True}

    img = Image.open(io.BytesIO(src.read_bytes()))
    full_path = cfg.ASSETS_FULL_DIR / f"{form_id}.webp"
    resize_to(img, FULL_SIZE).save(full_path, "WEBP", quality=FULL_QUALITY, method=4)
    thumb_path = None
    if is_default:
        thumb_path = cfg.ASSETS_THUMB_DIR / f"{form_id}.webp"
        resize_to(img, THUMB_SIZE).save(thumb_path, "WEBP", quality=THUMB_QUALITY, method=4)
    return {
        "form_id": form_id, "is_default": bool(is_default), "missing": False,
        "full": full_path, "thumb": thumb_path, "bytes": full_path.stat().st_size
        + (thumb_path.stat().st_size if thumb_path else 0),
    }


def main(argv: list[str] | None = None) -> int:
    force = "--force" in (argv or sys.argv[1:])
    cfg.assert_utf8_env()
    cfg.ensure_dirs()
    t0 = time.time()

    conn = sqlite3.connect(cfg.DB_PATH)
    try:
        forms = conn.execute(
            "SELECT id, species_id, is_default FROM forms ORDER BY id").fetchall()
        print(f"[images] 待处理形态 {len(forms)} 个（sprites@{cfg.SPRITES_SHA[:12]}）")

        results = []
        done = 0
        with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
            futures = [pool.submit(process_form, fid, sid, dflt, force)
                       for fid, sid, dflt in forms]
            for fut in as_completed(futures):
                results.append(fut.result())
                done += 1
                if done % 200 == 0:
                    with _print_lock:
                        print(f"  ... {done}/{len(forms)}")

        missing = sorted(r["form_id"] for r in results if r["missing"])
        total_bytes = sum(r.get("bytes", 0) for r in results)

        # 回填 forms.artwork_asset / thumb_asset（正向斜杠，契约 §3）
        updates = []
        for r in results:
            if r["missing"]:
                updates.append((None, None, r["form_id"]))
            else:
                thumb = (f"assets/pokemon/thumb/{r['form_id']}.webp"
                         if r.get("thumb") else None)
                updates.append((f"assets/pokemon/full/{r['form_id']}.webp",
                                thumb, r["form_id"]))
        conn.executemany("UPDATE forms SET artwork_asset = ?, thumb_asset = ? WHERE id = ?",
                         updates)
        conn.execute(
            "INSERT INTO meta(key, value) VALUES ('missing_artwork', ?) "
            "ON CONFLICT(key) DO UPDATE SET value = excluded.value",
            (json.dumps(missing),))
        conn.commit()

        # 刷新 manifest.missingArtwork（其余字段不动）
        manifest = json.loads(cfg.MANIFEST_PATH.read_text(encoding="utf-8"))
        manifest["missingArtwork"] = missing
        cfg.MANIFEST_PATH.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

        default_missing = conn.execute(
            "SELECT COUNT(*) FROM forms WHERE is_default = 1 AND artwork_asset IS NULL"
        ).fetchone()[0]
    finally:
        conn.close()

    full_count = len(list(cfg.ASSETS_FULL_DIR.glob("*.webp")))
    thumb_count = len(list(cfg.ASSETS_THUMB_DIR.glob("*.webp")))
    print(f"[images] full={full_count} thumb={thumb_count} "
          f"总体积 {total_bytes / 1024 / 1024:.1f} MB，耗时 {time.time() - t0:.0f}s")
    print(f"[images] 缺图形态 {len(missing)} 个: {missing[:20]}{'...' if len(missing) > 20 else ''}")
    if default_missing >= DEFAULT_MISSING_LIMIT:
        print(f"[images][error] 默认形态缺图 {default_missing} ≥ {DEFAULT_MISSING_LIMIT}，构建失败")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
