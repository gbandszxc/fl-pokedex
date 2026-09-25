# 数据契约（tools/data_builder ↔ lib/data 唯一事实来源）

上游：PokeAPI 主仓库 `data/v2/csv`（版本锁定 commit）+ PokeAPI/sprites 仓库（版本锁定 commit）。
构建期允许联网；**应用运行期 0 网络请求**。

## 0. 构建产物

```
assets/database/pokedex.db      # SQLite，见下方 DDL
assets/database/manifest.json
assets/pokemon/full/{pokemon_id}.webp    # 立绘，最长边 400px，q76
assets/pokemon/thumb/{pokemon_id}.webp   # 缩略图，最长边 192px，q72（仅 is_default 形态）
```

manifest.json：

```json
{
  "schemaVersion": 1,
  "dataVersion": "pokeapi@<short-sha>",
  "pokemonCount": 1025,
  "formCount": 0,
  "moveCount": 0,
  "abilityCount": 0,
  "versionCount": 0,
  "buildDate": "<ISO8601>",
  "upstreamRevision": { "pokeapi": "<full-sha>", "sprites": "<full-sha>" },
  "learnsetVersionGroups": ["yellow","crystal","emerald","heartgold-soulsilver","black-2-white-2","omega-ruby-alpha-sapphire","ultra-sun-ultra-moon","sword-shield","the-indigo-disk"],
  "missingArtwork": []
}
```

两个上游 commit sha 在首次构建时获取并**硬编码**进 `tools/data_builder/config.py`（可重复构建）；提供 `--latest` 参数刷新。

## 1. ID 对齐（极重要）

- `species.id` = PokeAPI `pokemon_species.csv` id（1..1025）；`national_dex` 同 id。
- `forms.id` = PokeAPI `pokemon.csv`（variety）id（默认形态 id 与 species id 相同；特殊形态 ≥10001）。
- `types/abilities/moves/versions/pokedexes/evolution_chains` 直接沿用 PokeAPI id。
- 图片命名用 **forms.id**（即 variety id）。

## 2. 语言映射（PokeAPI language_id → 本项目 language）

`4→zh_hant, 9→en, 11→ja, 12→zh_hans, 1→ja_hrkt, 2→roomaji`。
名称缺失处理：`name_roomaji` 可空；其余四语（zh_hans/zh_hant/en/ja）对 1025 只全量存在（pokemon_species_names.csv 已保证；若个别缺失用英文回退并在 meta 表记录）。
`genus_zh_hans`（分类，如“种子宝可梦”）取 pokemon_species_names.genus。

## 3. DDL（生成到 pokedex.db，drift 端按此逐列对齐，列名全部 snake_case）

```sql
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

CREATE TABLE pokedexes(
  id INTEGER PRIMARY KEY, identifier TEXT NOT NULL UNIQUE,
  name_zh_hans TEXT NOT NULL, generation_id INTEGER);

CREATE TABLE species_dex_numbers(
  pokedex_id INTEGER NOT NULL, species_id INTEGER NOT NULL, dex_number INTEGER NOT NULL,
  PRIMARY KEY(pokedex_id, species_id));
CREATE INDEX idx_sdn_species ON species_dex_numbers(species_id);
```

## 4. 学习集代表性版本组（每世代一个，写入 pokemon_form_moves.version_group）

| 世代 | version_group |
|---|---|
| 1 | yellow |
| 2 | crystal |
| 3 | emerald |
| 4 | heartgold-soulsilver |
| 5 | black-2-white-2 |
| 6 | omega-ruby-alpha-sapphire |
| 7 | ultra-sun-ultra-moon |
| 8 | sword-shield |
| 9 | the-indigo-disk（若上游无此组数据则回退 scarlet-violet 并记录进 meta） |

