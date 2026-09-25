# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests", "pillow"]
# ///
"""数据构建总编排：fetch → build_db → process_images → verify，最后输出产物汇总。

用法：
    export PYTHONUTF8=1
    uv run tools/data_builder/build_all.py             # 增量（.cache 已有数据则跳过下载）
    uv run tools/data_builder/build_all.py --force     # 强制重新下载 CSV 与图片
    uv run tools/data_builder/build_all.py --latest    # 刷新上游 sha 后全量构建
任一步骤失败即中止，退出码非 0。
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

import config as cfg

sys.path.insert(0, str(cfg.TOOLS_DATA_BUILDER_DIR))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="琥珀图鉴数据构建编排")
    parser.add_argument("--force", action="store_true", help="忽略缓存，强制重新下载")
    parser.add_argument("--latest", action="store_true", help="获取上游 master 最新 sha 并构建")
    parser.add_argument("--skip-images", action="store_true", help="跳过图片处理（调试用）")
    args = parser.parse_args(argv)

    cfg.assert_utf8_env()
    started = datetime.now(timezone.utc)

    import fetch_data
    import build_db
    import process_images
    import verify

    fetch_extra = []
    if args.latest:
        fetch_extra.append("--latest")  # fetch_data 会回写 config.py 并强制重新下载
    elif args.force:
        fetch_extra.append("--force")

    steps: list[tuple[str, object, list[str]]] = [
        ("fetch_data", fetch_data, fetch_extra),
        ("build_db", build_db, []),
    ]
    if not args.skip_images:
        steps.append(("process_images", process_images, ["--force"] if args.force else []))
    steps.append(("verify", verify, []))

    for name, module, extra in steps:
        print(f"\n========== {name} ==========")
        rc = module.main(extra)
        if rc != 0:
            print(f"[build_all] 步骤 {name} 失败（exit {rc}），中止")
            return rc

    # ---- 汇总 ----
    import json
    import sqlite3

    counts = {}
    conn = sqlite3.connect(cfg.DB_PATH)
    try:
        tables = [r[0] for r in conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")]
        for t in tables:
            counts[t] = conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
    finally:
        conn.close()

    db_bytes = cfg.DB_PATH.stat().st_size
    full_images = list(cfg.ASSETS_FULL_DIR.glob("*.webp"))
    thumb_images = list(cfg.ASSETS_THUMB_DIR.glob("*.webp"))
    image_bytes = sum(p.stat().st_size for p in full_images + thumb_images)
    manifest = json.loads(cfg.MANIFEST_PATH.read_text(encoding="utf-8"))

    print("\n========== 构建汇总 ==========")
    print(f"上游锁定  pokeapi@{cfg.POKEAPI_SHA[:12]}  sprites@{cfg.SPRITES_SHA[:12]}")
    print(f"数据版本  {manifest['dataVersion']}  构建于 {started.isoformat(timespec='seconds')}")
    print(f"数据库    {cfg.DB_PATH}  {db_bytes / 1024 / 1024:.1f} MB")
    print(f"图片      full {len(full_images)} 张 / thumb {len(thumb_images)} 张，"
          f"合计 {image_bytes / 1024 / 1024:.1f} MB")
    print(f"缺图清单  {len(manifest.get('missingArtwork', []))} 个形态")
    print("各表行数:")
    for t, n in counts.items():
        print(f"  {t:22s} {n:>8}")
    elapsed = (datetime.now(timezone.utc) - started).total_seconds()
    print(f"[build_all] 完成，总耗时 {elapsed:.0f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
