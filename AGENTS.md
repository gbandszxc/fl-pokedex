# AGENTS.md — Fl-PokeDex 项目约定

## 项目

完全离线的 Flutter 宝可梦图鉴。运行时 **0 网络请求**（代码里内置 HTTP 全量拦截器，请求即抛错）。UI 原创设计，Token 唯一来源 `DESIGN.md` + `lib/app/theme/`。

## 关键文档（改动前先读）

- `docs/architecture.md` — 层次、接口签名、Provider 命名、路由表、文件所有权
- `docs/data-contract.md` — SQLite DDL、ID 对齐、语言/版本组映射、构建校验
- `docs/design-ui.md` — ASCII 布局稿
- `PRODUCT.md` / `DESIGN.md` — 产品定位与设计系统

## 本机环境（Windows 11）

- 终端命令用跨平台写法；Python 一律走 uv：`uv run <script>.py`。
- **运行任何 Python 前先 `export PYTHONUTF8=1`**（GBK 编码坑）。
- 数据构建脚本在 `tools/data_builder/`，上游数据缓存在 `.cache/`（已 gitignore，可随时重建）。
- Flutter 3.47 stable；Android 构建用 `flutter build apk --release --target-platform android-x64`（MuMu 为 x86_64）。**Gradle 构建需会话级环境变量**：`JAVA_HOME=D:\Develop\Java\jdk-21.0.7+6`、`GRADLE_USER_HOME=C:\Users\gbandszxc\.gradle`、`PUB_CACHE=D:\pub-cache`（跨盘符 Kotlin 增量编译崩溃的规避，已在 android/gradle.properties 加 `kotlin.incremental=false`）。应用包名 `com.amberdex.fl_pokedex`。
- MuMu 模拟器 adb：`adb connect 127.0.0.1:7555`（另有 127.0.0.1:16416 实例），安装后 `adb -s <serial> shell monkey -p com.amberdex.fl_pokedex 1` 启动；**换库重装后须 `pm clear` 清数据**（首启复制的 DB 副本按 schemaVersion 判断是否覆盖）。
- Windows 宿主跑 drift 测试需要 `tool/sqlite3/windows/sqlite3.dll`（已入库，勿删）。

## 硬性规则

1. 运行时依赖禁止引入任何 HTTP 库；任何功能发现需要联网即视为设计错误，回报重议。
2. drift 表/列名必须与 `docs/data-contract.md` DDL 逐字一致（snake_case，用 `@ColumnInfo` 显式命名）。
3. UI 不得硬编码颜色/圆角/时长/断点，一律取 `lib/app/theme/tokens.dart`。
4. 属性色只做徽章/Accent，禁止铺底色；详见 DESIGN.md 禁令。
5. Species ≠ Form：一切“几只宝可梦”的统计以 species 计，形态走 forms 表。
6. 缺官方简中的图鉴文本：如实标注“暂无简体中文资料”，禁止机翻/生成冒充。
7. 提交纪律：单元验收通过即 `git add <该单元文件>` + 一行祈使句提交；并发工作由主会话串行提交。
8. `flutter analyze` 0 error 0 warning、`flutter test` 全绿才允许提交代码单元。

## 常用命令

```powershell
# 数据构建（首次或上游更新）
export PYTHONUTF8=1; uv run tools/data_builder/build_all.py

# Flutter
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run -d windows
flutter build apk --release --target-platform android-x64
# APK 产物：build/app/outputs/apk/<release|debug>/Fl-PokeDex-<版本号>-<release|debug>.apk
# （build/.../flutter-apk/app-*.apk 是 Flutter 工具链的固定名副本，供 flutter run/install 使用，勿手工改名）
# Windows 可执行：build/windows/x64/runner/<Release|Debug>/Fl-PokeDex.exe；改 BINARY_NAME 后需删 build/windows 重建
# MSI 打包（前置 flutter build windows --release）：uv run tools/msi/build_msi.py → build/windows/msi/Fl-PokeDex-<版本>-x64.msi
# CI：.github/workflows/build.yml 手动触发（gh workflow run build.yml），-f publish=true 时发布 Release（标题=pubspec 版本号，正文空，附件 APK+MSI）
```
