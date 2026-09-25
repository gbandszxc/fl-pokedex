# THIRD_PARTY_NOTICES

本项目（应用代码、UI、组件、视觉语言）为原创，以 MIT 许可发布（见 LICENSE）。

## 数据来源

- **PokéAPI**（https://github.com/PokeAPI/pokeapi）— 构建期从其 `data/v2/csv` 版本化数据快照提取并清洗生成 `assets/database/pokedex.db`。
  - 上游 revision：见 `assets/database/manifest.json` 的 `upstreamRevision.pokeapi`。
  - 许可：BSD-3-Clause（上游仓库 LICENSE；数据构建脚本使用者请一并遵守）。
- **PokéAPI/sprites**（https://github.com/PokeAPI/sprites）— 官方立绘（official artwork）压缩为本地 WebP 资源。
  - 上游 revision：见 `manifest.json` 的 `upstreamRevision.sprites`。
  - 图片版权：© Nintendo / Creatures Inc. / GAME FREAK inc. / Pokémon。仅为非商业粉丝用途随应用本地分发，本项目不主张对这些图片的任何权利。

## 运行时依赖

以下为核心依赖（完整清单以 `pubspec.lock` 为准），均为 MIT/BSD/Apache 系许可：

| 包 | 用途 | 许可 |
|---|---|---|
| flutter_riverpod | 状态管理 | MIT |
| go_router | 声明式路由 | BSD-3-Clause |
| drift / drift_dev | SQLite ORM | MIT |
| sqlite3_flutter_libs | 内置 SQLite | MIT? （以包内 LICENSE 为准） |
| shared_preferences | 用户偏好 | BSD-3-Clause |
| path_provider / path | 平台路径 | BSD-3-Clause |
| freezed / json_serializable | 代码生成 | MIT |

构建期工具（不入应用）：Python + uv、requests、Pillow（HPND 许可，见 Pillow 仓库）。

## 素材

- 应用图标 / Logo：本项目原创（tools/data_builder 生成）。
- 无第三方字体打包（使用系统字体回退链）。

## 商标声明

Pokémon 及宝可梦相关名称、角色、立绘等知识产权归其对应权利方（Nintendo、Creatures Inc.、GAME FREAK inc. 等）所有。本项目与其无 affiliation，不提供任何商业用途。
