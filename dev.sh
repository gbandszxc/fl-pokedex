#!/usr/bin/env bash
# Bash 3.2+；数组传参，不使用 eval。直接执行，勿 source。
set -euo pipefail

show_help() {
    printf '%s\n' 'Fl-PokeDex 开发入口
用法: bash ./dev.sh <command> [arguments]

  help | -h | --help          显示帮助（无参数也显示）
  setup                      flutter pub get
  doctor                     flutter doctor -v
  devices                    flutter devices
  run [device]               启动 debug 环境，默认宿主桌面
  frontend [device]          同 run；本项目无 Web/npm 前端
  build [target] [mode]      默认 apk release
                             target: apk / windows / macos / linux / msi
                             mode: release / debug（msi 仅 release）
  logs [device]              持续查看 Flutter 日志，默认宿主桌面
  generate                   运行 build_runner 代码生成
  analyze                    flutter analyze
  test                       flutter test
  check                      analyze 通过后运行 test
  clean                      flutter clean（仅清理构建缓存）
  data                       全量构建离线数据（构建期可能联网）
  verify-data                校验现有离线数据

run/frontend/logs 可在 device 后直接传入 Flutter 参数（也可使用 --）：
  bash ./dev.sh run windows -- --verbose
  bash ./dev.sh logs 127.0.0.1:7555
  bash ./dev.sh build apk debug
  bash ./dev.sh build windows release
  bash ./dev.sh build msi

启动后 r 热重载，R 热重启，q 退出；日志用 Ctrl+C 停止。
Android 始终输出三 ABI 分包；MSI 先构建 Windows release。
Windows 使用仓库约定的本机 JDK/Gradle/Pub Cache/NuGet，仅对子进程生效。
退出码: 0 成功；2 用法错误；1 环境错误；子命令失败保留其退出码。'
}

usage_error() {
    printf '%s\n使用 bash ./dev.sh -h 查看帮助。\n' "$1" >&2
    exit 2
}

run_tool() {
    local tool=$1 status
    shift
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf '找不到 %s，请先安装并加入 PATH。\n' "$tool" >&2
        exit 1
    fi
    printf '> %s' "$tool"
    printf ' %s' "$@"
    printf '\n'
    if "$tool" "$@"; then
        return 0
    else
        status=$?
        printf '%s 失败，退出码 %s。\n' "$tool" "$status" >&2
        exit "$status"
    fi
}

if [[ $# -eq 0 ]]; then
    show_help
    exit 0
fi
case "$1" in help|-h|--help) show_help; exit 0 ;; esac
if [[ $# -eq 2 ]]; then
    case "$2" in -h|--help) show_help; exit 0 ;; esac
fi

command_name=$1
shift
case "${OSTYPE:-}" in
    msys*|cygwin*) host_target=windows ;;
    darwin*) host_target=macos ;;
    *) host_target=linux ;;
esac
device=$host_target
extra=()
target=apk
mode=release

# 完成用法校验后才执行工具或修改环境。
case "$command_name" in
    run|frontend|logs)
        if [[ $# -gt 0 && $1 != -* ]]; then
            device=$1
            shift
            case "$device" in
                chrome|edge|web-server) usage_error 'device 必须是原生设备 ID；本项目不支持 Web。' ;;
            esac
        fi
        if [[ $# -gt 0 ]]; then
            if [[ $1 == -- ]]; then
                shift
            elif [[ $1 != -* ]]; then
                usage_error 'Flutter 参数必须以 - 开头；可用 -- 透传。'
            fi
            # 兼容 Bash 3.2 的 set -u：调用工具时安全展开空数组。
            extra=("$@")
            for flag in "$@"; do
                case "$flag" in
                    -d*|--device-id|--device-id=*|--debug|--release|--profile)
                        usage_error '设备和 debug 模式由脚本管理，不能在透传参数中覆盖。' ;;
                esac
            done
        fi
        ;;
    build)
        [[ $# -le 2 ]] || usage_error 'build 最多接收 target 和 mode。'
        target=${1-apk}
        mode=${2-release}
        case "$target" in apk|windows|macos|linux|msi) ;; *) usage_error "不支持的构建目标: $target" ;; esac
        case "$mode" in release|debug) ;; *) usage_error "不支持的构建模式: $mode" ;; esac
        [[ $target != msi || $mode == release ]] || usage_error 'MSI 仅支持 release。'
        required_host=$target
        [[ $target != msi ]] || required_host=windows
        if [[ $target != apk && $required_host != "$host_target" ]]; then
            usage_error "$target 需要在 $required_host 宿主上构建。"
        fi
        ;;
    setup|doctor|devices|generate|analyze|test|check|clean|data|verify-data)
        [[ $# -eq 0 ]] || usage_error "$command_name 不接收参数。"
        ;;
    *) usage_error "未知命令: $command_name" ;;
esac

# 脚本进程的 cwd 和 export 不会污染调用方。
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
export PYTHONUTF8=1
if [[ $host_target == windows ]]; then
    if [[ -f /d/Develop/Java/jdk-21.0.7+6/bin/java.exe ]]; then
        export JAVA_HOME='D:\Develop\Java\jdk-21.0.7+6'
        export PATH="/d/Develop/Java/jdk-21.0.7+6/bin:$PATH"
    fi
    export GRADLE_USER_HOME="${USERPROFILE:-$(cygpath -w "$HOME")}\\.gradle"
    if [[ -d /d ]]; then export PUB_CACHE='D:\pub-cache'; fi
    if [[ -f /d/Develop/Tools/nuget/nuget.exe ]]; then
        export PATH="/d/Develop/Tools/nuget:$PATH"
    fi
fi

case "$command_name" in
    setup)       run_tool flutter pub get ;;
    doctor)      run_tool flutter doctor -v ;;
    devices)     run_tool flutter devices ;;
    run|frontend) run_tool flutter run --debug -d "$device" ${extra[@]+"${extra[@]}"} ;;
    logs)        run_tool flutter logs -d "$device" ${extra[@]+"${extra[@]}"} ;;
    build)
        flutter_target=$target
        [[ $target != msi ]] || flutter_target=windows
        if [[ $target == apk ]]; then
            run_tool flutter build apk "--$mode" --split-per-abi
        else
            run_tool flutter build "$flutter_target" "--$mode"
        fi
        if [[ $target == msi ]]; then run_tool uv run tools/msi/build_msi.py; fi
        ;;
    generate)    run_tool dart run build_runner build --delete-conflicting-outputs ;;
    analyze)     run_tool flutter analyze ;;
    test)        run_tool flutter test ;;
    check)       run_tool flutter analyze; run_tool flutter test ;;
    clean)       run_tool flutter clean ;;
    data)        run_tool uv run tools/data_builder/build_all.py ;;
    verify-data) run_tool uv run tools/data_builder/verify.py ;;
esac
