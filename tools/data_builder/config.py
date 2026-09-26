# -*- coding: utf-8 -*-
"""琥珀图鉴 · 数据构建管线 — 全局配置与上游锁定。

上游 commit sha 首次构建时获取并硬编码在此，保证可重复构建。
刷新途径：`uv run tools/data_builder/fetch_data.py --latest`
（会重新获取 master 最新 sha 并回写本文件，然后按新 sha 下载。）
"""

from __future__ import annotations

import os
from pathlib import Path

# ---------------------------------------------------------------------------
# 上游版本锁定（硬编码，勿随手改动；用 fetch_data.py --latest 刷新）
# ---------------------------------------------------------------------------

# PokeAPI/pokeapi master（data/v2/csv 来源）
POKEAPI_SHA = "ca0a21b3587af20b52c8a00d33812c47b75fe341"
# PokeAPI/sprites master（official-artwork 来源）
SPRITES_SHA = "a13b1f4ccd77f35fd1370d2db5f0051221e9683f"

REPO_POKEAPI = "PokeAPI/pokeapi"
REPO_SPRITES = "PokeAPI/sprites"

# raw.githubusercontent.com 为主，jsdelivr 为兜底
def pokeapi_raw_url(sha: str, name: str) -> str:
    return f"https://raw.githubusercontent.com/{REPO_POKEAPI}/{sha}/data/v2/csv/{name}"

def pokeapi_jsdelivr_url(sha: str, name: str) -> str:
    return f"https://cdn.jsdelivr.net/gh/{REPO_POKEAPI}@{sha}/data/v2/csv/{name}"

def sprites_raw_url(sha: str, image_id: int) -> str:
    return (
        f"https://raw.githubusercontent.com/{REPO_SPRITES}/{sha}"
        f"/sprites/pokemon/other/official-artwork/{image_id}.png"
    )

def sprites_jsdelivr_url(sha: str, image_id: int) -> str:
    return (
        f"https://cdn.jsdelivr.net/gh/{REPO_SPRITES}@{sha}"
        f"/sprites/pokemon/other/official-artwork/{image_id}.png"
    )

GITHUB_API_LATEST = "https://api.github.com/repos/{repo}/commits/master"

# ---------------------------------------------------------------------------
# 路径（所有脚本统一由此推导，仓库根 = tools/ 的上一级）
# ---------------------------------------------------------------------------

TOOLS_DATA_BUILDER_DIR = Path(__file__).resolve().parent
REPO_ROOT = TOOLS_DATA_BUILDER_DIR.parent.parent
CACHE_DIR = TOOLS_DATA_BUILDER_DIR / ".cache"
CACHE_CSV_DIR = CACHE_DIR / "csv"
CACHE_SPRITES_DIR = CACHE_DIR / "sprites"

ASSETS_DB_DIR = REPO_ROOT / "assets" / "database"
DB_PATH = ASSETS_DB_DIR / "pokedex.db"
MANIFEST_PATH = ASSETS_DB_DIR / "manifest.json"
ASSETS_FULL_DIR = REPO_ROOT / "assets" / "pokemon" / "full"
ASSETS_THUMB_DIR = REPO_ROOT / "assets" / "pokemon" / "thumb"

SCHEMA_VERSION = 2  # 新增 form_flavor_texts（地区形态专属说明）时 +1

# ---------------------------------------------------------------------------
# 数据契约常量（docs/data-contract.md §2/§4/§5）
# ---------------------------------------------------------------------------

# PokeAPI language_id → 本项目 language
LANGUAGE_MAP = {
    1: "ja_hrkt",
    2: "roomaji",
    4: "zh_hant",
    9: "en",
    11: "ja",
    12: "zh_hans",
}
FLAVOR_LANGUAGES = ("zh_hans", "zh_hant", "en", "ja")

# 学习集代表性版本组（每世代一个；gen9 若上游无 the-indigo-disk 数据则回退 scarlet-violet）
LEARNSET_VERSION_GROUPS = (
    "yellow",                       # gen1
    "crystal",                      # gen2
    "emerald",                      # gen3
    "heartgold-soulsilver",         # gen4
    "black-2-white-2",              # gen5
    "omega-ruby-alpha-sapphire",    # gen6
    "ultra-sun-ultra-moon",         # gen7
    "sword-shield",                 # gen8
    "the-indigo-disk",              # gen9（无数据时回退 scarlet-violet 并写入 meta）
)
LEARNSET_FALLBACK_VG = "scarlet-violet"

