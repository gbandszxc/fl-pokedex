# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""解析/清洗上游 CSV，构建 assets/database/pokedex.db 与 manifest.json。

DDL、映射、校验全部以 docs/data-contract.md 为准，逐字建表建索引。
用法：export PYTHONUTF8=1 && uv run tools/data_builder/build_db.py
"""

from __future__ import annotations

import csv
import json
import re
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import config as cfg

# ---------------------------------------------------------------------------
# DDL：与 docs/data-contract.md §3 逐字一致
# ---------------------------------------------------------------------------

DDL = """\
CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);

CREATE TABLE generations(id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE, region TEXT NOT NULL);

CREATE TABLE types(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  name_zh_hans TEXT NOT NULL, name_zh_hant TEXT NOT NULL, name_en TEXT NOT NULL, name_ja TEXT NOT NULL);

CREATE TABLE abilities(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  name_zh_hans TEXT NOT NULL, name_en TEXT NOT NULL, name_ja TEXT NOT NULL,
  generation_id INTEGER NOT NULL,
  text_zh_hans TEXT,          -- 最新官方简中 flavor（可空）
  text_en TEXT);              -- 英文 short_effect（可空）

CREATE TABLE moves(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  generation_id INTEGER NOT NULL, type_id INTEGER NOT NULL,
  damage_class TEXT NOT NULL CHECK(damage_class IN ('physical','special','status')),
  power INTEGER, pp INTEGER, accuracy INTEGER,
  priority INTEGER NOT NULL DEFAULT 0, target TEXT, effect_chance INTEGER,
  name_zh_hans TEXT NOT NULL, name_en TEXT NOT NULL, name_ja TEXT NOT NULL,
  effect_en TEXT, flavor_zh_hans TEXT);

CREATE TABLE species(
  id INTEGER PRIMARY KEY, national_dex INTEGER NOT NULL UNIQUE,
  generation_id INTEGER NOT NULL,
  name_zh_hans TEXT NOT NULL, name_zh_hant TEXT NOT NULL, name_en TEXT NOT NULL,
  name_ja TEXT NOT NULL, name_ja_hrkt TEXT NOT NULL, name_roomaji TEXT,
  genus_zh_hans TEXT, genus_en TEXT,
  is_legendary INTEGER NOT NULL DEFAULT 0, is_mythical INTEGER NOT NULL DEFAULT 0,
  is_ultra_beast INTEGER NOT NULL DEFAULT 0, is_baby INTEGER NOT NULL DEFAULT 0,
  evolution_chain_id INTEGER,
  capture_rate INTEGER, base_happiness INTEGER, gender_rate INTEGER,
  hatch_counter INTEGER, growth_rate TEXT,
  egg_group_1 TEXT, egg_group_2 TEXT,
  color TEXT, shape TEXT, habitat TEXT);
CREATE INDEX idx_species_national_dex ON species(national_dex);
CREATE INDEX idx_species_generation ON species(generation_id);
CREATE INDEX idx_species_name_zh ON species(name_zh_hans);
CREATE INDEX idx_species_name_en ON species(name_en);
CREATE INDEX idx_species_name_ja ON species(name_ja);

CREATE TABLE forms(
  id INTEGER PRIMARY KEY, species_id INTEGER NOT NULL,
  form_identifier TEXT,              -- NULL = 默认形态
  form_name_zh TEXT NOT NULL, form_name_en TEXT NOT NULL,
  is_default INTEGER NOT NULL DEFAULT 0,
  is_mega INTEGER NOT NULL DEFAULT 0, is_gmax INTEGER NOT NULL DEFAULT 0,
  is_regional INTEGER NOT NULL DEFAULT 0, is_battle_only INTEGER NOT NULL DEFAULT 0,
  form_order INTEGER NOT NULL,
  height INTEGER, weight INTEGER, base_experience INTEGER,
  has_gender_difference INTEGER NOT NULL DEFAULT 0,
  artwork_asset TEXT, thumb_asset TEXT);   -- 形如 assets/pokemon/full/6.webp；缺失为 NULL
CREATE INDEX idx_forms_species ON forms(species_id);

CREATE TABLE form_types(
  form_id INTEGER NOT NULL, slot INTEGER NOT NULL, type_id INTEGER NOT NULL,
  PRIMARY KEY(form_id, slot));
CREATE INDEX idx_form_types_type ON form_types(type_id);

CREATE TABLE form_stats(
  form_id INTEGER NOT NULL,
  stat TEXT NOT NULL CHECK(stat IN ('hp','attack','defense','special_attack','special_defense','speed')),
  base_value INTEGER NOT NULL, PRIMARY KEY(form_id, stat));

CREATE TABLE form_abilities(
  form_id INTEGER NOT NULL, slot INTEGER NOT NULL, ability_id INTEGER NOT NULL,
  is_hidden INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(form_id, slot, is_hidden));
CREATE INDEX idx_form_abilities_ability ON form_abilities(ability_id);

-- 学习集仅收录代表性版本组（见 §4），一版本组一行
CREATE TABLE pokemon_form_moves(
  form_id INTEGER NOT NULL, move_id INTEGER NOT NULL,
  method TEXT NOT NULL CHECK(method IN ('level_up','machine','egg','tutor','other')),
  level INTEGER,                     -- 仅 level_up 有值
  version_group TEXT NOT NULL,
  PRIMARY KEY(form_id, move_id, method, version_group));
