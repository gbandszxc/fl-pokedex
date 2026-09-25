import 'dart:ffi';
import 'dart:io';

// sqlite3 是 drift 的传递依赖（pubspec.yaml 归脚手架单元所有，测试助手
// 不重复声明依赖）；仅此测试加载器需要 open.overrideFor 指向仓库内 DLL。
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

/// Windows 宿主跑 drift 测试前加载仓库内 sqlite3.dll
/// （architecture.md §10）。`flutter test` 的 cwd 是仓库根，相对路径可用；
/// 非 Windows 平台（CI/其他桌面端）交由默认加载逻辑处理。
///
/// 所有要打开 SQLite 库的测试 setup 中调用一次即可。
void loadSqliteForHostTests() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('tool/sqlite3/windows/sqlite3.dll'),
    );
  }
}
