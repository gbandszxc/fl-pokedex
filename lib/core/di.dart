import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/database/pokedex_database.dart';
import '../data/database/user_database.dart';
import '../data/repository/favorites_repository_impl.dart';
import '../data/repository/pokedex_repository_impl.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/repositories/pokedex_repository.dart';

/// 本文件是数据层唯一的 Flutter 胶水层：lib/data/** 下的文件必须保持
/// 纯 Dart 依赖（drift_dev codegen 会完整 resolve 白名单内的每个文件，
/// 引入 Flutter SDK 源码会让 analyzer 7.x 的 summary writer 崩溃）。

/// 图鉴只读库（architecture.md §5 命名锁死）。
///
/// 惰性打开：首次被仓储访问时才执行复制/连接；Provider 非 autoDispose，
/// 应用生命周期内保活。
///
/// 复制策略（architecture.md §6）：文档目录不存在 pokedex.db 时从
/// assets 复制；已存在则比对 meta.schema_version 与 manifest.json 的
/// schemaVersion，不一致（含文件损坏）则覆盖复制，预留给未来数据升级。
final pokedexDatabaseProvider = Provider<PokedexDatabase>((ref) {
  final db = PokedexDatabase(LazyDatabase(() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(docsDir.path, 'pokedex.db'));

    final expectedVersion = await _manifestSchemaVersion();
    final localVersion = await PokedexDatabase.storedSchemaVersion(file);
    if (localVersion != expectedVersion) {
      final bytes = await rootBundle.load(PokedexDatabase.assetDbPath);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );
    }
    return PokedexDatabase.readOnlyExecutor(file);
  }));
  ref.onDispose(db.close);
  return db;
});

/// 用户个人数据可写库（favorites / recents）。
final userDatabaseProvider = Provider<UserDatabase>((ref) {
  final db = UserDatabase(
    LazyDatabase(() async {
      final docsDir = await getApplicationDocumentsDirectory();
      return NativeDatabase(File(p.join(docsDir.path, 'user.db')));
    }),
  );
  ref.onDispose(db.close);
  return db;
});

/// 图鉴数据仓储。
final pokedexRepositoryProvider = Provider<PokedexRepository>((ref) {
  return PokedexRepositoryImpl(
    ref.watch(pokedexDatabaseProvider),
    loadManifestJson: _loadManifestJson,
  );
});

/// 收藏/最近浏览仓储。
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(userDatabaseProvider));
});

/// manifest.json → JSON 对象（离线守卫下 rootBundle 资产读取安全）。
Future<Map<String, dynamic>> _loadManifestJson() async {
  final raw =
      await rootBundle.loadString(PokedexDatabase.assetManifestPath);
  return jsonDecode(raw) as Map<String, dynamic>;
}

Future<int> _manifestSchemaVersion() async =>
    (await _loadManifestJson())['schemaVersion'] as int;
