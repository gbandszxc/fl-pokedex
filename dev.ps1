# PowerShell 5.1 / 7+. 使用数组传参，不经字符串拼接或 Invoke-Expression。
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Show-Help {
    @'
Fl-PokeDex 开发入口
用法: .\dev.ps1 <command> [arguments]

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
  .\dev.ps1 run windows -- --verbose
  .\dev.ps1 logs 127.0.0.1:7555
  .\dev.ps1 build apk debug
  .\dev.ps1 build windows release
  .\dev.ps1 build msi

启动后 r 热重载，R 热重启，q 退出；日志用 Ctrl+C 停止。
Android 始终输出三 ABI 分包；MSI 先构建 Windows release。
Windows 使用仓库约定的本机 JDK/Gradle/Pub Cache/NuGet，仅对子进程生效。
退出码: 0 成功；2 用法错误；1 环境错误；子命令失败保留其退出码。
'@
}

function Invoke-Tool([string] $Tool, [string[]] $Arguments) {
    if (-not (Get-Command $Tool -CommandType Application -ErrorAction SilentlyContinue)) {
        throw "找不到 $Tool，请先安装并加入 PATH。"
    }
    Write-Host ("> {0} {1}" -f $Tool, ($Arguments -join ' '))
    & $Tool @Arguments
    if ($LASTEXITCODE -ne 0) {
        $script:ExitCode = $LASTEXITCODE
        throw "$Tool 失败，退出码 $LASTEXITCODE。"
    }
}

$cli = @($args)
if ($cli.Count -eq 0 -or $cli[0] -cin @('help', '-h', '--help') -or
    ($cli.Count -eq 2 -and $cli[1] -cin @('-h', '--help'))) {
    Show-Help
    exit 0
}

$command = $cli[0]
$tail = @($cli | Select-Object -Skip 1)
$isWindowsHost = $env:OS -eq 'Windows_NT'
$hostTarget = if ($isWindowsHost) { 'windows' } elseif ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::OSX)) { 'macos' } else { 'linux' }
$device = $hostTarget
$extra = @()
$target = 'apk'
$mode = 'release'

# 完成用法校验后才执行工具或修改环境。
try {
    switch -CaseSensitive ($command) {
        { $_ -cin @('run', 'frontend', 'logs') } {
            if ($tail.Count -gt 0 -and -not $tail[0].StartsWith('-')) {
                $device = $tail[0]
                $tail = @($tail | Select-Object -Skip 1)
                if ($device -in @('chrome', 'edge', 'web-server')) {
                    throw 'device 必须是原生设备 ID；本项目不支持 Web。'
                }
            }
            if ($tail.Count -gt 0) {
                if ($tail[0] -eq '--') {
                    $extra = @($tail | Select-Object -Skip 1)
                } elseif ($tail[0].StartsWith('-')) {
                    $extra = $tail
                } else {
                    throw 'Flutter 参数必须以 - 开头；可用 -- 透传。'
                }
                foreach ($flag in $extra) {
                    if ($flag -clike '-d*' -or $flag -cin @('--device-id', '--debug', '--release', '--profile') -or $flag.StartsWith('--device-id=')) {
                        throw '设备和 debug 模式由脚本管理，不能在透传参数中覆盖。'
                    }
                }
            }
        }
        'build' {
            if ($tail.Count -gt 2) { throw 'build 最多接收 target 和 mode。' }
            if ($tail.Count -gt 0) { $target = $tail[0] }
            if ($tail.Count -gt 1) { $mode = $tail[1] }
            if ($target -cnotin @('apk', 'windows', 'macos', 'linux', 'msi')) { throw "不支持的构建目标: $target" }
            if ($mode -cnotin @('release', 'debug')) { throw "不支持的构建模式: $mode" }
            if ($target -eq 'msi' -and $mode -ne 'release') { throw 'MSI 仅支持 release。' }
            $requiredHost = if ($target -eq 'msi') { 'windows' } else { $target }
            if ($target -ne 'apk' -and $requiredHost -ne $hostTarget) { throw "$target 需要在 $requiredHost 宿主上构建。" }
        }
        { $_ -cin @('setup', 'doctor', 'devices', 'generate', 'analyze', 'test', 'check', 'clean', 'data', 'verify-data') } {
            if ($tail.Count -gt 0) { throw "$command 不接收参数。" }
        }
        default { throw "未知命令: $command" }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    [Console]::Error.WriteLine('使用 .\dev.ps1 -h 查看帮助。')
    exit 2
}

$ExitCode = 0
$originalEnvironment = @{}
foreach ($key in @('JAVA_HOME', 'GRADLE_USER_HOME', 'PUB_CACHE', 'PYTHONUTF8', 'PATH')) {
    $originalEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
}
Push-Location $PSScriptRoot
try {
    $env:PYTHONUTF8 = '1'
    if ($isWindowsHost) {
        if (Test-Path 'D:\Develop\Java\jdk-21.0.7+6\bin\java.exe') {
            $env:JAVA_HOME = 'D:\Develop\Java\jdk-21.0.7+6'
        }
        $env:GRADLE_USER_HOME = Join-Path $env:USERPROFILE '.gradle'
        if (Test-Path 'D:\') { $env:PUB_CACHE = 'D:\pub-cache' }
        if (Test-Path 'D:\Develop\Tools\nuget\nuget.exe') { $env:PATH = "D:\Develop\Tools\nuget;$env:PATH" }
        if ($env:JAVA_HOME) { $env:PATH = "$(Join-Path $env:JAVA_HOME 'bin');$env:PATH" }
    }
    switch ($command) {
        'setup'       { Invoke-Tool flutter @('pub', 'get') }
        'doctor'      { Invoke-Tool flutter @('doctor', '-v') }
        'devices'     { Invoke-Tool flutter @('devices') }
        { $_ -in @('run', 'frontend') } { Invoke-Tool flutter (@('run', '--debug', '-d', $device) + $extra) }
        'logs'        { Invoke-Tool flutter (@('logs', '-d', $device) + $extra) }
        'build' {
            $flutterTarget = if ($target -eq 'msi') { 'windows' } else { $target }
            $buildArgs = @('build', $flutterTarget, "--$mode")
            if ($target -eq 'apk') { $buildArgs += '--split-per-abi' }
            Invoke-Tool flutter $buildArgs
            if ($target -eq 'msi') { Invoke-Tool uv @('run', 'tools/msi/build_msi.py') }
        }
        'generate'    { Invoke-Tool dart @('run', 'build_runner', 'build', '--delete-conflicting-outputs') }
        'analyze'     { Invoke-Tool flutter @('analyze') }
        'test'        { Invoke-Tool flutter @('test') }
        'check'       { Invoke-Tool flutter @('analyze'); Invoke-Tool flutter @('test') }
        'clean'       { Invoke-Tool flutter @('clean') }
        'data'        { Invoke-Tool uv @('run', 'tools/data_builder/build_all.py') }
        'verify-data' { Invoke-Tool uv @('run', 'tools/data_builder/verify.py') }
    }
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    if ($ExitCode -eq 0) { $ExitCode = 1 }
} finally {
    Pop-Location
    foreach ($key in $originalEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($key, $originalEnvironment[$key], 'Process')
    }
}
exit $ExitCode
