# 架构契约（lib/ 层次、接口签名、文件所有权）

多个子代理并行开发时的接口锁。**签名与文件路径不得擅改**；发现缺陷先回报主会话。

## 目录所有权（并行单元互不越界）

| 单元 | 独占路径 |
|---|---|
| C 数据层 | `lib/data/` `lib/core/db/` |
| D 设计系统 | `lib/shared/` `lib/app/theme/` |
| B 脚手架 | `lib/app/`(router/shell/main) `lib/domain/` `pubspec.yaml` |
| E 首页 | `lib/features/pokedex/` |
| F 详情 | `lib/features/pokemon_detail/` `lib/features/moves/` |
| G 设置收藏 | `lib/features/settings/` `lib/features/favorites/` |

公共依赖顺序：`shared → domain → data → features → app`。features 之间禁止互相 import。

## 1. 技术栈与依赖（pubspec 锁定范围）

```yaml
environment: { sdk: ">=3.5.0 <4.0.0" }
dependencies:
  flutter_riverpod: ^2.6.1
  go_router: ^14.6.0
  drift: ^2.28.0
  sqlite3_flutter_libs: ^0.5.26
  path_provider: ^2.1.5
  path: ^1.9.0
  shared_preferences: ^2.3.4
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  collection: ^1.19.0
dev_dependencies:
  build_runner: ^2.4.14
  drift_dev: ^2.28.0
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  flutter_lints: ^6.0.0   # 以 flutter create 生成版本为准
  flutter_test: {sdk: flutter}
```

**运行时依赖里禁止出现任何 HTTP 库**（dio/http/http 等）。版本以 `flutter pub get` 实际解析为准，允许向上浮动小版本，不允许降级大版本。

## 2. 响应式（lib/shared/responsive/）

```dart
enum WindowSize { compact, medium, expanded }
WindowSize windowSizeFor(double width);           // <600 compact, <840 medium, else expanded
bool twoPaneFor(double width);                    // >=1080 → master-detail
```

AppShell：compact → NavigationBar（图鉴/收藏/设置）；medium/expanded → NavigationRail；图鉴分支在 twoPane 时渲染 `HomeListPane + DetailPane`，否则点击跳路由 `/pokemon/:speciesId`。

## 3. 领域模型（lib/domain/models/，freezed；字段锁死）

```dart
// pokemon_summary.dart
PokemonSummary { int speciesId; int nationalDex; String nameZh; String nameEn; String nameJa;
  List<String> typeIds; String? thumbAsset; int generationId;
  bool isLegendary; bool isMythical; bool isUltraBeast; }
// form_summary.dart
FormSummary { int formId; int speciesId; String? formIdentifier; String formNameZh; String formNameEn;
  bool isDefault; bool isMega; bool isGmax; bool isRegional; String? artworkAsset; List<String> typeIds; }
// stat_block.dart
StatBlock { int hp; int attack; int defense; int specialAttack; int specialDefense; int speed;
  int get total; }   // 6 项 + 总和
// ability_ref.dart
AbilityRef { int id; String nameZh; String nameEn; bool isHidden; }
// flavor_entry.dart
FlavorEntry { int versionId; String versionIdentifier; String versionNameZh; String versionNameEn;
  int generationId; String language; String text; }   // language ∈ zh_hans/zh_hant/en/ja
// evolution.dart
EvolutionEdge { int chainId; int? fromSpeciesId; int toSpeciesId; String trigger; int? minLevel;
  String? item; String? heldItem; String? knownMove; String? knownMoveType; String? location;
  String? timeOfDay; String? gender; int? minHappiness; int? minAffection; int? minBeauty;
  String? relativePhysicalStats; String? partySpecies; String? partyType; String? tradeSpecies;
  bool needsRain; bool turnUpsideDown; }
EvolutionNode { int speciesId; int nationalDex; String nameZh; String? thumbAsset;
  List<EvolutionEdge> children; }
EvolutionTree { EvolutionNode root; }
// move_entry.dart
MoveEntry { int moveId; String nameZh; String nameEn; String typeId; String damageClass;
  int? power; int? pp; int? accuracy; int? level; String method; String versionGroup; }
// move_detail.dart
MoveDetail { int id; String nameZh; String nameEn; String nameJa; String typeId; String damageClass;
  int? power; int? pp; int? accuracy; int? priority; int? effectChance;
  String? effectEn; String? flavorZh; int generationId; }
// filters.dart
enum SpecialTag { legendary, mythical, ultraBeast, mega, gmax, regional }
enum TypeMatchMode { any, all }
FilterState { String query; Set<int> generations; Set<String> typeIds; TypeMatchMode typeMatchMode;
  Set<int> pokedexIds; int? dexMin; int? dexMax; Set<SpecialTag> tags;
  bool get isEmpty; }
// refs.dart
TypeRef { String id; String nameZh; }   // id 即 identifier（"fire"）
GenerationRef { int id; String identifier; String region; }
PokedexRef { int id; String identifier; String nameZh; int? generationId; }
VersionGroupRef { String id; String labelZh; int generationId; }
// manifest.dart (json_serializable)
DataManifest { int schemaVersion; String dataVersion; int pokemonCount; int formCount; int moveCount;
  int abilityCount; int versionCount; String buildDate;
  Map<String, dynamic> upstreamRevision; List<String> learnsetVersionGroups; List<int> missingArtwork; }
```

枚举与 DB 的字符串值一致（method/trigger/damage_class 等 snake_case 原样传递，不额外编码）。

## 4. 仓储接口（lib/domain/repositories/）

