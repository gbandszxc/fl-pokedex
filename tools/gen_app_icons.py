# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10.0"]
# ///
"""从 docs/icon/raw.png 生成各平台应用图标，覆盖 Flutter 模板默认图标。

母版统一归一化为 1024x1024 RGB（无 alpha，满足 iOS App Store 硬性要求），
再由母版缩放出全部尺寸，保证各平台观感一致。

覆盖范围（Linux 模板无图标资源，跳过）：
- Android: mipmap-{mdpi..xxxhdpi}/ic_launcher.png（legacy，项目未启用 adaptive icon）
- iOS:     Runner/Assets.xcassets/AppIcon.appiconset 全套
- macOS:   Runner/Assets.xcassets/AppIcon.appiconset 全套
- Windows: runner/resources/app_icon.ico（16-256 多尺寸嵌入）

用法: uv run tools/gen_app_icons.py
"""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "docs" / "icon" / "raw.png"
MASTER_SIZE = 1024

# 密度目录 -> 图标边长（px）
ANDROID_MIPMAPS = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

# 文件名 -> 实际像素边长（@Nx 的像素已折算）
IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

MACOS_ICONS = {
    "app_icon_16.png": 16,
    "app_icon_32.png": 32,
    "app_icon_64.png": 64,
    "app_icon_128.png": 128,
    "app_icon_256.png": 256,
    "app_icon_512.png": 512,
    "app_icon_1024.png": 1024,
}

ICO_SIZES = [16, 24, 32, 48, 64, 128, 256]


def build_master() -> Image.Image:
    raw = Image.open(RAW)
    if raw.mode != "RGB":
        raw = raw.convert("RGB")
    return raw.resize((MASTER_SIZE, MASTER_SIZE), Image.LANCZOS)


def save_png(master: Image.Image, size: int, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    master.resize((size, size), Image.LANCZOS).save(dest, format="PNG")
    print(f"  {dest.relative_to(ROOT)}  ({size}x{size})")


def save_ico(master: Image.Image, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    master.save(dest, format="ICO", sizes=[(s, s) for s in ICO_SIZES])
    print(f"  {dest.relative_to(ROOT)}  (ico: {ICO_SIZES})")


def main() -> None:
    master = build_master()
    android_res = ROOT / "android" / "app" / "src" / "main" / "res"
    ios_set = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    macos_set = ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    win_res = ROOT / "windows" / "runner" / "resources"

    print("Android:")
    for density, size in ANDROID_MIPMAPS.items():
        save_png(master, size, android_res / f"mipmap-{density}" / "ic_launcher.png")

    print("iOS:")
    for name, size in IOS_ICONS.items():
        save_png(master, size, ios_set / name)

    print("macOS:")
    for name, size in MACOS_ICONS.items():
        save_png(master, size, macos_set / name)

    print("Windows:")
    save_ico(master, win_res / "app_icon.ico")


if __name__ == "__main__":
    main()