method 映射：1→level_up, 2→egg, 3→machine, 4→tutor, 其余(5+)→other。
damage_class 映射**必须**从上游 `move_damage_classes.csv` 数据驱动（1=status, 2=physical, 3=special，禁止硬编码）；verify 断言 tackle=physical、thunderbolt=special、growl/hypnosis=status，且三类分布与上游按 id 重算一致。
进化边根节点行：from_species_id=NULL 且 trigger='root'。
构建时断言：每个代表性 version_group 在 pokemon_moves.csv 中确有数据。

## 5. 形态中文名映射（forms.form_name_zh）

identifier 后缀 → 官方中文：
`-alola→阿罗拉的样子 -galar→伽勒尔的样子 -hisui→洗翠的样子 -paldea→帕底亚的样子 -mega→超级进化 -mega-x→超级进化Ｘ -mega-y→超级进化Ｙ -gmax→超极巨化 -primal→原始回归 -origin→起源形态 -therian→灵兽形态 -black→阿勃梭鲁(霸主?)…`（以 pokemon_form_names.csv 的 language 12/4 官方数据为准，取不到时用“地区名+的样子”模板，仍无则回退英文并在 meta 记录缺失清单）。is_regional 判定 = form_identifier ∈ {alola,galar,hisui,paldea}(含 -battle 变体归并)；is_gmax = identifier 以 -gmax 结尾；is_mega = pokemon_forms.is_mega。

## 6. 图鉴说明（flavor_texts）

- 来源 `pokemon_species_flavor_text.csv`，只保留 language ∈ {zh_hans, zh_hant, en, ja} 四行/版本。
- 清洗：压平换行、去 U+0C/U+1C 控制符。
- versions 表收录全部游戏版本（含无简中文本的旧版本）；version_names.csv 提供官方简中版本名（剑/盾/朱/紫…；无官方简中的版本 name_zh_hans 留空）。
- **禁止生成/机翻“官方”文本**。缺简中由 UI 标注。

## 7. 图片

- 源：`sprites/pokemon/other/official-artwork/{forms.id}.png`（PokeAPI/sprites@锁定 sha）。
- 处理：Pillow → RGBA、白底去除不需要（官方立绘本底透明）、最长边 400px(full)/192px(thumb)、WebP q76/q72。
- 404 清单写入 manifest.missingArtwork，UI 回退该 species 默认形态图。
- thumbs 只为 is_default 形态生成；特殊形态仅 full。
- 断言：1025 只默认形态中缺图数量 < 10，否则构建失败。

## 8. 构建校验（verify.py 必须全绿才允许输出到 assets/）

1. species 行数 == 1025；forms ≥ species；每 species 有 is_default form。
2. 每只 species 至少 1 行 zh_hans flavor 或标记到 meta（不可静默丢弃）。
3. 妙蛙种子(#1)：zh=妙蛙种子，en=Bulbasaur，ja=フシギダネ，types=草/毒，6 项种族值 45/49/49/65/65/45。
4. 伊布(#133)进化链：eevee 为根，出边 8 条，各带 trigger/条件字段。
5. 皮卡丘(#25)：forms ≥ 6（含超级/超极巨/原始戴鲁比无…以实际为准），默认形态 height=4, weight=60。
6. 空手道王? 改为：吼爆弹/螺钉地鼠类分支进化（nuzleaf? 用 slowbro 线）验证 from→to 多分支存在；土居忍士 shed 边存在。
7. 招式：moves ≥ 900；每招式 name_zh_hans 非空（“极巨化招式”类除外，若上游缺失记 meta）。
8. 学习集：选取 3 只（妙蛙种子/皮卡丘/伊布）验证 yellow、sword-shield、the-indigo-disk 三组各 method 有行。
9. 外键完整性：form_types/form_stats/form_abilities/pokemon_form_moves/flavor_texts 的 id 全部可解析到父表。
10. pokedexes 含 region kanto..paldea；species_dex_numbers 覆盖全部地区图鉴成员。

输出结束时打印：各表行数、db 文件大小、图片数量与总体积。