CREATE INDEX idx_pfm_moves_form ON pokemon_form_moves(form_id);
CREATE INDEX idx_pfm_moves_move ON pokemon_form_moves(move_id);
CREATE INDEX idx_pfm_moves_vg ON pokemon_form_moves(version_group);

CREATE TABLE evolution_chains(id INTEGER PRIMARY KEY, root_species_id INTEGER NOT NULL);

CREATE TABLE evolution_edges(
  chain_id INTEGER NOT NULL,
  from_species_id INTEGER,           -- NULL 表示根节点自指行（root→root）
  to_species_id INTEGER NOT NULL,
  trigger TEXT NOT NULL,             -- level-up / trade / use-item / shed / spin / ...
  min_level INTEGER, item TEXT, held_item TEXT,
  known_move TEXT, known_move_type TEXT, location TEXT, time_of_day TEXT,
  gender TEXT, min_happiness INTEGER, min_affection INTEGER, min_beauty INTEGER,
  relative_physical_stats TEXT,      -- greater / less / equal
  party_species TEXT, party_type TEXT, trade_species TEXT,
  needs_overworld_rain INTEGER NOT NULL DEFAULT 0,
  turn_upside_down INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY(chain_id, to_species_id));
CREATE INDEX idx_evo_from ON evolution_edges(from_species_id);
CREATE INDEX idx_evo_to ON evolution_edges(to_species_id);

CREATE TABLE versions(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  generation_id INTEGER NOT NULL, version_group TEXT NOT NULL,
  name_zh_hans TEXT, name_en TEXT NOT NULL, name_ja TEXT);

CREATE TABLE flavor_texts(
  species_id INTEGER NOT NULL, version_id INTEGER NOT NULL,
  language TEXT NOT NULL CHECK(language IN ('zh_hans','zh_hant','en','ja')),
  flavor_text TEXT NOT NULL,
  PRIMARY KEY(species_id, version_id, language));
CREATE INDEX idx_flavor_species ON flavor_texts(species_id);

-- 地区形态专属说明（契约 §6）：版本地区 == 地区形态的 species 文本移入本表
CREATE TABLE form_flavor_texts(form_id INTEGER NOT NULL, version_id INTEGER NOT NULL, language TEXT NOT NULL CHECK(language IN ('zh_hans','zh_hant','en','ja')), flavor_text TEXT NOT NULL, PRIMARY KEY(form_id, version_id, language));
CREATE INDEX idx_form_flavor_form ON form_flavor_texts(form_id);

CREATE TABLE pokedexes(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  name_zh_hans TEXT NOT NULL, generation_id INTEGER);

CREATE TABLE species_dex_numbers(
  pokedex_id INTEGER NOT NULL, species_id INTEGER NOT NULL, dex_number INTEGER NOT NULL,
  PRIMARY KEY(pokedex_id, species_id));
