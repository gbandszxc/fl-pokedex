# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.10"
# dependencies = ["requests"]
# ///
"""下载锁定 sha 的 PokeAPI data/v2/csv/*.csv 到 tools/data_builder/.cache/csv/。

用法：
    export PYTHONUTF8=1
    uv run tools/data_builder/fetch_data.py            # 按config.py锁定的sha下载（已存在的文件跳过）
    uv run tools/data_builder/fetch_data.py --force    # 强制重新下载
    uv run tools/data_builder/fetch_data.py --latest   # 获取master最新sha，回写config.py并下载
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

import config as cfg

# 构建所需的全部 CSV（缺一会构建失败，便于上游重命名时及时发现）
CSV_FILES = [
    "abilities.csv",
    "ability_flavor_text.csv",
    "ability_names.csv",
    "ability_prose.csv",
    "egg_groups.csv",
    "evolution_chains.csv",
    "evolution_triggers.csv",
    "genders.csv",
    "generations.csv",
    "growth_rates.csv",
    "items.csv",
    "locations.csv",
    "move_damage_classes.csv",
    "move_effect_prose.csv",
    "move_flavor_text.csv",
    "move_names.csv",
    "move_targets.csv",
    "moves.csv",
    "pokedexes.csv",
    "pokemon.csv",
    "pokemon_abilities.csv",
    "pokemon_colors.csv",
    "pokemon_dex_numbers.csv",
    "pokemon_egg_groups.csv",
    "pokemon_forms.csv",
    "pokemon_form_names.csv",
    "pokemon_habitats.csv",
    "pokemon_evolution.csv",
    "pokemon_moves.csv",
    "pokemon_shapes.csv",
    "pokemon_species.csv",
    "pokemon_species_flavor_text.csv",
    "pokemon_species_names.csv",
    "pokemon_stats.csv",
    "stats.csv",
    "pokemon_types.csv",
    "regions.csv",
    "types.csv",
    "type_names.csv",
    "version_groups.csv",
    "version_names.csv",
    "versions.csv",
]

RETRIES = 4
TIMEOUT = 60


def fetch_url(url: str) -> bytes:
    last_err: Exception | None = None
    for attempt in range(1, RETRIES + 1):
        try:
            resp = requests.get(url, timeout=TIMEOUT)
            if resp.status_code == 200:
                return resp.content
            if resp.status_code == 404:
                raise FileNotFoundError(url)
            last_err = RuntimeError(f"HTTP {resp.status_code}: {url}")
        except (requests.RequestException, FileNotFoundError) as exc:
            if isinstance(exc, FileNotFoundError):
                raise
            last_err = exc
        time.sleep(min(2 ** attempt, 8))
    raise RuntimeError(f"下载失败（重试 {RETRIES} 次）: {url}") from last_err


def download_csv(name: str, sha: str, dest_dir, force: bool) -> str:
    dest = dest_dir / name
    if dest.exists() and dest.stat().st_size > 0 and not force:
        return f"skip  {name}"
    try:
        data = fetch_url(cfg.pokeapi_raw_url(sha, name))
    except FileNotFoundError:
        data = fetch_url(cfg.pokeapi_jsdelivr_url(sha, name))  # jsdelivr 兜底
    if not data:
        raise RuntimeError(f"空文件: {name}")
    dest.write_bytes(data)
    return f"ok    {name} ({len(data) // 1024} KB)"


def get_latest_sha(repo: str) -> str:
    """GitHub API 获取 master 最新 commit sha；限流时回退 gh CLI。"""
    try:
        resp = requests.get(cfg.GITHUB_API_LATEST.format(repo=repo), timeout=30)
        if resp.status_code == 200:
            return resp.json()["sha"]
        print(f"[warn] GitHub API {resp.status_code}（{repo}），回退 gh CLI")
    except requests.RequestException as exc:
        print(f"[warn] GitHub API 不可达（{repo}）：{exc}，回退 gh CLI")
    out = subprocess.run(
        ["gh", "api", f"repos/{repo}/commits/master", "--jq", ".sha"],
        capture_output=True, text=True, check=True, encoding="utf-8",
    )
    return out.stdout.strip()


def update_config_shas(pokeapi_sha: str, sprites_sha: str) -> None:
    """把最新 sha 硬编码回写进 config.py（保持可重复构建）。"""
    path = cfg.TOOLS_DATA_BUILDER_DIR / "config.py"
    text = path.read_text(encoding="utf-8")
    text = re.sub(r'POKEAPI_SHA = "[0-9a-f]{40}"', f'POKEAPI_SHA = "{pokeapi_sha}"', text)
    text = re.sub(r'SPRITES_SHA = "[0-9a-f]{40}"', f'SPRITES_SHA = "{sprites_sha}"', text)
    path.write_text(text, encoding="utf-8")
    print(f"[config] 已回写 config.py: pokeapi={pokeapi_sha[:12]} sprites={sprites_sha[:12]}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="下载锁定的 PokeAPI 上游 CSV")
    parser.add_argument("--latest", action="store_true", help="获取 master 最新 sha 并回写 config.py")
    parser.add_argument("--force", action="store_true", help="忽略缓存强制重新下载")
    args = parser.parse_args(argv)

    cfg.assert_utf8_env()
    pokeapi_sha, sprites_sha = cfg.POKEAPI_SHA, cfg.SPRITES_SHA
    if args.latest:
        pokeapi_sha = get_latest_sha(cfg.REPO_POKEAPI)
        sprites_sha = get_latest_sha(cfg.REPO_SPRITES)
        update_config_shas(pokeapi_sha, sprites_sha)
        args.force = True  # sha 变了必须重新下载

    cfg.ensure_dirs()
    print(f"[fetch] pokeapi@{pokeapi_sha[:12]}  sprites@{sprites_sha[:12]}")
    t0 = time.time()
    failures: list[str] = []
    with ThreadPoolExecutor(max_workers=8) as pool:
        futures = {
            pool.submit(download_csv, name, pokeapi_sha, cfg.CACHE_CSV_DIR, args.force): name
            for name in CSV_FILES
        }
        done = 0
        for fut in as_completed(futures):
            name = futures[fut]
            try:
                print(fut.result())
            except Exception as exc:  # noqa: BLE001
                failures.append(name)
                print(f"[error] {name}: {exc}")
            done += 1
            if done % 10 == 0:
                print(f"... {done}/{len(CSV_FILES)}")
    if failures:
        print(f"[fetch] 失败 {len(failures)} 个: {failures}")
        return 1
    print(f"[fetch] 全部 {len(CSV_FILES)} 个 CSV 就绪，耗时 {time.time() - t0:.1f}s")
    return 0


if __name__ == "__main__":
    sys.exit(main())
