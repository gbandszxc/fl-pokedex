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
- Flutter 3.47 stable；Android 构建 `flutter build apk --release --split-per-abi` 按 ABI 分包出**三包**（arm64-v8a / armeabi-v7a / x86_64，不产 universal 包，CI 发布同款）：真机装 arm64-v8a，MuMu 等模拟器装 x86_64；分包由 Flutter 插件按 CLI flag 自动配置（gradle 里手写 splits 会与插件设的 ndk.abiFilters 冲突）。release 用 upload-keystore 签名：本机取 `android/key.properties`（已 gitignore，缺失自动回退 debug 签名），CI 用同名 Secrets 注入（`ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` / `ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD`，与 open-burnin-tool 同一套 keystore）。**Gradle 构建需会话级环境变量**：`JAVA_HOME=D:\Develop\Java\jdk-21.0.7+6`、`GRADLE_USER_HOME=C:\Users\gbandszxc\.gradle`、`PUB_CACHE=D:\pub-cache`（跨盘符 Kotlin 增量编译崩溃的规避，已在 android/gradle.properties 加 `kotlin.incremental=false`）。应用包名 `com.github.gbandszxc.fl_pokedex`。
- MuMu 模拟器 adb：`adb connect 127.0.0.1:7555`（另有 127.0.0.1:16416 实例），安装后 `adb -s <serial> shell monkey -p com.github.gbandszxc.fl_pokedex 1` 启动；**换库重装后须 `pm clear` 清数据**（首启复制的 DB 副本按 schemaVersion 判断是否覆盖）。
- Windows 宿主跑 drift 测试需要 `tool/sqlite3/windows/sqlite3.dll`（已入库，勿删）。
- **Windows 构建需 nuget.exe 在 PATH**：`export PATH="/d/Develop/Tools/nuget:$PATH"`（本机已装于该处；flutter_tts 的 Windows 实现构建期用它拉取 CppWinRT，仅构建期联网，CI 自带无需处理）。

## 硬性规则

1. 运行时依赖禁止引入任何 HTTP 库；任何功能发现需要联网即视为设计错误，回报重议。
2. drift 表/列名必须与 `docs/data-contract.md` DDL 逐字一致（snake_case，用 `@ColumnInfo` 显式命名）。
3. UI 不得硬编码颜色/圆角/时长/断点，一律取 `lib/app/theme/tokens.dart`。
4. 属性色只做徽章/Accent，禁止铺底色；详见 DESIGN.md 禁令。
5. Species ≠ Form：一切“几只宝可梦”的统计以 species 计，形态走 forms 表。
6. 缺官方简中的图鉴文本：如实标注“暂无简体中文资料”，禁止机翻/生成冒充。
7. 提交纪律：单元验收通过即 `git add <该单元文件>` + 一行祈使句提交；并发工作由主会话串行提交。
8. `flutter analyze` 0 error 0 warning、`flutter test` 全绿才允许提交代码单元。

## 开发脚本（Agent 优先入口）

- **执行开发操作前，先运行 `.\dev.ps1 -h`（PowerShell）或 `bash ./dev.sh -h`（Bash）阅读当前帮助，以脚本实际支持的命令和参数为准，禁止猜测用法。** 无参数也会显示帮助，不会启动应用或安装依赖。
- **常用开发操作优先使用根目录 `dev.ps1` / `dev.sh`**，避免自行拼接 Flutter 命令或遗漏环境配置。两份脚本的子命令和参数行为一致，详细说明见 `README.md`。
- `run` / `frontend` 启动原生 Flutter debug 环境，默认宿主桌面；`frontend` 与 `run` 等价，本项目没有 Web/npm 前端。启动后 `r` 热重载、`R` 热重启、`q` 退出，`logs` 用 Ctrl+C 停止。
- Windows 脚本自动应用仓库约定的 JDK、Gradle/Pub 缓存与 NuGet 环境，数据命令自动设置 `PYTHONUTF8=1`，不会持久修改调用方环境。Android debug/release 均按三 ABI 分包；`build msi` 自动先构建 Windows release。
- 构建、代码生成、清理和测试必须串行执行，避免争用 Flutter 产物。子命令失败即停止，必须检查退出码并解决原因，不得隐藏错误或继续依赖失败产物的操作。
- 脚本未封装所需操作时，可使用下方底层命令参考；若判断该操作具有常用、可复用价值，**允许后续更新维护现有 `dev.ps1` / `dev.sh`**，不要重复创建同类包装脚本。新增或调整命令时，必须同步两份脚本的行为、`-h` 帮助与 `README.md` 使用说明，并自测受影响的命令。

```powershell
.\dev.ps1 -h                       # 必须先阅读帮助
.\dev.ps1 setup                    # Flutter 依赖
.\dev.ps1 devices                  # 查看设备 ID
.\dev.ps1 run windows              # 原生前端调试
.\dev.ps1 run windows -- --verbose # 透传 Flutter 选项，也可省略 --
.\dev.ps1 generate                 # 代码生成
.\dev.ps1 check                    # analyze 成功后执行 test
.\dev.ps1 build apk release        # Android 三 ABI 分包
.\dev.ps1 build apk debug
.\dev.ps1 build msi                # Windows release + MSI
.\dev.ps1 logs windows
.\dev.ps1 data                     # 全量数据构建，构建期可能联网
.\dev.ps1 verify-data              # 校验现有离线数据
# Bash 使用 bash ./dev.sh <同名命令> [同样的参数]
```

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
flutter build apk --release --split-per-abi
# APK 产物：build/app/outputs/apk/<release|debug>/Fl-PokeDex-<版本号>-<abi>-<release|debug>.apk（abi ∈ arm64-v8a/armeabi-v7a/x86_64，分包命名见 android/app/build.gradle.kts）
# （build/.../flutter-apk/app-*.apk 是 Flutter 工具链的固定名副本，供 flutter run/install 使用，勿手工改名）
# Windows 可执行：build/windows/x64/runner/<Release|Debug>/Fl-PokeDex.exe；改 BINARY_NAME 后需删 build/windows 重建
# MSI 打包（前置 flutter build windows --release）：uv run tools/msi/build_msi.py → build/windows/msi/Fl-PokeDex-<版本>-x64.msi
# CI：.github/workflows/build.yml 手动触发（gh workflow run build.yml），-f publish=true 时发布 Release（标题=pubspec 版本号，正文空，附件 3 架构签名 APK+MSI）
```
