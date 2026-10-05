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
| H 更新通道 | `lib/core/update/` `lib/app/update_startup_check.dart` `lib/features/settings/check_update_row.dart` |

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
  flutter_tts: ^4.2.5          # 本地朗读，纯 MethodChannel
  package_info_plus: ^10.2.1   # 关于/许可页版本号，纯 MethodChannel
  url_launcher: ^6.3.2         # 关于区外链跳系统浏览器，纯 MethodChannel（应用自身 0 请求）
  flutter_svg: ^2.3.0          # 关于区 GitHub 标志，本地矢量解析
dev_dependencies:
  build_runner: ^2.4.14
  drift_dev: ^2.28.0
  freezed: ^2.5.7
  json_serializable: ^6.9.0
  flutter_lints: ^6.0.0   # 以 flutter create 生成版本为准
  flutter_test: {sdk: flutter}
```

**运行时依赖里禁止出现任何 HTTP 库**（dio/http/http 等）。版本以 `flutter pub get` 实际解析为准，允许向上浮动小版本，不允许降级大版本。

更新通道不引入任何依赖：检查/下载直接用 `dart:io` 的 `HttpClient`（经 `BlockingHttpOverrides` 白名单放行），系统架构用 `dart:ffi` 的 `Abi.current()` 判定，Android 安装包唤起走自建 MethodChannel + FileProvider。

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
  Future<List<FlavorEntry>> getFormFlavorTexts(int formId);         // 地区形态专属说明（data-contract §6）；空列表 → UI 回退 species 文本
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

修订记录：**接口增补**——`getFormFlavorTexts(int formId)` 返回地区形态专属图鉴说明（版本地区 == 地区形态的行，见 data-contract.md §6）；无归属文本返回空列表，由 UI 回退 species 级文本。**接口增补（详情页上一只/下一只）**——`getAllSpeciesIds()` 返回全部 species 的 id，按 national_dex 升序（data-contract：species.id == national_dex）；详情页据此取相邻项做直接切换，无合适现有接口（queryPokemon 为分页列表语义且需硬编码上限）故新增最小只读查询。

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
seedColorProvider: Notifier<AppSeedColor>（持久化 SharedPreferences key 'seed_color'，默认 amber，非法值回退 amber）
cardDensityProvider（桌面卡片密度）
homeViewLayoutProvider: Notifier<HomeViewLayout>（首页布局，与 pokedex 侧共享 SP key `view_mode`）
appVersionProvider: FutureProvider<String>（安装包版本号，关于/许可页；读 package_info_plus，唯一事实来源为 pubspec `version`）
externalUrlOpenerProvider: Provider<ExternalUrlOpener>（关于区「项目地址」跳系统浏览器；typedef ExternalUrlOpener = Future<bool> Function(Uri)，默认 launchUrl，测试注入 fake 断言目标 URL）
kProjectRepoUrl: const String（仓库地址常量，取自 git remote origin）
// lib/core/update/update_providers.dart
updateTargetProvider: Provider<UpdateTarget?>（当前平台/架构；不在发布矩阵内为 null）
updateServiceProvider: Provider<UpdateService>（检查/下载；默认 GitHub 发布网页实现，测试 override 成 fake 保证不触网）
updateInstallerProvider: Provider<UpdateInstaller>（Android 平台通道 / Windows msiexec / macOS open）
updatePromptSnoozedProvider: NotifierProvider<UpdatePromptSnooze, bool>（会话内已忽略启动提示；手动入口不受影响）
// lib/features/favorites/providers.dart
favoriteIdsProvider: StreamProvider<List<int>>
recentIdsProvider: StreamProvider<List<int>>
```

修订记录：**主题色增补**——`lib/app/theme/app_colors.dart` 新增 `enum AppSeedColor { amber, rose, forest, blue, teal, violet }`（amber=琥珀·默认即现有品牌色，rose=粉，forest=墨绿，blue=蓝，teal=青，violet=紫）；`buildLightTheme()/buildDarkTheme()` 增加可选命名参数 `seed`（默认 `AppSeedColor.amber`）。设置页"主题色"行见 design-ui.md §8。**外链跳转增补**——设置页关于区新增「项目地址」行（左文案 + 右 `assets/icons/github.svg` 标志），点按经 `externalUrlOpenerProvider` 调 `launchUrl` 委托系统浏览器；`url_launcher` 走 MethodChannel，应用进程自身不发起请求，运行时 0 网络红线不变（见 §8）。

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

## 8. 离线保证与更新通道（运行时联网的唯一白名单）