# pokemon_moves.pokemon_move_method_id → method
METHOD_MAP = {1: "level_up", 2: "egg", 3: "machine", 4: "tutor"}

# moves.damage_class 不做硬编码映射：直接读上游 move_damage_classes.csv 的
# id→identifier（1=status, 2=physical, 3=special）。
# 历史：A2 修复前此处曾硬编码 {1:physical,...} 与上游错位，导致全列错乱。

# 世代 → 地区（generations.region）
GENERATION_REGION = {
    1: "kanto", 2: "johto", 3: "hoenn", 4: "sinnoh", 5: "unova",
    6: "kalos", 7: "alola", 8: "galar", 9: "paldea",
}

# 地区图鉴中文名（契约 §0 硬编码映射，构建时统一追加“图鉴”后缀）
REGION_DEX_ZH = {
    "kanto": "关都",
    "johto": "城都",
    "hoenn": "丰缘",
    "sinnoh": "神奥",
    "unova": "合众",
    "kalos": "卡洛斯",
    "alola": "阿罗拉",
    "galar": "伽勒尔",
    "hisui": "洗翠",
    "paldea": "帕底亚",
}

# 地区形态后缀（is_regional 判定：form_identifier 等于该项或以其为前缀）
REGIONAL_SUFFIXES = ("alola", "galar", "hisui", "paldea")

# 形态中文名模板（契约 §5；官方 pokemon_form_names.csv 取不到时使用，
# 仅作描述性兜底——真实官方名以上游 CSV 为准，模板命中也会记入 meta 缺失清单）
FORM_SUFFIX_ZH_TEMPLATE = {
    "alola": "阿罗拉的样子",
    "galar": "伽勒尔的样子",
    "hisui": "洗翠的样子",
    "paldea": "帕底亚的样子",
    "mega": "超级进化",
    "mega-x": "超级进化Ｘ",
    "mega-y": "超级进化Ｙ",
    "gmax": "超极巨化",
    "primal": "原始回归",
    "origin": "起源形态",
    "therian": "灵兽形态",
    "incarnate": "化身形态",
    "black": "黑色形态",
    "white": "白色形态",
}

# 进化触发词根（evolution_triggers.csv identifier 直接沿用；根节点自指行固定为 root）
EVO_ROOT_TRIGGER = "root"

# 上游 pokemon_species.csv 无 is_ultra_beast 列时的兜底名单（全国图鉴编号）
ULTRA_BEAST_DEX_IDS = {
    793, 794, 795, 796, 797, 798, 799,  # 尼日耶鲁..恶食大王
    805, 806, 807, 808,                 # 毒贝比..爆焰蚊
}

# 上游 CSV 无 is_battle_only 列时的兜底名单（battle-only 变体 identifier，
# 与 PokeAPI API 层 is_battle_only=true 对齐；若 pokemon_forms.csv 有该列则以上游为准）
BATTLE_ONLY_FORM_IDENTIFIERS = {
    "cherrim-sunshine",
    "darmanitan-zen", "darmanitan-galar-zen",
    "keldeo-resolute",
    "aegislash-blade", "aegislash-hero",
    "mimikyu-busted", "mimikyu-busted-totem",
    "wishiwashi-school",
    "minior-red-core", "minior-orange-core", "minior-yellow-core",
    "minior-green-core", "minior-blue-core", "minior-indigo-core",
    "minior-violet-core",
    "zygarde-complete",
    "necrozma-ultra",
    "cramorant-gulping", "cramorant-gorging",
    "eiscue-noice",
    "morpeko-hangry",
    "eternatus-eternamax",
    "zacian-crowned", "zamazenta-crowned",
    "hoopa-unbound",
    "terapagos-stellar",
}

# ---------------------------------------------------------------------------


def ensure_dirs() -> None:
    for d in (CACHE_CSV_DIR, CACHE_SPRITES_DIR, ASSETS_DB_DIR, ASSETS_FULL_DIR, ASSETS_THUMB_DIR):
        d.mkdir(parents=True, exist_ok=True)


def assert_utf8_env() -> None:
    """运行期提醒（构建脚本约定 export PYTHONUTF8=1）。"""
    if os.name == "nt" and os.environ.get("PYTHONUTF8") != "1":
        # 不中止——内部读写均已显式指定 encoding，但打印可能受 GBK 影响
        print("[warn] 建议先执行 export PYTHONUTF8=1 再运行构建脚本")
