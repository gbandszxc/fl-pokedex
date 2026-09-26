# Windows MSI 打包

将 Flutter Windows Release 产物打包为单文件 MSI 安装包（per-machine，x64，WiX Toolset v3.11 独立二进制，免安装）。

## 用法

前置条件（只需一次）：

```powershell
export PUB_CACHE=D:\pub-cache
flutter build windows --release
```

构建 MSI（在仓库根目录执行）：

```bash
uv run tools/msi/build_msi.py
```

脚本会自动：

1. 读取 `pubspec.yaml` 中的 `version`（如 `1.0.0+1` → ProductVersion `1.0.0`）；
2. 首次运行时下载 WiX v3 独立二进制（`wix311-binaries.zip`，官方 GitHub Release 直链）并解压到 `tools/msi/.cache/wix3/`（该目录已 gitignore，无需安装任何 SDK）；
3. 递归 harvest `build/windows/x64/runner/Release/` 全部文件并生成 `.wxs`；
4. 用 `candle.exe` + `light.exe` 构建内嵌 CAB 的单文件 MSI。

## 产物

```
build/windows/msi/Fl-PokeDex-<versionName>-x64.msi
```

例如 `build/windows/msi/Fl-PokeDex-1.0.0-x64.msi`。构建中间产物（`.wxs`/`.wixobj`）在 `build/windows/msi/.work/`。

## 安装包行为

- 安装目录：`C:\Program Files\Fl-PokeDex\`（ProgramFiles64Folder，per-machine）；
- 开始菜单快捷方式：`开始菜单\Fl-PokeDex\Fl-PokeDex`；
- 控制面板"程序与功能"中显示名称、版本与产品图标（`windows/runner/resources/app_icon.ico`）；
- 无 UI 向导（默认基础进度 UI），支持 MajorUpgrade 升级、禁止降级；
- UpgradeCode 固定为 `{5854FB72-F7EC-443C-917D-E57314BBD4DF}`（硬编码于 `build_msi.py`，保证升级链）。

## CI 复现步骤

CI 上无需任何预装 SDK，两条命令即可：

```bash
# 1. 下载并解压 WiX v3 独立二进制（脚本运行时也会自动完成此步，此处为显式缓存示例）
curl -L --fail -o wix311-binaries.zip \
  https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311-binaries.zip
mkdir -p tools/msi/.cache/wix3 && unzip -q wix311-binaries.zip -d tools/msi/.cache/wix3

# 2. 构建（前提：已完成 flutter build windows --release 并上传该目录）
uv run tools/msi/build_msi.py
```

## 验证 MSI 内容（不解包安装到系统）

用管理解包（administrative extract）检查内容完整性：

```bash
mkdir -p build/windows/msi/_extract_check
msiexec /a build/windows/msi/Fl-PokeDex-1.0.0-x64.msi /qn TARGETDIR="D:\\path\\to\\build\\windows\\msi\\_extract_check"
```

解包树中应存在 `Fl-PokeDex.exe`、`flutter_windows.dll`、`data\` 完整目录树（注意：管理解包中文件存储于 `.cab` 归档旁的原始布局，`data/` 等目录应原样可见）。

## 常见问题

- **版本号限制**：MSI ProductVersion 形如 `X.Y.Z` 且 `X ≤ 255`、`Y ≤ 255`、`Z ≤ 65535`；pubspec 的 `versionCode`（`+` 后缀）不进入 MSI 版本。
- **更换 UpgradeCode**：仅在需要把产品拆成独立升级链时才改；改了之后老版本无法升级到新版本。
