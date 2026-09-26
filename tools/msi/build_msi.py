#!/usr/bin/env python3
# /// script
# requires-python = ">=3.9"
# dependencies = []
# ///
"""Build the Fl-PokeDex Windows MSI installer.

Prerequisite: `flutter build windows --release` must have been run, so that
build/windows/x64/runner/Release/ exists.

Usage (from the repository root):
    uv run tools/msi/build_msi.py

The script:
  1. Reads the app version from pubspec.yaml (e.g. `version: 1.0.0+1`).
  2. Ensures the WiX Toolset v3.11 standalone binaries are available under
     tools/msi/.cache/wix3/ (downloads wix311-binaries.zip from the official
     GitHub release on first run; no SDK installation is required).
  3. Harvests every file under build/windows/x64/runner/Release/ and
     generates a self-contained .wxs source file.
  4. Runs candle.exe + light.exe to produce a single-file MSI with an
     embedded cabinet.
  5. Writes the MSI to build/windows/msi/Fl-PokeDex-<versionName>-x64.msi
     and prints that path at the end.
"""

from __future__ import annotations

import hashlib
import os
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

# ---------------------------------------------------------------------------
# Fixed identity of the product. The UpgradeCode MUST stay stable across
# releases so that MajorUpgrade treats later builds as upgrades of this one.
# ---------------------------------------------------------------------------
UPGRADE_CODE = "{5854FB72-F7EC-443C-917D-E57314BBD4DF}"
SHORTCUT_COMPONENT_GUID = "{5FDBDB1A-F3B7-40C6-A03C-39E4D8854C2B}"
APP_NAME = "Fl-PokeDex"
MANUFACTURER = "Fl-PokeDex Project"
WIX3_URL = (
    "https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/"
    "wix311-binaries.zip"
)

WIX_NAMESPACE = "http://schemas.microsoft.com/wix/2006/wi"

REPO_ROOT = Path(__file__).resolve().parents[2]
RELEASE_DIR = REPO_ROOT / "build" / "windows" / "x64" / "runner" / "Release"
MSI_OUT_DIR = REPO_ROOT / "build" / "windows" / "msi"
WORK_DIR = MSI_OUT_DIR / ".work"
CACHE_DIR = Path(__file__).resolve().parent / ".cache"
WIX_DIR = CACHE_DIR / "wix3"
ICON_FILE = REPO_ROOT / "windows" / "runner" / "resources" / "app_icon.ico"


def read_version() -> tuple[str, str]:
    """Return (versionName, versionCode) from pubspec.yaml."""
    pubspec = REPO_ROOT / "pubspec.yaml"
    match = re.search(
        r'^\s*version:\s*["\']?([^"\'\s#]+)["\']?\s*(?:#.*)?$', pubspec.read_text(encoding="utf-8"), re.M
    )
    if not match:
        sys.exit("error: could not find `version:` in pubspec.yaml")
    raw = match.group(1)
    name, _, code = raw.partition("+")
    if not code:
        code = "0"
    # MSI ProductVersion limit: 255.255.65535
    parts = name.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        sys.exit(
            f"error: versionName '{name}' is not of the form X.Y.Z, "
            "which MSI ProductVersion requires"
        )
    major, minor, build = (int(p) for p in parts)
    if major > 255 or minor > 255 or build > 65535:
        sys.exit(f"error: versionName '{name}' exceeds MSI ProductVersion limits")
    return name, code


def ensure_wix() -> Path:
    """Ensure candle.exe/light.exe exist under .cache/wix3; download if needed."""
    candle = WIX_DIR / "candle.exe"
    light = WIX_DIR / "light.exe"
    if candle.exists() and light.exists():
        return WIX_DIR

    print(f"Downloading WiX Toolset v3 standalone binaries from {WIX_URL} ...")
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    zip_path = CACHE_DIR / "wix311-binaries.zip"
    if not zip_path.exists():
        try:
            from urllib.request import Request, urlopen

            req = Request(WIX_URL, headers={"User-Agent": "fl-pokedex-build"})
            with urlopen(req) as resp, open(zip_path, "wb") as out:
                total = int(resp.headers.get("Content-Length") or 0)
                done = 0
                while True:
                    chunk = resp.read(1024 * 256)
                    if not chunk:
                        break
                    out.write(chunk)
                    done += len(chunk)
                    if total:
                        sys.stdout.write(f"\r  {done / 1e6:.1f} / {total / 1e6:.1f} MB")
                        sys.stdout.flush()
            print()
        except Exception as exc:  # noqa: BLE001 - report any download failure
            zip_path.unlink(missing_ok=True)
            sys.exit(f"error: failed to download WiX binaries from {WIX_URL}: {exc}")

    try:
        with zipfile.ZipFile(zip_path) as archive:
            archive.extractall(WIX_DIR)
    except zipfile.BadZipFile as exc:
        sys.exit(f"error: downloaded WiX archive is corrupt: {exc}")

    if not (candle.exists() and light.exists()):
        sys.exit("error: extracted WiX archive does not contain candle.exe/light.exe")
    print(f"WiX 3 ready at {WIX_DIR}")
    return WIX_DIR


