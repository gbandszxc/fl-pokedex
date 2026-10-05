# Fl-PokeDex

完全离线的宝可梦图鉴。安装即用：无账号、无服务器、无互联网依赖，飞行模式下可查询全部 1000+ 宝可梦的资料、种族值、特性、进化树、形态、招式与各游戏版本图鉴说明。

- Flutter + Material 3，手机 / 平板 / 桌面真实响应式布局
- 数据（SQLite + 本地化立绘）全部随应用打包；除「检查更新」通道外，运行时网络请求数 = 0
- 内置检查更新 / 自动更新：启动静默检查一次，设置页版本号下方有手动入口；发现新版本按当前系统与架构自动选包，在模态里回显进度与速度，下载完交系统安装器（GitHub 发布网页实现，不用 API）
- 简体中文优先，支持中 / 英 / 日 / 编号搜索，多条件组合筛选
- 首选平台：Android / Windows / macOS

## 构建步骤

```bash
# 1. 生成离线数据（需要联网，一次性）
export PYTHONUTF8=1
uv run tools/data_builder/build_all.py

# 2. 运行
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d windows          # 或 -d <android device>

# 3. 测试（含“图鉴链路 0 网络请求 + 更新通道解析/流程”用例）
flutter test
```

## 开发命令

根目录提供 `dev.ps1`（PowerShell 5.1/7）与 `dev.sh`（Bash，含 Windows Git Bash）。
两个入口使用相同的子命令和参数，无参数、`-h`、`--help` 或 `help` 都显示帮助；可从任意目录调用。
本项目的前端就是原生 Flutter 应用，`frontend` 与 `run` 等价，不提供 Web/npm 服务。

```powershell
.\dev.ps1                         # 帮助，不启动、不安装依赖
.\dev.ps1 setup                   # 拉取 Flutter 依赖
.\dev.ps1 doctor                  # 检查工具链
.\dev.ps1 devices                 # 列出设备
.\dev.ps1 run                     # debug，默认宿主桌面
.\dev.ps1 frontend windows        # 原生前端，支持热重载
.\dev.ps1 run 127.0.0.1:7555       # 已连接的 Android 设备
.\dev.ps1 run windows -- --verbose
.\dev.ps1 build                   # 默认 apk release
.\dev.ps1 build apk debug
.\dev.ps1 build windows release
.\dev.ps1 build msi               # Windows release 构建 + MSI 打包
.\dev.ps1 logs windows            # Flutter 日志，Ctrl+C 停止
.\dev.ps1 generate                # build_runner
.\dev.ps1 analyze
.\dev.ps1 test
.\dev.ps1 check                   # analyze 成功后执行 test
.\dev.ps1 clean                   # 清理 Flutter 构建缓存
.\dev.ps1 data                    # 全量数据构建，构建期可能联网
.\dev.ps1 verify-data             # 校验现有离线数据
```

Bash 下把 `.\dev.ps1` 换为 `bash ./dev.sh`，其余参数不变。
`build` 支持 `apk/windows/macos/linux/msi`，模式为 `release/debug`；桌面构建必须在对应宿主执行，MSI 仅支持 Windows release。
Android 始终输出 arm64-v8a、armeabi-v7a、x86_64 三个 APK，位于 `build/app/outputs/apk/<模式>/`；
Windows 程序位于 `build/windows/x64/runner/<Release|Debug>/Fl-PokeDex.exe`，MSI 位于 `build/windows/msi/`。

Windows 入口在本机路径存在时使用 `D:\Develop\Java\jdk-21.0.7+6`、`D:\pub-cache` 和 `D:\Develop\Tools\nuget`，
并将 Gradle 缓存设为用户目录下 `.gradle`；不会持久修改环境或 Flutter 配置。数据命令自动设置 `PYTHONUTF8=1`。
`run/frontend/logs` 可在设备后直接传入额外 Flutter 选项，也可用 `--` 分隔；两种写法行为一致，不允许覆盖设备和 debug 模式。
启动后 `r` 热重载、`R` 热重启、`q` 退出。不要同时运行构建、代码生成、清理和测试，避免争用 Flutter 产物。
设备连接由 `adb connect 127.0.0.1:7555` 完成；换库重装后执行 `adb -s <设备> shell pm clear com.github.gbandszxc.fl_pokedex`（会清空收藏等应用数据）。
脚本退出码：成功 `0`、用法错误 `2`、环境错误 `1`；工具执行失败保留工具退出码，并停止后续步骤。

架构、数据契约与设计系统见 `docs/` 与 `DESIGN.md`。数据与素材来源、许可见 `THIRD_PARTY_NOTICES.md`；宝可梦相关名称与立绘版权归 Nintendo / Creatures Inc. / GAME FREAK inc. 等权利方所有，本项目仅为非商业粉丝工具，应用自身的 UI / 代码为原创。
