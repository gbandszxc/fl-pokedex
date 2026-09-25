# tools/ — 数据构建与宿主测试支撑

## 目录

```
tools/
├── data_builder/            # 数据构建管线（上游 → 应用打包资源）
│   ├── config.py            # 全局配置；上游 commit sha 硬编码锁定
│   ├── fetch_data.py        # 下载锁定 sha 的 data/v2/csv/*.csv 到 .cache/
│   ├── build_db.py          # 解析/清洗 → assets/database/pokedex.db + manifest.json
│   ├── process_images.py    # official-artwork → assets/pokemon/{full,thumb}/*.webp
│   ├── verify.py            # docs/data-contract.md §8 全部 10 条校验
│   ├── build_all.py         # 编排：fetch → build_db → process_images → verify
│   └── .cache/              # 上游原始数据缓存（gitignore，可随时删除重建）
└── README.md
```

另见仓库根 `tool/sqlite3/windows/sqlite3.dll`（Windows 宿主跑 drift 测试所需，构建期一次性下载入库，勿删）。

## 使用

PowerShell / Git Bash（Windows）：

```bash
export PYTHONUTF8=1

# 全量构建（首次或上游更新后；数据已在 .cache 时跳过重复下载）
uv run tools/data_builder/build_all.py

# 只校验现有产物
uv run tools/data_builder/verify.py

# 刷新上游到 master 最新 commit 并全量重建（会回写 config.py 中的 sha）
uv run tools/data_builder/build_all.py --latest

# 忽略缓存强制重新下载
uv run tools/data_builder/build_all.py --force
```

单个脚本也可独立执行（均带 PEP 723 内联依赖声明，由 uv 自动解析）：

```bash
uv run tools/data_builder/fetch_data.py            # 只下载 CSV
uv run tools/data_builder/build_db.py              # 只构建数据库
uv run tools/data_builder/process_images.py        # 只处理图片
```

## 产物（写入 assets/）

| 产物 | 说明 |
|---|---|
| `assets/database/pokedex.db` | SQLite，DDL 见 `docs/data-contract.md` §3 |
| `assets/database/manifest.json` | 数据版本清单（契约 §0），UI 启动时读取 |
| `assets/pokemon/full/{form_id}.webp` | 立绘，最长边 400px，q76 |
| `assets/pokemon/thumb/{form_id}.webp` | 缩略图，最长边 192px，q72，仅 is_default 形态 |

体积参考：db ≈ 43MB，图片 ≈ 32MB（full 1351 张 + thumb 1025 张）。

## 上游版本锁定

`config.py` 中硬编码两个 commit sha（首次构建时取 master 最新）：

- `POKEAPI_SHA` — PokeAPI/pokeapi（数据 CSV）
- `SPRITES_SHA` — PokeAPI/sprites（official-artwork）

`--latest` 会通过 GitHub API（限流时回退 `gh` CLI）获取最新 sha 并**回写 `config.py`**，保证“当前构建可重复”。想长期钉住某个版本，把 sha 手动改回即可。

## 缓存与增量（重要边界）

- 缓存键是**文件名**（`.cache/csv/*.csv`、`.cache/sprites/{id}.png`），判断逻辑为“已存在且非空即跳过”，与 sha 无关：
  - **同版本重复打包**：0 下载，只剩本地 CPU 工作（SQLite 重建 + WebP 重编码，全量约 20-60 秒）。
  - **升级上游版本（`--latest` 后）**：旧缓存仍会命中，拉不到新数据——**必须 `build_all.py --force` 全量重拉**（约 200MB，一次性几分钟）。这是有意保留的简单策略；如需按 sha/内容哈希的真增量，改动只在 `fetch_data.py` 的缓存键。
- 删除 `.cache` 或在全新机器/CI 上构建会自动全量下载一次，无需手工干预。

## 构建期约定（重要）

- 语言映射、代表版本组、形态中文名规则等全部以 `docs/data-contract.md` 为准；契约与实现的任何偏差都记录在 `meta` 表（`missing_json`、`learnset_vg_fallback` 等 key）。
- 上游缺失的官方简中（部分形态名/暗影招式名）按契约以英文回退并在 meta 记录清单，**禁止机翻补齐**。
- 无简中图鉴说明的 species（303 只，多为 1-5 世代）记录在 `meta.missing_json.species_without_zh_hans_flavor`，UI 需标注“暂无简体中文资料”。
- the-indigo-disk 在上游 `pokemon_moves.csv` 尚无数据，学习集第 9 世代代表组自动回退 `scarlet-violet`（`meta.learnset_vg_fallback` 有记录）；上游补数据后 `--latest` 重建即自动切回。