CREATE INDEX idx_sdn_species ON species_dex_numbers(species_id);
"""

TABLE_ORDER = [
    "meta", "generations", "types", "abilities", "moves", "species", "forms",
    "form_types", "form_stats", "form_abilities", "pokemon_form_moves",
    "evolution_chains", "evolution_edges", "versions", "flavor_texts",
    "form_flavor_texts", "pokedexes", "species_dex_numbers",
]

# ---------------------------------------------------------------------------
# 工具函数
# ---------------------------------------------------------------------------

def _int(s: str) -> int | None:
    return int(s) if s not in ("", None) else None


def _flag(s: str) -> int:
    return 1 if s == "1" else 0


def _is_cjk(ch: str) -> bool:
    code = ord(ch)
    return (
        0x3000 <= code <= 0x9FFF      # CJK 统一表意/标点
        or 0x3040 <= code <= 0x30FF   # 假名
        or 0xFF00 <= code <= 0xFFEF   # 全角符号
    )


def clean_flavor(text: str) -> str:
    """压平换行、去 U+000C/U+001C 等控制符（契约 §6）。

    中文语境下相邻直接拼接，其余替换为单个空格，再收敛重复空格。
    """
    out: list[str] = []
    i, n = 0, len(text)
    while i < n:
        if ord(text[i]) < 32 or ord(text[i]) == 127:
            j = i
            while j < n and (ord(text[j]) < 32 or ord(text[j]) == 127):
                j += 1
            prev = out[-1] if out else ""
            nxt = text[j] if j < n else ""
            if prev and nxt and _is_cjk(prev) and _is_cjk(nxt):
                pass  # CJK 之间直接连接，避免出现多余空格
            else:
                out.append(" ")
            i = j
        else:
            out.append(text[i])
            i += 1
    return re.sub(r" {2,}", " ", "".join(out)).strip()


# ---------------------------------------------------------------------------
# 构建器
# ---------------------------------------------------------------------------

class Builder:
    def __init__(self) -> None:
        self.cache = cfg.CACHE_CSV_DIR
        self.meta: dict[str, str] = {}
        self.rows: dict[str, list[tuple]] = {t: [] for t in TABLE_ORDER}

    # ---- 读取 ----
    def read(self, name: str) -> list[dict]:
        with open(self.cache / name, encoding="utf-8", newline="") as f:
            return list(csv.DictReader(f))

    # ---- 名称工具 ----
    @staticmethod
    def pick_name(names: dict[int, str], lang: int) -> str | None:
        return names.get(lang)

    def name_with_fallback(
        self, names: dict[int, str], lang: int, fallback: str,
        missing_key: str, missing_id: int,
    ) -> str:
        """取指定语言名称；缺失时回退并记入 meta 缺失清单。"""
        value = names.get(lang)
        if value:
            return value
        self.missing.setdefault(missing_key, []).append(missing_id)
        return fallback

    # ---- 主流程 ----
    def build(self) -> dict:
        self.missing: dict[str, list[int]] = defaultdict(list)
        self.notes: dict[str, object] = {}

        gens = self.build_generations()
        self.build_types()
        self.build_abilities()
        self.build_moves()
        self.build_species(gens)
        self.build_forms()
        self.build_form_details()
        self.build_moves_learnsets()
        self.build_evolution()
        self.build_versions_flavors()
        self.attribute_form_flavors()
        self.build_pokedexes()

        self.finalize_meta()
        return self.write_db()

    # -- generations / types / abilities / moves --
    def build_generations(self) -> dict[int, str]:
        regions = {r["id"]: r["identifier"] for r in self.read("regions.csv")}
        for r in self.read("generations.csv"):
            region = regions[r["main_region_id"]]
            self.rows["generations"].append((int(r["id"]), r["identifier"], region))
        return {int(r["id"]): r["identifier"] for r in self.read("generations.csv")}

    def build_types(self) -> None:
        names: dict[int, dict[int, str]] = defaultdict(dict)
        for r in self.read("type_names.csv"):
            names[int(r["type_id"])][int(r["local_language_id"])] = r["name"]
        for r in self.read("types.csv"):
            tid = int(r["id"])
            en = self.name_with_fallback(names[tid], 9, r["identifier"], "missing_type_name_en", tid)
            self.rows["types"].append((
                tid, r["identifier"],
                self.name_with_fallback(names[tid], 12, en, "missing_type_name_zh_hans", tid),
                self.name_with_fallback(names[tid], 4, en, "missing_type_name_zh_hant", tid),
                en,
                self.name_with_fallback(names[tid], 11, en, "missing_type_name_ja", tid),
            ))

    def build_abilities(self) -> None:
        names: dict[int, dict[int, str]] = defaultdict(dict)
        for r in self.read("ability_names.csv"):
            names[int(r["ability_id"])][int(r["local_language_id"])] = r["name"]
        prose_en: dict[int, str] = {}
        for r in self.read("ability_prose.csv"):
            if int(r["local_language_id"]) == 9 and r["ability_id"] not in prose_en:
                prose_en[int(r["ability_id"])] = r["short_effect"] or r["effect"] or ""
        flavor_zh: dict[int, tuple[int, str]] = {}
        for r in self.read("ability_flavor_text.csv"):
            if int(r["language_id"]) == 12:
                aid, vg = int(r["ability_id"]), int(r["version_group_id"])
                if aid not in flavor_zh or vg > flavor_zh[aid][0]:
                    flavor_zh[aid] = (vg, clean_flavor(r["flavor_text"]))
        for r in self.read("abilities.csv"):
            aid = int(r["id"])
            en = self.name_with_fallback(names[aid], 9, r["identifier"], "missing_ability_name_en", aid)
            self.rows["abilities"].append((
                aid, r["identifier"],
                self.name_with_fallback(names[aid], 12, en, "missing_ability_name_zh_hans", aid),
                en,
                self.name_with_fallback(names[aid], 11, en, "missing_ability_name_ja", aid),
                int(r["generation_id"]),
                flavor_zh.get(aid, (0, None))[1],
                clean_flavor(prose_en[aid]) if aid in prose_en else None,
            ))

    def build_moves(self) -> None:
        names: dict[int, dict[int, str]] = defaultdict(dict)
        for r in self.read("move_names.csv"):
            names[int(r["move_id"])][int(r["local_language_id"])] = r["name"]
        targets = {r["id"]: r["identifier"] for r in self.read("move_targets.csv")}
        # 伤害分类以上游 move_damage_classes.csv 为唯一事实（A2：1=status, 2=physical, 3=special），
        # 禁止硬编码 id 映射（历史缺陷即由此而来）
        damage_classes = {
            int(r["id"]): r["identifier"] for r in self.read("move_damage_classes.csv")
        }
        assert set(damage_classes.values()) >= {"physical", "special", "status"}, \
            "move_damage_classes.csv 缺少三类枚举值"
        prose_en: dict[int, str] = {}
        for r in self.read("move_effect_prose.csv"):
            if int(r["local_language_id"]) == 9 and int(r["move_effect_id"]) not in prose_en:
                prose_en[int(r["move_effect_id"])] = r["short_effect"] or r["effect"] or ""
        flavor_zh: dict[int, tuple[int, str]] = {}
        for r in self.read("move_flavor_text.csv"):
            if int(r["language_id"]) == 12:
                mid, vg = int(r["move_id"]), int(r["version_group_id"])
                if mid not in flavor_zh or vg > flavor_zh[mid][0]:
                    flavor_zh[mid] = (vg, clean_flavor(r["flavor_text"]))
        for r in self.read("moves.csv"):
            mid = int(r["id"])
            damage_class = damage_classes[int(r["damage_class_id"])]
            assert damage_class in ("physical", "special", "status"), \
                f"招式 {mid} 伤害分类异常: {damage_class}"
            en = self.name_with_fallback(names[mid], 9, r["identifier"], "missing_move_name_en", mid)
            effect = prose_en.get(int(r["effect_id"])) if r["effect_id"] else None
            self.rows["moves"].append((
                mid, r["identifier"], int(r["generation_id"]), int(r["type_id"]),
                damage_class,
                _int(r["power"]), _int(r["pp"]), _int(r["accuracy"]),
                int(r["priority"] or 0), targets[r["target_id"]], _int(r["effect_chance"]),
                self.name_with_fallback(names[mid], 12, en, "missing_move_name_zh_hans", mid),
                en,
                self.name_with_fallback(names[mid], 11, en, "missing_move_name_ja", mid),
                clean_flavor(effect) if effect else None,
                flavor_zh.get(mid, (0, None))[1],
            ))

    # -- species --
    def build_species(self, gens: dict[int, str]) -> None:
        names: dict[int, dict[int, dict]] = defaultdict(dict)
        for r in self.read("pokemon_species_names.csv"):
            names[int(r["pokemon_species_id"])][int(r["local_language_id"])] = {
                "name": r["name"], "genus": r["genus"],
            }
        growth = {r["id"]: r["identifier"] for r in self.read("growth_rates.csv")}
        colors = {r["id"]: r["identifier"] for r in self.read("pokemon_colors.csv")}
        shapes = {r["id"]: r["identifier"] for r in self.read("pokemon_shapes.csv")}
        habitats = {r["id"]: r["identifier"] for r in self.read("pokemon_habitats.csv")}
        eggs: dict[int, list[str]] = defaultdict(list)
        egg_ids = {r["id"]: r["identifier"] for r in self.read("egg_groups.csv")}
        for r in sorted(self.read("pokemon_egg_groups.csv"), key=lambda x: int(x["egg_group_id"])):
            eggs[int(r["species_id"])].append(egg_ids[r["egg_group_id"]])

        species = sorted(self.read("pokemon_species.csv"), key=lambda r: int(r["id"]))
        assert len(species) == 1025, f"species 行数 {len(species)} != 1025"

        for r in species:
            sid = int(r["id"])
            n = names[sid]
            if 9 in n and n[9]["name"]:
                en = n[9]["name"]
            else:  # 上游保证四语齐全，此处仅防御
                en = r["identifier"]
                self.missing["missing_species_name_en"].append(sid)

            def nm(lang: int, key: str, missing_key: str) -> str | None:
                """名称缺失回退英文并记录；genus 允许为空不记录。"""
                if lang in n and n[lang][key]:
                    return n[lang][key]
                if key == "name":
                    self.missing[missing_key].append(sid)
                    return en
                return None

            national_dex = sid  # species id 与全国图鉴编号一致（1..1025 连续，构建前已断言）
            egg = (eggs[sid] + [None, None])[:2]
            self.rows["species"].append((
                sid, national_dex, int(r["generation_id"]),
                nm(12, "name", "missing_species_name_zh_hans"),
                nm(4, "name", "missing_species_name_zh_hant"),
                en,
                nm(11, "name", "missing_species_name_ja"),
                nm(1, "name", "missing_species_name_ja_hrkt"),
                n[2]["name"] if 2 in n else None,  # roomaji 契约允许为空，不回退
                nm(12, "genus", ""),
                nm(9, "genus", ""),
                _flag(r["is_legendary"]), _flag(r["is_mythical"]),
                1 if national_dex in cfg.ULTRA_BEAST_DEX_IDS else 0,
                _flag(r["is_baby"]),
                _int(r["evolution_chain_id"]),
                _int(r["capture_rate"]), _int(r["base_happiness"]), _int(r["gender_rate"]),
                _int(r["hatch_counter"]), growth[r["growth_rate_id"]],
                egg[0], egg[1],
                colors.get(r["color_id"]), shapes.get(r["shape_id"]),
                habitats.get(r["habitat_id"]) if r["habitat_id"] else None,
            ))

    # -- forms --
    @staticmethod
    def choose_form_row(rows: list[dict], variety_id: int) -> dict:
        """上游 28 个 variety 挂多个 pokemon_forms 行（unown/burmy/cherrim 等）。

        每个 variety 取一行“代表 form”：优先 id 与 variety 相同者，
        其次 is_default=1，再按 form_order 最小。
        """
        for r in rows:
            if int(r["id"]) == variety_id:
                return r
        defaults = [r for r in rows if r["is_default"] == "1"]
        pool = defaults if defaults else rows
        return min(pool, key=lambda r: int(r["form_order"] or r["order"] or 0))

    def build_forms(self) -> None:
        species_rows = {r[0]: r for r in self.rows["species"]}
        sp_extra = {int(r["id"]): (r["identifier"], _flag(r["has_gender_differences"]))
                    for r in self.read("pokemon_species.csv")}
        variety = {}
        for r in self.read("pokemon.csv"):
            variety[int(r["id"])] = (int(r["species_id"]), r["identifier"], _flag(r["is_default"]),
                                     _int(r["height"]), _int(r["weight"]), _int(r["base_experience"]))

        form_rows: dict[int, list[dict]] = defaultdict(list)
        for r in self.read("pokemon_forms.csv"):
            form_rows[int(r["pokemon_id"])].append(r)
        assert set(form_rows) == set(variety), "存在没有 pokemon_forms 行的 variety"
        chosen = {vid: self.choose_form_row(rows, vid) for vid, rows in form_rows.items()}

        # 官方形态名以 pokemon_forms.id 为键（≠ variety id，必须经 chosen 行中转）
        zh_hans: dict[int, str] = {}
        zh_hant: dict[int, str] = {}
        official_en: dict[int, str] = {}
        for r in self.read("pokemon_form_names.csv"):
            lang = int(r["local_language_id"])
            fid = int(r["pokemon_form_id"])
            if lang == 12:
                zh_hans.setdefault(fid, r["form_name"])
            elif lang == 4:
                zh_hant.setdefault(fid, r["form_name"])
            elif lang == 9:
                official_en.setdefault(fid, r["form_name"])
        official_zh = {**zh_hant, **zh_hans}  # 简中优先，繁中兜底

        for vid in sorted(variety):
            sid, ident, is_default, height, weight, base_exp = variety[vid]
            fmeta = chosen[vid]
            sp = species_rows[sid]
            # form_identifier：NULL = 默认形态（契约 §3）；非默认优先上游 form_identifier
            form_identifier = None if is_default else (fmeta["form_identifier"] or None)

            # form_name_zh：默认形态=种名；官方 zh(12→4)→模板→英文回退并记 meta
            if is_default:
                name_zh, name_en = sp[3], sp[5]
            else:
                fmeta_id = int(fmeta["id"])
                name_en = official_en.get(fmeta_id) or None
                name_zh = official_zh.get(fmeta_id) or None
                if name_en is None:
                    name_en = (form_identifier or ident).replace("-", " ").title()
                    self.missing["missing_form_name_en"].append(vid)
                if name_zh is None:
                    tpl = self.form_suffix_template(form_identifier)
                    if tpl:
                        name_zh = tpl
                        self.missing["form_name_zh_template_fallback"].append(vid)
                    else:
                        name_zh = name_en
                        self.missing["missing_form_name_zh"].append(vid)

            is_regional = int(any(
                form_identifier == s or (form_identifier or "").startswith(s + "-")
                for s in cfg.REGIONAL_SUFFIXES
            )) if form_identifier else 0
            form_order = int(fmeta["form_order"] or fmeta["order"] or 1)
            self.rows["forms"].append((
                vid, sid, form_identifier, name_zh, name_en,
                is_default,
                _flag(fmeta["is_mega"]),
                1 if ident.endswith("-gmax") else 0,
                is_regional,
                _flag(fmeta["is_battle_only"]),
                form_order,
                height, weight, base_exp,
                sp_extra[sid][1],
                None, None,  # artwork_asset / thumb_asset 由 process_images.py 回填
            ))

        assert len(self.rows["forms"]) >= len(self.rows["species"]), "forms 行数 < species"
        defaults = defaultdict(int)
        for row in self.rows["forms"]:
            defaults[row[1]] += 1 if row[5] else 0
        no_default = [sid for sid in species_rows if defaults[sid] != 1]
        assert not no_default, f"无默认形态的 species: {no_default[:10]}"

    # -- form_types / form_stats / form_abilities（键 = variety id，与 forms.id 对齐）--
    def build_form_details(self) -> None:
        form_ids = {r[0] for r in self.rows["forms"]}
        # 属性
        for r in sorted(self.read("pokemon_types.csv"), key=lambda x: (int(x["pokemon_id"]), int(x["slot"]))):
            form_id = int(r["pokemon_id"])
            assert form_id in form_ids, f"pokemon_types 引用未知 variety {form_id}"
            self.rows["form_types"].append((form_id, int(r["slot"]), int(r["type_id"])))
        # 种族值（仅 1..6 六项战斗数值；accuracy/evasion/special 非种族值，跳过）
        stat_names = {
            1: "hp", 2: "attack", 3: "defense",
            4: "special_attack", 5: "special_defense", 6: "speed",
        }
        for r in sorted(self.read("pokemon_stats.csv"), key=lambda x: (int(x["pokemon_id"]), int(x["stat_id"]))):
            stat = stat_names.get(int(r["stat_id"]))
            if stat is None:
                continue
            form_id = int(r["pokemon_id"])
            assert form_id in form_ids, f"pokemon_stats 引用未知 variety {form_id}"
            self.rows["form_stats"].append((form_id, stat, int(r["base_stat"])))
        # 特性（PK(form, slot, is_hidden)：防御性去重，保留首行）
        seen_abilities: set[tuple] = set()
        for r in sorted(self.read("pokemon_abilities.csv"),
                        key=lambda x: (int(x["pokemon_id"]), int(x["slot"]), int(x["is_hidden"]))):
            key = (int(r["pokemon_id"]), int(r["slot"]), int(r["is_hidden"]))
            if key in seen_abilities:
                continue
            seen_abilities.add(key)
            assert key[0] in form_ids, f"pokemon_abilities 引用未知 variety {key[0]}"
            self.rows["form_abilities"].append((key[0], key[1], int(r["ability_id"]), key[2]))

    def form_suffix_template(self, form_identifier: str | None) -> str | None:
        if not form_identifier:
            return None
        if form_identifier in cfg.FORM_SUFFIX_ZH_TEMPLATE:
            return cfg.FORM_SUFFIX_ZH_TEMPLATE[form_identifier]
        # 前缀匹配（如 alola-battle → 阿罗拉的样子；paldea-combat → 帕底亚的样子）
        for suffix, zh in cfg.FORM_SUFFIX_ZH_TEMPLATE.items():
            if form_identifier.startswith(suffix + "-"):
                return zh
        return None

    # -- learnsets --
    def build_moves_learnsets(self) -> None:
        vg_ids = {r["identifier"]: int(r["id"]) for r in self.read("version_groups.csv")}
        # gen9 代表组无数据时回退 scarlet-violet（契约 §4）
        targets = list(cfg.LEARNSET_VERSION_GROUPS)
        fallback_note = ""
        vg_seen: set[str] = set()
        with open(self.cache / "pokemon_moves.csv", encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                vg_seen.add(r["version_group_id"])
        for vg in list(targets):
            if vg not in vg_ids or str(vg_ids[vg]) not in vg_seen:
                if vg == cfg.LEARNSET_FALLBACK_VG:
                    raise RuntimeError(f"回退版本组 {vg} 也无数据")
                targets[targets.index(vg)] = cfg.LEARNSET_FALLBACK_VG
                fallback_note = f"{vg}->{cfg.LEARNSET_FALLBACK_VG}"
        assert len(set(targets)) == len(cfg.LEARNSET_VERSION_GROUPS)
        self.notes["learnset_fallback"] = fallback_note
        self.notes["learnset_version_groups"] = targets

        want_vg = {str(vg_ids[vg]): vg for vg in targets}
        # PK(form, move, method, vg)；level_up 同招式多等级取最小
        merged: dict[tuple, int | None] = {}
        with open(self.cache / "pokemon_moves.csv", encoding="utf-8", newline="") as f:
            reader = csv.DictReader(f)
            for r in reader:
                vg = want_vg.get(r["version_group_id"])
                if vg is None:
                    continue
                method = cfg.METHOD_MAP.get(int(r["pokemon_move_method_id"]), "other")
                level = _int(r["level"]) if method == "level_up" else None
                key = (int(r["pokemon_id"]), int(r["move_id"]), method, vg)
                if key in merged:
                    if method == "level_up":
                        old = merged[key]
                        merged[key] = level if old is None else min(old, level)
                else:
                    merged[key] = level
        self.rows["pokemon_form_moves"] = [
            (form_id, move_id, method, level, vg)
            for (form_id, move_id, method, vg), level in sorted(merged.items())
        ]
        per_vg = defaultdict(int)
        for _, _, _, _, vg in self.rows["pokemon_form_moves"]:
            per_vg[vg] += 1
        for vg in targets:
            assert per_vg[vg] > 0, f"版本组 {vg} 在学习集中无数据"

    # -- evolution --
    def build_evolution(self) -> None:
        sp = self.read("pokemon_species.csv")
        chain_of = {int(r["id"]): int(r["evolution_chain_id"]) for r in sp}
        evolves_from = {int(r["id"]): (_int(r["evolves_from_species_id"])) for r in sp}

        chain_members: dict[int, list[int]] = defaultdict(list)
        for sid, chain in chain_of.items():
            chain_members[chain].append(sid)
        triggers = {r["id"]: r["identifier"] for r in self.read("evolution_triggers.csv")}
        items = {r["id"]: r["identifier"] for r in self.read("items.csv")}
        locations = {r["id"]: r["identifier"] for r in self.read("locations.csv")}
        genders = {r["id"]: r["identifier"] for r in self.read("genders.csv")}
        types = {r["id"]: r["identifier"] for r in self.read("types.csv")}
        species_ident = {int(r["id"]): r["identifier"] for r in sp}
        moves_ident = {r[0]: r[1] for r in self.rows["moves"]}
        rel_phys = {"1": "greater", "-1": "less", "0": "equal"}

        # 根节点自指行（root→root，trigger=root）
        for chain in sorted(chain_members):
            root = min(sid for sid in chain_members[chain] if evolves_from[sid] is None)
            self.rows["evolution_chains"].append((chain, root))
            self.rows["evolution_edges"].append(
                (chain, None, root, cfg.EVO_ROOT_TRIGGER,
                 None, None, None, None, None, None, None, None,
                 None, None, None, None, None, None, None, 0, 0))

        # 同一 (chain, to) 存在跨版本组的条件变体（如 蚊香蝌蚪・叶之石/苔藓岩），
        # DDL PK(chain, to) 要求合并为一行：取最新 version_group 的条件（最贴近现行游戏）。
        grouped: dict[tuple, list[dict]] = defaultdict(list)
        for r in self.read("pokemon_evolution.csv"):
            to_sid = int(r["evolved_species_id"])
            grouped[(chain_of[to_sid], to_sid)].append(r)
        merged_out = sum(len(v) - 1 for v in grouped.values())
        for (chain, to_sid) in sorted(grouped):
            r = max(grouped[(chain, to_sid)], key=lambda x: int(x["version_group_id"] or 0))
            self.rows["evolution_edges"].append((
                chain,
                evolves_from[to_sid],
                to_sid,
                triggers[r["evolution_trigger_id"]],
                _int(r["minimum_level"]),
                items.get(r["trigger_item_id"]) if r["trigger_item_id"] else None,
                items.get(r["held_item_id"]) if r["held_item_id"] else None,
                moves_ident.get(int(r["known_move_id"])) if r["known_move_id"] else None,
                types.get(r["known_move_type_id"]) if r["known_move_type_id"] else None,
                locations.get(r["location_id"]) if r["location_id"] else None,
                r["time_of_day"] or None,
                genders.get(r["gender_id"]) if r["gender_id"] else None,
                _int(r["minimum_happiness"]), _int(r["minimum_affection"]), _int(r["minimum_beauty"]),
                rel_phys.get(r["relative_physical_stats"]) or None,
                species_ident.get(int(r["party_species_id"])) if r["party_species_id"] else None,
                types.get(r["party_type_id"]) if r["party_type_id"] else None,
                species_ident.get(int(r["trade_species_id"])) if r["trade_species_id"] else None,
                _flag(r["needs_overworld_rain"]),
                _flag(r["turn_upside_down"]),
            ))
        if merged_out:
            self.notes["evolution_variant_rows_merged"] = merged_out

    # -- versions & flavor texts --
    def build_versions_flavors(self) -> None:
        vgroups = {r["id"]: (r["identifier"], int(r["generation_id"])) for r in self.read("version_groups.csv")}
        vnames: dict[int, dict[int, str]] = defaultdict(dict)
        for r in self.read("version_names.csv"):
            vnames[int(r["version_id"])][int(r["local_language_id"])] = r["name"]
        for r in self.read("versions.csv"):
            vid = int(r["id"])
            vg_ident, gen_id = vgroups[r["version_group_id"]]
            en = self.name_with_fallback(vnames[vid], 9, r["identifier"], "missing_version_name_en", vid)
            self.rows["versions"].append((
                vid, r["identifier"], gen_id, vg_ident,
                vnames[vid].get(12), en, vnames[vid].get(11),
            ))

        lang_map = {int(k): v for k, v in cfg.LANGUAGE_MAP.items()}
        kept_langs = {"zh_hans", "zh_hant", "en", "ja"}
        seen: set[tuple] = set()
        species_with_zh: set[int] = set()
        dup = 0
        for r in self.read("pokemon_species_flavor_text.csv"):
            lang = lang_map.get(int(r["language_id"]))
            if lang not in kept_langs:
                continue
            sid, vid = int(r["species_id"]), int(r["version_id"])
            key = (sid, vid, lang)
            if key in seen:
                dup += 1
                continue
            seen.add(key)
            text = clean_flavor(r["flavor_text"])
            if not text:
                continue
            self.rows["flavor_texts"].append((sid, vid, lang, text))
            if lang == "zh_hans":
                species_with_zh.add(sid)
        all_species = {r[0] for r in self.rows["species"]}
        self.missing["species_without_zh_hans_flavor"] = sorted(all_species - species_with_zh)
        if dup:
            self.notes["flavor_duplicate_rows_dropped"] = dup

    # -- 地区形态文本归属（契约 §6）--
    def attribute_form_flavors(self) -> None:
        """把「版本地区 == 地区形态」的 species 文本移入 form_flavor_texts。

        上游地区图鉴登记的是地区形态，对应版本的 flavor 实际描述的是地区
        形态（如剑/盾的呆呆兽登记的是伽勒尔的样子）；其余文本维持 species
        级（描述默认形态）。mega/gmax 等其他形态不建 form 文本。
        """
        # 仅收地区形态：is_regional=1 且 form_identifier 恰为地区名
        regional_forms: dict[int, dict[str, int]] = defaultdict(dict)
        for row in self.rows["forms"]:
            if row[8] and row[2] in cfg.REGIONAL_SUFFIXES:
                regional_forms[row[1]][row[2]] = row[0]

        # vid → (version_group, generation_id)
        vg_gen = {row[0]: (row[3], row[2]) for row in self.rows["versions"]}

        def version_region(vid: int) -> str | None:
            vg, gen_id = vg_gen[vid]
            if vg == "lets-go-pikachu-lets-go-eevee":
                return "kanto"   # Let's Go 重访关都
            if vg == "legends-arceus":
                return "hisui"   # 传说阿尔宙斯在洗翠（上游归第 8 世代）
            return cfg.GENERATION_REGION.get(gen_id)

        kept: list[tuple] = []
        for row in self.rows["flavor_texts"]:
            sid, vid, lang, text = row
            forms_of_species = regional_forms.get(sid)
            region = version_region(vid)
            form_id = (
                forms_of_species.get(region)
                if forms_of_species and region else None
            )
            if form_id is not None:
                self.rows["form_flavor_texts"].append((form_id, vid, lang, text))
            else:
                kept.append(row)
        self.rows["flavor_texts"] = kept

    # -- pokedexes --
    def build_pokedexes(self) -> None:
        regions = {r["id"]: r["identifier"] for r in self.read("regions.csv")}
        region_to_gen = {region: gen for gen, region in cfg.GENERATION_REGION.items()}
        dexes = self.read("pokedexes.csv")
        included = []
        for r in sorted(dexes, key=lambda x: int(x["id"])):
            region = regions.get(r["region_id"]) if r["region_id"] else None
            if not region or region not in cfg.REGION_DEX_ZH:
                continue  # national / 非主线 / 未映射地区一律排除
            gen = region_to_gen.get(region)
            if region == "hisui":
                gen = 8  # Legends: Arceus 属第 8 世代
            included.append((int(r["id"]), r["identifier"], f"{cfg.REGION_DEX_ZH[region]}图鉴", gen))
        self.rows["pokedexes"] = included

        included_ids = {d[0] for d in included}
        for r in self.read("pokemon_dex_numbers.csv"):
            pid = int(r["pokedex_id"])
            if pid in included_ids:
                self.rows["species_dex_numbers"].append(
                    (pid, int(r["species_id"]), int(r["pokedex_number"])))

        by_name: dict[str, list[str]] = defaultdict(list)
        for _, ident, name, _ in included:
            by_name[name].append(ident)
        self.notes["duplicate_pokedex_names"] = {
            k: v for k, v in by_name.items() if len(v) > 1
        }

    # -- meta / 落盘 --
    def finalize_meta(self) -> None:
        counts = {t: len(rows) for t, rows in self.rows.items()}
        self.meta.update({
            "schema_version": str(cfg.SCHEMA_VERSION),
            "data_version": f"pokeapi@{cfg.POKEAPI_SHA[:12]}",
            "upstream_pokeapi_sha": cfg.POKEAPI_SHA,
            "upstream_sprites_sha": cfg.SPRITES_SHA,
            "build_date": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "row_counts": json.dumps(counts, ensure_ascii=False),
            "missing_json": json.dumps({
                "missing_species_name": {k: v for k, v in self.missing.items() if k.startswith("missing_species")},
                "missing_form_name_zh": {
                    "enFallback": sorted(self.missing.get("missing_form_name_zh", [])),
                    "templateFallback": sorted(self.missing.get("form_name_zh_template_fallback", [])),
                },
                "missing_move_name_zh_hans": sorted(self.missing.get("missing_move_name_zh_hans", [])),
                "missing_ability_name_zh_hans": sorted(self.missing.get("missing_ability_name_zh_hans", [])),
                "species_without_zh_hans_flavor": self.missing.get("species_without_zh_hans_flavor", []),
            }, ensure_ascii=False),
            "learnset_version_groups": json.dumps(self.notes.get("learnset_version_groups", [])),
            "learnset_vg_fallback": self.notes.get("learnset_fallback", ""),
            "duplicate_pokedex_names": json.dumps(self.notes.get("duplicate_pokedex_names", {}), ensure_ascii=False),
        })
        for key in ("evolution_variant_rows_merged", "flavor_duplicate_rows_dropped"):
            if key in self.notes:
                self.meta[key] = str(self.notes[key])

    def write_db(self) -> dict:
        cfg.ensure_dirs()
        if cfg.DB_PATH.exists():
            cfg.DB_PATH.unlink()
        conn = sqlite3.connect(cfg.DB_PATH)
        try:
            conn.execute("PRAGMA page_size = 8192")  # 立绘外最大头是 form_moves/说明文，大页减少页开销
            conn.executescript(DDL)
            for table in TABLE_ORDER:
                rows = self.rows[table]
                if table == "meta":
                    rows = list(self.meta.items())
                if not rows:
                    continue
                placeholders = ",".join("?" * len(rows[0]))
                conn.executemany(f"INSERT INTO {table} VALUES ({placeholders})", rows)
            conn.commit()
            conn.execute("VACUUM")
            counts = {t: conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in TABLE_ORDER}
            conn.execute("UPDATE meta SET value = ? WHERE key = 'row_counts'",
                         (json.dumps(counts, ensure_ascii=False),))
            conn.commit()
        finally:
            conn.close()

        manifest = {
            "schemaVersion": cfg.SCHEMA_VERSION,
            "dataVersion": f"pokeapi@{cfg.POKEAPI_SHA[:12]}",
            "pokemonCount": counts["species"],
            "formCount": counts["forms"],
            "moveCount": counts["moves"],
            "abilityCount": counts["abilities"],
            "versionCount": counts["versions"],
            "buildDate": self.meta["build_date"],
            "upstreamRevision": {"pokeapi": cfg.POKEAPI_SHA, "sprites": cfg.SPRITES_SHA},
            "learnsetVersionGroups": self.notes.get("learnset_version_groups", []),
            "missingArtwork": [],
        }
        cfg.MANIFEST_PATH.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
        return counts


def main(argv: list[str] | None = None) -> int:
    cfg.assert_utf8_env()
    builder = Builder()
    counts = builder.build()
    db_size = cfg.DB_PATH.stat().st_size
    print("[build_db] 各表行数:")
    for t in TABLE_ORDER:
        print(f"  {t:22s} {counts[t]:>8}")
    print(f"[build_db] {cfg.DB_PATH} ({db_size / 1024 / 1024:.1f} MB)")
    print(f"[build_db] manifest -> {cfg.MANIFEST_PATH}")
    if db_size > 45 * 1024 * 1024:
        print("[build_db][error] db 体积超过 45MB 上限")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