1. **数据全部随包**：`assets/database/pokedex.db` + `manifest.json` + `assets/pokemon/{full,thumb}/*.webp`。运行时只读 assets 与本地文件；首启把 db 复制到应用文档目录（`meta.schema_version` 与 manifest 比对决定是否覆盖，换数据重装需 `pm clear`），Drift 以 `query_only` 只读打开；图片 `Image.asset` + `cacheWidth`。
2. **运行时依赖零 HTTP 库**：drift / riverpod / go_router 等均无网络能力，禁止引入 dio/http 等。`url_launcher` 不在此列——它走 MethodChannel 把 URL 交给系统浏览器/关联应用，请求由 OS 侧发起，本进程不产生任何 socket，`HttpOverrides` 也不受影响（唯一用途：设置页「项目地址」跳转）。
3. **兜底拦截器 + 更新域名白名单**：`main()` 无条件 `HttpOverrides.global = BlockingHttpOverrides()`（lib/core/offline/），除下述更新通道白名单（`kUpdateChannelAllowedHosts`：github.com / release-assets.githubusercontent.com / objects.githubusercontent.com / github-releases.githubusercontent.com，且必须 https）外，任何 `open/openUrl` 当场抛 `OfflineRequestBlocked`——非更新功能试图联网会立刻暴露而非静默请求。检查与下载在 Dart 侧手动逐跳跟随重定向，每一跳都过白名单校验。
4. **更新通道（唯一联网用途）**：`lib/core/update/`。
   - `update_release.dart`：纯函数——版本号比较（数字段，`v` 前缀/构建号不参与）、`releases/latest` 重定向 tag 解析、`expanded_assets` HTML 里按平台/架构选包（资产命名契约见该文件注释）。
   - `update_service.dart`：`UpdateService.checkForUpdate / download`。检查读 GitHub 发布**网页**（不使用 API、无 token/速率限制），失败以 `UpdateCheckFailed` 返回不抛；下载写 `getTemporaryDirectory()/updates/`，按 500ms 回调进度/速度，支持取消并删除半成品。
   - `update_installer.dart`：Android 走宿主 MethodChannel（FileProvider content:// + 系统包安装器，未授权时跳「安装未知应用」设置）；Windows 拉起 `msiexec /i` 后退出应用（安装器要替换运行中的 exe）；macOS `open` dmg。
   - `update_dialogs.dart` / `update_flow.dart`：发现新版本对话框 → 下载模态（进度 + 速度）→ 安装结果反馈；启动静默检查挂在外壳（`lib/app/update_startup_check.dart`），手动入口在设置页版本号下方（`CheckUpdateRow`）。
   - Android 侧同步声明 `INTERNET` / `REQUEST_INSTALL_PACKAGES` 权限与 FileProvider（applicationId `.update_installer`）；macOS 两侧 entitlements 增加 `com.apple.security.network.client`。

机器判据：`test/acceptance/offline_acceptance_test.dart` 在拦截器生效下，用真实 `pokedex.db` 驱动完整链路（首页→搜索→详情→进化→招式→图鉴说明→切主题），断言全程 0 请求且无异常（启动静默检查 override 成 fake）；`test/core/update/` 覆盖版本比较/选包/进度格式化/流程弹窗，`test/offline_guard_test.dart` 覆盖白名单口径。网络只允许出现在构建期（`tools/data_builder`，见其 README 的缓存与增量说明）。

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

## 12. 实施偏差记录（与上文契约的最终落地产物）

- **codegen 白名单**：仓库根 `build.yaml` 把 freezed/json_serializable/drift_dev 限定在 `lib/domain/models/**`、`lib/data/**`、`lib/core/db/**`（Flutter 3.47 的 dot-shorthand 语法会使旧 analyzer 崩溃，features 内禁放 codegen 文件）。数据层保持纯 Dart，Flutter 胶水在 `lib/core/di.dart`。
- **drift 命名**：drift 2.28 无 `@Table(name:)`/`@ColumnInfo(name:)`，用 `tableName` override + `.named('snake_name')` 达成同等效果；只读打开用 `enableMigrations:false` + `PRAGMA query_only`。
- **Provider**：`listViewModeProvider` 等用 `Notifier`（而非 §5 所写 StateProvider）；`formDetailProvider` family 参数为 `FormSummary` 值对象；分页用 `AsyncNotifier` + 代数计数防竞态。
- **接口增补（主会话裁决）**：`getSpeciesInfo` / `getPokemonSummaries` / FormSummary.heightM/weightKg / AbilityRef.descriptionZh|En / EvolutionTree.nodesBySpeciesId。
- **详情页折叠头**：compact/medium 高度 = `clamp(视口高×0.5, 300, 440)`（非固定 512）。
- **网格**：两档密度用固定 `mainAxisExtent`（244/200），弃用 childAspectRatio（防小屏溢出）。
- **离线库副本**：按 `meta.schema_version` 与 manifest 比对决定是否覆盖；换数据重装需 `pm clear`。
- **更新通道**：新增 `lib/core/update/`（H 单元，见 §8）。检查走 GitHub 发布网页（`releases/latest` 重定向 + `expanded_assets` 片段），不引入 HTTP 库（`dart:io HttpClient` + 守卫白名单）；架构判定用 `Abi.current()`（Android 分包后即所装 APK 的 ABI）；Android 安装走宿主 MethodChannel + FileProvider（`res/xml/update_file_paths.xml`），Windows 拉起 `msiexec /i` 后退出应用，macOS `open` dmg。启动静默检查为 `lib/app/update_startup_check.dart`（失败静默），手动入口为设置页版本号下方的 `CheckUpdateRow`。
