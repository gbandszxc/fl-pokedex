# -*- coding: utf-8 -*-
# /// script
# requires-python = ">=3.10"
# dependencies = []
# ///
"""契约 §8 构建校验：对生成的 pokedex.db / manifest.json 断言，全绿退出码 0。

用法：export PYTHONUTF8=1 && uv run tools/data_builder/verify.py
"""

from __future__ import annotations

import csv
import json
import sqlite3
import sys
from pathlib import Path

import build_db as bdb
import config as cfg

DB_META_KEYS_REQUIRED = (
    "schema_version", "upstream_pokeapi_sha", "upstream_sprites_sha", "row_counts",
)
LEARNSET_SAMPLE_SPECIES = (1, 25, 133)  # 妙蛙种子 / 皮卡丘 / 伊布
SAMPLE_VGS = ("yellow", "sword-shield")  # the-indigo-disk 允许被回退


class Checks:
    def __init__(self) -> None:
        self.failed: list[str] = []

    def check(self, name: str, ok: bool, detail: str = "") -> None:
        mark = "PASS" if ok else "FAIL"
        line = f"[{mark}] {name}" + (f" — {detail}" if detail else "")
        print(line)
        if not ok:
            self.failed.append(name)


def main(argv: list[str] | None = None) -> int:
    cfg.assert_utf8_env()
    c = Checks()
    if not cfg.DB_PATH.exists():
        print(f"[FAIL] 数据库不存在: {cfg.DB_PATH}")
        return 1
    conn = sqlite3.connect(cfg.DB_PATH)
    conn.row_factory = sqlite3.Row
    q = conn.execute
    meta = dict(q("SELECT key, value FROM meta").fetchall())

    # ---- 0. 基线：meta 与 manifest 存在 ----
    for key in DB_META_KEYS_REQUIRED:
        c.check(f"meta.{key} 存在", key in meta)
    manifest = json.loads(cfg.MANIFEST_PATH.read_text(encoding="utf-8"))
    for field in ("schemaVersion", "dataVersion", "pokemonCount", "formCount", "moveCount",
                  "abilityCount", "versionCount", "buildDate", "upstreamRevision",
                  "learnsetVersionGroups", "missingArtwork"):
        c.check(f"manifest.{field} 存在", field in manifest)

    # ---- 1. species==1025；forms ≥ species；每 species 有 is_default form ----
    n_species = q("SELECT COUNT(*) FROM species").fetchone()[0]
    n_forms = q("SELECT COUNT(*) FROM forms").fetchone()[0]
    c.check("§8.1 species 行数 == 1025", n_species == 1025, f"实际 {n_species}")
    c.check("§8.1 forms ≥ species", n_forms >= n_species, f"{n_forms} vs {n_species}")
    orphan_default = q(
        "SELECT COUNT(*) FROM species s WHERE (SELECT COUNT(*) FROM forms f "
        "WHERE f.species_id = s.id AND f.is_default = 1) <> 1").fetchone()[0]
    c.check("§8.1 每 species 恰有 1 个 is_default 形态", orphan_default == 0,
            f"异常 {orphan_default} 个")

    # ---- 1b. forms 图片路径回填完整（process_images 语义：NULL ⇔ 缺图且已记录）----
    missing_list = list(manifest.get("missingArtwork", []))
    null_art = {r[0] for r in q(
        "SELECT id FROM forms WHERE artwork_asset IS NULL").fetchall()}
    c.check("§8.1 artwork_asset 为 NULL 的形态 == manifest.missingArtwork",
            null_art == set(missing_list),
            f"NULL {len(null_art)} 个 vs 记录 {len(missing_list)} 个")
    # 回填语义：非缺图（artwork 非空）的默认形态必带 thumb_asset；
    # 防止 build_db 后漏跑 process_images 导致全库 NULL 静默通过。
    broken_thumb = q("SELECT COUNT(*) FROM forms WHERE is_default = 1 "
                     "AND thumb_asset IS NULL AND artwork_asset IS NOT NULL").fetchone()[0]
    c.check("§8.1 默认形态 thumb_asset 无漏回填", broken_thumb == 0,
            f"异常 {broken_thumb} 个")

    # ---- 2. 每 species ≥1 条 zh_hans flavor（species 级 ∪ 地区形态级）或已记录到 meta ----
    no_zh_flavor = [r[0] for r in q(
        "SELECT s.id FROM species s WHERE NOT EXISTS "
        "(SELECT 1 FROM flavor_texts ft WHERE ft.species_id = s.id AND ft.language = 'zh_hans') "
        "AND NOT EXISTS "
        "(SELECT 1 FROM form_flavor_texts ff JOIN forms f ON f.id = ff.form_id "
        " WHERE f.species_id = s.id AND ff.language = 'zh_hans')"
    ).fetchall()]
    recorded = json.loads(meta.get("missing_json", "{}")).get(
        "species_without_zh_hans_flavor", [])
    c.check("§8.2 无简中 flavor 的 species 全部记录于 meta",
            sorted(no_zh_flavor) == sorted(recorded),
            f"未覆盖 {len(no_zh_flavor)}，已记录 {len(recorded)}")

    # ---- 3. 妙蛙种子：四语名称、草/毒、种族值 ----
    row = q("SELECT name_zh_hans, name_zh_hant, name_en, name_ja, name_ja_hrkt, genus_zh_hans "
            "FROM species WHERE id = 1").fetchone()
    c.check("§8.3 妙蛙种子 四语名称",
            row["name_zh_hans"] == "妙蛙种子" and row["name_en"] == "Bulbasaur"
            and row["name_ja"] == "フシギダネ" and bool(row["name_zh_hant"])
            and bool(row["name_ja_hrkt"]),
            f"{row['name_zh_hans']}/{row['name_en']}/{row['name_ja']}")
    types1 = [r[0] for r in q(
        "SELECT t.name_zh_hans FROM form_types ft JOIN types t ON t.id = ft.type_id "
        "WHERE ft.form_id = 1 ORDER BY ft.slot").fetchall()]
    c.check("§8.3 妙蛙种子 属性 草/毒", types1 == ["草", "毒"], str(types1))
    stats1 = dict(q("SELECT stat, base_value FROM form_stats WHERE form_id = 1").fetchall())
    expect = {"hp": 45, "attack": 49, "defense": 49,
              "special_attack": 65, "special_defense": 65, "speed": 45}
    c.check("§8.3 妙蛙种子 种族值 45/49/49/65/65/45", stats1 == expect, str(stats1))

    # ---- 4. 伊布进化链：根 + 8 出边 ----
    chain = q("SELECT evolution_chain_id FROM species WHERE id = 133").fetchone()[0]
    root_row = q("SELECT root_species_id FROM evolution_chains WHERE id = ?", (chain,)).fetchone()
    c.check("§8.4 伊布为链根", root_row and root_row[0] == 133, f"root={root_row[0] if root_row else None}")
    root_self = q("SELECT COUNT(*) FROM evolution_edges WHERE chain_id = ? "
                  "AND from_species_id IS NULL AND to_species_id = 133", (chain,)).fetchone()[0]
    out_edges = q("SELECT trigger, min_level, item, held_item, known_move, known_move_type, "
                  "location, time_of_day, min_happiness FROM evolution_edges "
                  "WHERE chain_id = ? AND from_species_id = 133", (chain,)).fetchall()
    c.check("§8.4 根节点自指行存在（from NULL → 133）", root_self == 1)
    c.check("§8.4 伊布出边 8 条", len(out_edges) == 8, f"实际 {len(out_edges)}")
    c.check("§8.4 出边均带 trigger/条件字段",
            all(e["trigger"] and any(e[k] is not None for k in
                ("min_level", "item", "held_item", "known_move", "known_move_type",
                 "location", "time_of_day", "min_happiness")) for e in out_edges),
            f"triggers={sorted({e['trigger'] for e in out_edges})}")

    # ---- 5. 皮卡丘：形态数与默认形态身高体重 ----
    n_pika = q("SELECT COUNT(*) FROM forms WHERE species_id = 25").fetchone()[0]
    c.check("§8.5 皮卡丘 forms ≥ 6", n_pika >= 6, f"实际 {n_pika}")
    h, w = q("SELECT height, weight FROM forms WHERE id = 25").fetchone()
    c.check("§8.5 皮卡丘默认形态 height=4 weight=60", (h, w) == (4, 60), f"{h}/{w}")

    # ---- 6. 分支进化 + shed 边 ----
    slowpoke_branches = q(
        "SELECT to_species_id FROM evolution_edges WHERE from_species_id = 79").fetchall()
    c.check("§8.6 slowpoke 分支进化 ≥2（slowbro/slowking）", len(slowpoke_branches) >= 2,
            str([r[0] for r in slowpoke_branches]))
    shed = q("SELECT from_species_id, to_species_id FROM evolution_edges "
             "WHERE trigger = 'shed'").fetchone()
    c.check("§8.6 土居忍士 shed 边存在（290→292）",
            shed is not None and shed[0] == 290 and shed[1] == 292, str(tuple(shed) if shed else None))

    # ---- 7. 招式 ≥900 且 name_zh_hans 非空 ----
    n_moves = q("SELECT COUNT(*) FROM moves").fetchone()[0]
    c.check("§8.7 moves ≥ 900", n_moves >= 900, f"实际 {n_moves}")
    empty_zh = q("SELECT COUNT(*) FROM moves WHERE name_zh_hans IS NULL "
                 "OR trim(name_zh_hans) = ''").fetchone()[0]
    fallback_moves = json.loads(meta.get("missing_json", "{}")).get(
        "missing_move_name_zh_hans", [])
    c.check("§8.7 每招式 name_zh_hans 非空（缺失者以英文回退并记 meta）",
            empty_zh == 0 and len(fallback_moves) > 0,
            f"空名 {empty_zh} 个，英文回退 {len(fallback_moves)} 个")

    # ---- 7b. 伤害分类（A2 回归：PokeAPI 1=status, 2=physical, 3=special）----
    known = {  # identifier -> (damage_class, power 或 None)
        "tackle": ("physical", 40), "growl": ("status", None),
        "thunderbolt": ("special", 90), "hypnosis": ("status", None),
    }
    for ident, (dc, power) in known.items():
        row = q("SELECT id, damage_class, power FROM moves WHERE identifier = ?",
                (ident,)).fetchone()
        ok = (row is not None and row["damage_class"] == dc
              and (power is None or row["power"] == power))
        c.check(f"§8.7b {ident} → {dc}" + (f"(威力{power})" if power else ""),
                ok, f"{tuple(row) if row else '缺失'}")
    # 三类分布与上游 CSV 按 id 重算对比（防再次错位）
    csv_moves = cfg.CACHE_CSV_DIR / "moves.csv"
    csv_dc = cfg.CACHE_CSV_DIR / "move_damage_classes.csv"
    if csv_moves.exists() and csv_dc.exists():
        import csv as _csv
        with open(csv_dc, encoding="utf-8", newline="") as f:
            dc_names = {r["id"]: r["identifier"] for r in _csv.DictReader(f)}
        expect_dist: dict[str, int] = {}
        with open(csv_moves, encoding="utf-8", newline="") as f:
            for r in _csv.DictReader(f):
                name = dc_names[r["damage_class_id"]]
                expect_dist[name] = expect_dist.get(name, 0) + 1
        actual = dict(q("SELECT damage_class, COUNT(*) FROM moves "
                        "GROUP BY damage_class").fetchall())
        c.check("§8.7b 三类分布与上游 CSV 按 id 复核一致",
                actual == expect_dist, f"db={actual} 上游={expect_dist}")
    else:
        c.check("§8.7b 三类分布与上游 CSV 按 id 复核一致", False,
                "缺少 .cache/csv/{moves,move_damage_classes}.csv，请先运行 fetch_data.py")

    # ---- 8. 学习集：3 只样本 × 版本组 ----
    vgs = json.loads(meta.get("learnset_version_groups", "[]"))
    c.check("§8.8 meta.learnset_version_groups 共 9 组", len(vgs) == 9, str(vgs))
    gen9_vg = "the-indigo-disk" if "the-indigo-disk" in vgs else "scarlet-violet"
    sample_vgs = list(SAMPLE_VGS) + [gen9_vg]
    for sid in LEARNSET_SAMPLE_SPECIES:
        for vg in sample_vgs:
            n = q("SELECT COUNT(*) FROM pokemon_form_moves WHERE form_id = ? "
                  "AND version_group = ?", (sid, vg)).fetchone()[0]
            c.check(f"§8.8 form {sid} × {vg} 学习集有数据", n > 0, f"{n} 行")
    methods = {r[0] for r in q(
        "SELECT DISTINCT method FROM pokemon_form_moves WHERE form_id = 25").fetchall()}
    c.check("§8.8 method 取值符合契约枚举",
            methods <= {"level_up", "egg", "machine", "tutor", "other"}, str(sorted(methods)))

    # ---- 9. 外键完整性 ----
    fk_cases = [
        ("forms.species_id → species",
         "SELECT COUNT(*) FROM forms f LEFT JOIN species s ON s.id = f.species_id WHERE s.id IS NULL"),
        ("form_types.form_id → forms",
         "SELECT COUNT(*) FROM form_types x LEFT JOIN forms f ON f.id = x.form_id WHERE f.id IS NULL"),
        ("form_types.type_id → types",
         "SELECT COUNT(*) FROM form_types x LEFT JOIN types t ON t.id = x.type_id WHERE t.id IS NULL"),
        ("form_stats.form_id → forms",
         "SELECT COUNT(*) FROM form_stats x LEFT JOIN forms f ON f.id = x.form_id WHERE f.id IS NULL"),
        ("form_abilities.form_id → forms",
         "SELECT COUNT(*) FROM form_abilities x LEFT JOIN forms f ON f.id = x.form_id WHERE f.id IS NULL"),
        ("form_abilities.ability_id → abilities",
         "SELECT COUNT(*) FROM form_abilities x LEFT JOIN abilities a ON a.id = x.ability_id WHERE a.id IS NULL"),
        ("pokemon_form_moves.form_id → forms",
         "SELECT COUNT(*) FROM pokemon_form_moves x LEFT JOIN forms f ON f.id = x.form_id WHERE f.id IS NULL"),
        ("pokemon_form_moves.move_id → moves",
         "SELECT COUNT(*) FROM pokemon_form_moves x LEFT JOIN moves m ON m.id = x.move_id WHERE m.id IS NULL"),
        ("flavor_texts.species_id → species",
         "SELECT COUNT(*) FROM flavor_texts x LEFT JOIN species s ON s.id = x.species_id WHERE s.id IS NULL"),
        ("flavor_texts.version_id → versions",
         "SELECT COUNT(*) FROM flavor_texts x LEFT JOIN versions v ON v.id = x.version_id WHERE v.id IS NULL"),
        ("form_flavor_texts.form_id → forms（且 is_regional=1）",
         "SELECT COUNT(*) FROM form_flavor_texts x LEFT JOIN forms f ON f.id = x.form_id "
         "WHERE f.id IS NULL OR f.is_regional <> 1"),
        ("form_flavor_texts.version_id → versions",
         "SELECT COUNT(*) FROM form_flavor_texts x LEFT JOIN versions v ON v.id = x.version_id WHERE v.id IS NULL"),
        ("evolution_edges.chain_id → evolution_chains",
         "SELECT COUNT(*) FROM evolution_edges x LEFT JOIN evolution_chains c ON c.id = x.chain_id WHERE c.id IS NULL"),
        ("evolution_edges.to_species_id → species",
         "SELECT COUNT(*) FROM evolution_edges x LEFT JOIN species s ON s.id = x.to_species_id WHERE s.id IS NULL"),
        ("evolution_edges.from_species_id → species(或 NULL)",
         "SELECT COUNT(*) FROM evolution_edges x LEFT JOIN species s ON s.id = x.from_species_id "
         "WHERE x.from_species_id IS NOT NULL AND s.id IS NULL"),
        ("species_dex_numbers.pokedex_id → pokedexes",
         "SELECT COUNT(*) FROM species_dex_numbers x LEFT JOIN pokedexes p ON p.id = x.pokedex_id WHERE p.id IS NULL"),
        ("species_dex_numbers.species_id → species",
         "SELECT COUNT(*) FROM species_dex_numbers x LEFT JOIN species s ON s.id = x.species_id WHERE s.id IS NULL"),
    ]
    for name, sql in fk_cases:
        n = q(sql).fetchone()[0]
        c.check(f"§8.9 {name}", n == 0, f"悬空 {n} 行")
    bad_vg = q("SELECT COUNT(*) FROM pokemon_form_moves WHERE version_group NOT IN "
               f"({','.join('?' * len(vgs))})", vgs).fetchone()[0]
    c.check("§8.9 pokemon_form_moves.version_group ∈ 收录组", bad_vg == 0, f"越界 {bad_vg} 行")

    # ---- 10. 地区图鉴覆盖 ----
    zh_names = {r[0] for r in q("SELECT DISTINCT name_zh_hans FROM pokedexes").fetchall()}
    for region, zh in cfg.REGION_DEX_ZH.items():
        expected = f"{zh}图鉴"
        c.check(f"§8.10 图鉴含地区 {region}（{expected}）", expected in zh_names)
    empty_dexes = q(
        "SELECT p.identifier FROM pokedexes p WHERE NOT EXISTS "
        "(SELECT 1 FROM species_dex_numbers n WHERE n.pokedex_id = p.id)").fetchall()
    c.check("§8.10 每个收录图鉴均有成员", len(empty_dexes) == 0,
            f"空图鉴 {[r[0] for r in empty_dexes]}")
    kanto = q("SELECT COUNT(*) FROM species_dex_numbers WHERE pokedex_id = "
              "(SELECT id FROM pokedexes WHERE identifier = 'kanto')").fetchone()[0]
    c.check("§8.10 关都图鉴 151 只", kanto == 151, f"实际 {kanto}")

    # ---- 11. 地区形态文本归属（契约 §6：地区图鉴登记的是地区形态）----
    # 11a. flavor_texts ∪ form_flavor_texts 与归属前的 species 文本集合一一对应
    lang_map = {int(k): v for k, v in cfg.LANGUAGE_MAP.items()}
    kept_langs = {"zh_hans", "zh_hant", "en", "ja"}
    csv_flavor = cfg.CACHE_CSV_DIR / "pokemon_species_flavor_text.csv"
    if csv_flavor.exists():
        before: set[tuple] = set()
        seen: set[tuple] = set()
        with open(csv_flavor, encoding="utf-8", newline="") as f:
            for r in csv.DictReader(f):
                lang = lang_map.get(int(r["language_id"]))
                if lang not in kept_langs:
                    continue
                key = (int(r["species_id"]), int(r["version_id"]), lang)
                if key in seen:  # 与构建侧同规则去重
                    continue
                seen.add(key)
                text = bdb.clean_flavor(r["flavor_text"])
                if text:
                    before.add((*key, text))
        after = {
            (r[0], r[1], r[2], r[3]) for r in q(
                "SELECT species_id, version_id, language, flavor_text FROM flavor_texts"
            ).fetchall()
        } | {
            (r[0], r[1], r[2], r[3]) for r in q(
                "SELECT f.species_id, ff.version_id, ff.language, ff.flavor_text "
                "FROM form_flavor_texts ff JOIN forms f ON f.id = ff.form_id"
            ).fetchall()
        }
        only_before = sorted(before - after)[:3]
        only_after = sorted(after - before)[:3]
        c.check("§8.11a flavor_texts ∪ form_flavor_texts == 归属前 species 文本集合（不多不少）",
                before == after,
                f"归属前 {len(before)} / 归属后 {len(after)}"
                + (f"；仅归属前 {only_before}" if only_before else "")
                + (f"；仅归属后 {only_after}" if only_after else ""))

        # 11b. 呆呆兽(79)：剑/盾文本归属伽勒尔形态，species 级不再有剑/盾行
        slowpoke_galar = q(
            "SELECT id FROM forms WHERE species_id = 79 AND form_identifier = 'galar' "
            "AND is_regional = 1").fetchall()
        c.check("§8.11b 呆呆兽存在伽勒尔形态（唯一）", len(slowpoke_galar) == 1,
                f"{[r[0] for r in slowpoke_galar]}")
        if len(slowpoke_galar) == 1:
            galar_id = slowpoke_galar[0][0]
            ff_sword = q(
                "SELECT v.identifier, ff.flavor_text FROM form_flavor_texts ff "
                "JOIN versions v ON v.id = ff.version_id "
                "WHERE ff.form_id = ? AND ff.language = 'zh_hans' "
                "AND v.identifier IN ('sword', 'shield')", (galar_id,)).fetchall()
            c.check("§8.11b 呆呆兽剑/盾简中文本在伽勒尔形态名下",
                    {r[0] for r in ff_sword} == {"sword", "shield"},
                    f"命中 {sorted(r[0] for r in ff_sword)}")
            ft_sword = q(
                "SELECT v.identifier FROM flavor_texts ft "
                "JOIN versions v ON v.id = ft.version_id "
                "WHERE ft.species_id = 79 AND v.identifier IN ('sword', 'shield')").fetchall()
            c.check("§8.11b flavor_texts 已无呆呆兽剑/盾行（任何语言）",
                    not ft_sword, f"残留 {[r[0] for r in ft_sword]}")
            # species 级仍保留非伽勒尔版本（描述默认形态）
            ft_kept = q(
                "SELECT v.identifier FROM flavor_texts ft "
                "JOIN versions v ON v.id = ft.version_id WHERE ft.species_id = 79").fetchall()
            c.check("§8.11b 呆呆兽 species 级仍保留非剑/盾文本", len(ft_kept) > 0,
                    f"{[r[0] for r in ft_kept]}")

        # 11c. 喵喵(52)：sun/moon/ultra 系→阿罗拉；剑/盾→伽勒尔；lets-go 及更早→默认形态
        meowth = {r[0]: r[1] for r in q(
            "SELECT form_identifier, id FROM forms WHERE species_id = 52 "
            "AND is_regional = 1 AND form_identifier IN ('alola', 'galar')").fetchall()}
        c.check("§8.11c 喵喵存在阿罗拉+伽勒尔形态", set(meowth) == {"alola", "galar"},
                str(meowth))
        if set(meowth) == {"alola", "galar"}:

            def ff_has(form_id: int, version: str) -> bool:
                return q("SELECT 1 FROM form_flavor_texts ff "
                         "JOIN versions v ON v.id = ff.version_id "
                         "WHERE ff.form_id = ? AND ff.language = 'zh_hans' "
                         "AND v.identifier = ?", (form_id, version)).fetchone() is not None

            def ft_has(version: str) -> bool:
                return q("SELECT 1 FROM flavor_texts ft "
                         "JOIN versions v ON v.id = ft.version_id "
                         "WHERE ft.species_id = 52 AND ft.language = 'zh_hans' "
                         "AND v.identifier = ?", (version,)).fetchone() is not None

            alola_ok = all(ff_has(meowth['alola'], v) and not ft_has(v)
                           for v in ("sun", "moon", "ultra-sun", "ultra-moon"))
            c.check("§8.11c 喵喵 sun/moon/ultra 系简中文本归阿罗拉形态",
                    alola_ok, f"alola 形态 id={meowth['alola']}")
            galar_ok = (ff_has(meowth['galar'], 'sword') and ff_has(meowth['galar'], 'shield')
                        and not ft_has('sword') and not ft_has('shield'))
            c.check("§8.11c 喵喵剑/盾简中文本归伽勒尔形态",
                    galar_ok, f"galar 形态 id={meowth['galar']}")
            lets_go = q(
                "SELECT v.identifier FROM flavor_texts ft "
                "JOIN versions v ON v.id = ft.version_id "
                "WHERE ft.species_id = 52 AND ft.language = 'zh_hans' "
                "AND v.identifier IN ('lets-go-pikachu', 'lets-go-eevee')").fetchall()
            c.check("§8.11c 喵喵 lets-go 简中文本留在 species 级（关都=默认形态）",
                    {r[0] for r in lets_go} == {"lets-go-pikachu", "lets-go-eevee"},
                    f"{sorted(r[0] for r in lets_go)}")
            # gen<7 无官方简中（官方简中自 sun/moon 起），改用任意语言断言：
            # 更早版本文本全部留在 species 级，且从未归属到地区形态名下
            early_ff = q(
                "SELECT COUNT(*) FROM form_flavor_texts ff "
                "JOIN versions v ON v.id = ff.version_id "
                "WHERE ff.form_id IN (?, ?) AND v.generation_id < 7",
                (meowth['alola'], meowth['galar'])).fetchone()[0]
            early_ft = q(
                "SELECT COUNT(*) FROM flavor_texts ft "
                "JOIN versions v ON v.id = ft.version_id "
                "WHERE ft.species_id = 52 AND v.generation_id < 7").fetchone()[0]
            c.check("§8.11c 喵喵第 7 世代前文本留在 species 级（默认形态）",
                    early_ff == 0 and early_ft > 0,
                    f"species 级 {early_ft} 行，误归属 {early_ff} 行")

        # 11d. 归属只针对地区形态：form_flavor_texts 的 form 全部 is_regional=1
        # 且 form_identifier 恰为地区名（不含 mega/gmax 等其他形态）
        bad_form = q(
            "SELECT COUNT(*) FROM form_flavor_texts ff JOIN forms f ON f.id = ff.form_id "
            "WHERE f.is_regional <> 1 OR f.form_identifier NOT IN ('alola','galar','hisui','paldea')"
        ).fetchone()[0]
        c.check("§8.11d form_flavor_texts 只挂地区形态", bad_form == 0, f"异常 {bad_form} 行")

    conn.close()

    print()
    if c.failed:
        print(f"[verify] 失败 {len(c.failed)} 项: {c.failed}")
        return 1
    print("[verify] 全部校验通过 ✔")
    return 0


if __name__ == "__main__":
    sys.exit(main())