def harvest_files(source: Path) -> list[str]:
    """Collect all file paths below `source` as '/'-separated relative paths."""
    result: list[str] = []
    for root, dirs, files in os.walk(source):
        dirs.sort()
        for name in sorted(files):
            rel = Path(root, name).relative_to(source).as_posix()
            result.append(rel)
    if not result:
        sys.exit(f"error: no files found under {source}")
    return result


def short_id(prefix: str, rel: str, length: int = 20) -> str:
    digest = hashlib.sha1(rel.lower().encode("utf-8")).hexdigest()
    return f"{prefix}_{digest[:length]}"


def _add_directory(parent_el: ET.Element, dir_tree: dict, rel: str) -> ET.Element:
    """Recursively create <Directory> elements for the harvest tree.

    The root (rel == "") is pre-seeded in dir_tree as INSTALLFOLDER.
    """
    if rel == "":
        return dir_tree[rel]
    if rel in dir_tree:
        return dir_tree[rel]
    parent_rel, _, name = rel.rpartition("/")
    parent_node = _add_directory(parent_el, dir_tree, parent_rel)
    el = ET.SubElement(
        parent_node,
        "Directory",
        {"Id": short_id("d", rel, 12), "Name": name},
    )
    dir_tree[rel] = el
    return el


def generate_wxs(rel_files: list[str], version_name: str) -> Path:
    """Generate a self-contained WiX 3 source file covering the whole app."""
    ET.register_namespace("", WIX_NAMESPACE)
    wix = ET.Element("Wix", {"xmlns": WIX_NAMESPACE})
    product = ET.SubElement(
        wix,
        "Product",
        {
            "Id": "*",  # new ProductCode per build; MajorUpgrade handles upgrades
            "Name": APP_NAME,
            "Language": "1033",
            "Version": version_name,
            "Manufacturer": MANUFACTURER,
            "UpgradeCode": UPGRADE_CODE,
        },
    )
    # InstallerVersion 500: Windows 7+; Compressed: cabinet embedded via light
    ET.SubElement(
        product,
        "Package",
        {
            "InstallerVersion": "500",
            "Compressed": "yes",
            "InstallScope": "perMachine",
            "Platform": "x64",
            "Description": f"{APP_NAME} {version_name} installer",
            "Manufacturer": MANUFACTURER,
        },
    )
    ET.SubElement(
        product,
        "MajorUpgrade",
        {"DowngradeErrorMessage": "A newer version of [ProductName] is already installed."},
    )
    ET.SubElement(product, "MediaTemplate", {"EmbedCab": "yes"})
    ET.SubElement(
        product,
        "Icon",
        {"Id": "AppIcon.ico", "SourceFile": str(ICON_FILE)},
    )
    ET.SubElement(product, "Property", {"Id": "ARPPRODUCTICON", "Value": "AppIcon.ico"})
    ET.SubElement(product, "Property", {"Id": "ARPNOMODIFY", "Value": "1"})

    feature = ET.SubElement(
        product,
        "Feature",
        {
            "Id": "ProductFeature",
            "Title": APP_NAME,
            "Description": f"Installs {APP_NAME} and its runtime files.",
            "Level": "1",
        },
    )
    ET.SubElement(feature, "ComponentGroupRef", {"Id": "ProductComponents"})

    target_dir = ET.SubElement(product, "Directory", {"Id": "TARGETDIR", "Name": "SourceDir"})
    pf64 = ET.SubElement(target_dir, "Directory", {"Id": "ProgramFiles64Folder"})
    install_folder = ET.SubElement(pf64, "Directory", {"Id": "INSTALLFOLDER", "Name": APP_NAME})
    prog_menu = ET.SubElement(target_dir, "Directory", {"Id": "ProgramMenuFolder"})
    ET.SubElement(prog_menu, "Directory", {"Id": "ApplicationProgramsFolder", "Name": APP_NAME})

    comp_group = ET.SubElement(product, "ComponentGroup", {"Id": "ProductComponents"})

    # Start-menu shortcut component. Fixed GUID; the registry value is the
    # stable KeyPath. MSI rules (ICE38/43/57) require the KeyPath of a
    # non-advertised shortcut component to live under HKCU — this is the
    # standard WiX pattern even for per-machine installs.
    shortcut_comp = ET.SubElement(
        comp_group,
        "Component",
        {"Id": "ApplicationShortcut", "Guid": SHORTCUT_COMPONENT_GUID,
         "Directory": "ApplicationProgramsFolder"},
    )
    ET.SubElement(
        shortcut_comp,
        "Shortcut",
        {
            "Id": "StartMenuShortcut",
            "Name": APP_NAME,
            "Description": f"{APP_NAME} - fully offline Pokedex",
            "Target": "[INSTALLFOLDER]" f"{APP_NAME}.exe",
            "WorkingDirectory": "INSTALLFOLDER",
            "Icon": "AppIcon.ico",
        },
    )
    ET.SubElement(
        shortcut_comp,
        "RemoveFolder",
        {"Id": "RemoveApplicationProgramsFolder", "On": "uninstall"},
    )
    ET.SubElement(
        shortcut_comp,
        "RegistryValue",
        {
            "Root": "HKCU",
            "Key": rf"Software\{APP_NAME}",
            "Name": "StartMenuShortcut",
            "Type": "integer",
            "Value": "1",
            "KeyPath": "yes",
        },
    )

    # One component per harvested file. Guid="*" lets candle derive a stable
    # GUID from the component's install location; the file is an explicit
    # KeyPath, which Guid="*" requires to be deterministic. The directory tree
    # lives under TARGETDIR; each component references its directory by Id.
    dir_tree: dict[str, ET.Element] = {"": install_folder}
    for rel in rel_files:
        dir_rel, _, file_name = rel.rpartition("/")
        _add_directory(target_dir, dir_tree, dir_rel)
        dir_id = "INSTALLFOLDER" if dir_rel == "" else short_id("d", dir_rel, 12)
        component = ET.SubElement(
            comp_group,
            "Component",
            {"Id": short_id("cmp", rel), "Guid": "*", "Directory": dir_id},
        )
        ET.SubElement(
            component,
            "File",
            {"Id": short_id("fil", rel), "Name": file_name, "KeyPath": "yes",
             "Source": str(RELEASE_DIR / rel)},
        )

    ET.indent(wix, space="  ")
    wxs_path = WORK_DIR / f"{APP_NAME}.wxs"
    ET.ElementTree(wix).write(wxs_path, encoding="utf-8", xml_declaration=True)
    return wxs_path