```dart
abstract class PokedexRepository {
  Future<List<PokemonSummary>> queryPokemon(FilterState f, {required int limit, required int offset});
  Future<int> countPokemon(FilterState f);
  Future<List<FormSummary>> getForms(int speciesId);
  Future<StatBlock> getFormStats(int formId);
  Future<List<AbilityRef>> getFormAbilities(int formId);
  Future<List<FlavorEntry>> getFlavorTexts(int speciesId);          // zh 优先排序在 UI 做
  Future<EvolutionTree?> getEvolutionTree(int speciesId);           // 无进化链返回 null
  Future<List<VersionGroupRef>> getFormVersionGroups(int formId);   // 该形态有学习集的组，新→旧
  Future<List<MoveEntry>> getLearnset(int formId, String versionGroup, {Set<String>? methods});
  Future<MoveDetail?> getMoveDetail(int moveId);
  Future<List<TypeRef>> getTypes();
  Future<List<GenerationRef>> getGenerations();
  Future<List<PokedexRef>> getPokedexes();
  Future<DataManifest> getManifest();                               // 读 assets/database/manifest.json
}
abstract class FavoritesRepository {
  Stream<List<int>> watchFavoriteSpeciesIds();
  Future<void> toggleFavorite(int speciesId);
  Stream<List<int>> watchRecentSpeciesIds();
  Future<void> addRecent(int speciesId);                            // 上限 30，去重取最新
}
```

## 5. Riverpod Provider（命名锁死，跨文件引用）

```dart
// lib/core/di.dart
pokedexRepositoryProvider / favoritesRepositoryProvider / pokedexDatabaseProvider / userDatabaseProvider
// lib/features/pokedex/providers.dart
filterProvider: Notifier<FilterState>
pokemonListProvider: AsyncNotifier<PokemonPageState>   // {items, total, isLoadingMore}
listViewModeProvider: StateProvider<PokemonViewMode>   // grid/list，持久化
// lib/features/pokemon_detail/providers.dart
pokemonDetailProvider: FutureProviderFamily<PokemonDetailData, int /*speciesId*/>
selectedFormIdProvider: StateProviderFamily<int, int>
learnsetFilterProvider: NotifierFamily<LearnsetFilter, int>  // {versionGroup, methods, sort}
// lib/features/settings/providers.dart
themeModeProvider: Notifier<ThemeMode>（持久化 SharedPreferences）
cardDensityProvider（桌面卡片密度）
// lib/features/favorites/providers.dart
favoriteIdsProvider: StreamProvider<List<int>>
recentIdsProvider: StreamProvider<List<int>>
```

## 6. 数据库运行时（lib/data/）

- `pokedex_database.dart`：drift `@DriftDatabase(tables:[...], daos:[...])`，**所有列用 `@ColumnInfo(name:'snake_name')` 显式命名**，表名用 `@DataClassName`/`@Table(name:)` 对齐 data-contract DDL。
- 打开策略：`LazyDatabase` → 首启把 `assets/database/pokedex.db` 复制到 `getApplicationDocumentsDirectory()/pokedex.db`（exists 时跳过；meta.schemaVersion 比对 manifest 不符则覆盖复制，留给未来升级）。**数据库以只读模式打开**（`NativeDatabase(file, readOnly: true)` 对 pokedex.db；user.db 可写）。
- `user_database.dart`：drift，表 `favorites(species_id PK, created_at)`、`recents(species_id PK, viewed_at)`。
- 查询要求：单查询聚合（JOIN/子查询），禁止 N+1；列表分页 limit/offset；搜索 SQL 见 §7。

## 7. 搜索 SQL 语义（E 单元与 C 单元共同遵守）

```
原始输入 q → trim；若 q 匹配 ^#?\d{1,4}$ → int n = parse（去前导零）
WHERE ( national_dex = n  或为空 )
   OR name_zh_hans LIKE %q%  OR name_zh_hant LIKE %q%
   OR name_en LIKE %q%（大小写不敏感，LOWER()）
   OR name_ja LIKE %q%  OR name_ja_hrkt LIKE %q%  OR name_roomaji LIKE %q%
筛选条件全部在同一 WHERE 组合（世代 IN、属性经 form_types 默认形态 any/all、
地区经 species_dex_numbers EXISTS、编号范围、特殊分类标志位）。
排序固定 national_dex ASC。
```

## 8. 离线守卫（lib/core/offline/）

`BlockingHttpOverrides extends HttpOverrides`：`createHttpClient` 返回的客户端在 `open/openUrl` 直接抛 `OfflineRequestBlocked`。`main()` 中无条件 `HttpOverrides.global = BlockingHttpOverrides()`。集成测试据此验收 0 请求。

## 9. 路由（go_router，路径锁死）

```
/                     图鉴（StatefulShellRoute branch 0）
/favorites            收藏（branch 1）
/settings             设置（branch 2）
/pokemon/:speciesId   详情（compact/medium 全页；expanded+twoPane 时由首页分支内嵌渲染）
/move/:moveId         招式详情（全页推入）
```

## 10. 主机端 SQLite 测试前提

drift 在 Windows 宿主跑测试需要 sqlite3.dll：仓库内 `tool/sqlite3/windows/sqlite3.dll`（构建期一次性下载入库）。测试 setup：

```dart
open.overrideFor(OperatingSystem.windows, () => DynamicLibrary.open('tool/sqlite3/windows/sqlite3.dll'));
```

## 11. 质量门槛

`flutter analyze` 0 error 0 warning；`flutter test` 全绿；`flutter build apk --release --target-platform android-x64` 成功。UI 代码遵守 DESIGN.md，禁止硬编码颜色/时长/圆角。