def run_tool(exe: Path, args: list[str]) -> None:
    print(f"> {exe.name} {' '.join(args)}")
    result = subprocess.run([str(exe), *args], cwd=str(WORK_DIR))
    if result.returncode != 0:
        sys.exit(f"error: {exe.name} failed with exit code {result.returncode}")


def main() -> None:
    version_name, _version_code = read_version()
    print(f"Building {APP_NAME} MSI for version {version_name}")

    if not RELEASE_DIR.is_dir() or not (RELEASE_DIR / f"{APP_NAME}.exe").exists():
        sys.exit(
            f"error: {RELEASE_DIR} not found or missing {APP_NAME}.exe.\n"
            "Run `flutter build windows --release` first."
        )
    if not ICON_FILE.exists():
        sys.exit(f"error: icon not found: {ICON_FILE}")

    wix_dir = ensure_wix()
    rel_files = harvest_files(RELEASE_DIR)
    print(f"Harvested {len(rel_files)} files from {RELEASE_DIR}")

    WORK_DIR.mkdir(parents=True, exist_ok=True)
    wxs_path = generate_wxs(rel_files, version_name)
    print(f"Generated WiX source: {wxs_path}")

    wixobj = WORK_DIR / f"{APP_NAME}.wixobj"
    run_tool(wix_dir / "candle.exe", [
        "-arch", "x64",
        "-nologo",
        "-out", str(wixobj),
        str(wxs_path),
    ])

    msi_path = MSI_OUT_DIR / f"{APP_NAME}-{version_name}-x64.msi"
    run_tool(wix_dir / "light.exe", [
        "-nologo",
        # ICE60 warns on versioned non-font files without a Language column;
        # it is harmless noise for Flutter payload files.
        "-sw1076",
        "-out", str(msi_path),
        str(wixobj),
    ])

    size_mb = msi_path.stat().st_size / 1e6
    print(f"\nMSI built successfully ({size_mb:.1f} MB):")
    print(msi_path)


if __name__ == "__main__":
    main()
