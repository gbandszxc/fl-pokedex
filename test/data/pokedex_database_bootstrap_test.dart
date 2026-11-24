import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_pokedex/core/di.dart';
import 'package:fl_pokedex/data/database/pokedex_database.dart';
import 'package:fl_pokedex/features/pokemon_detail/detail_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// path_provider 的平台接口只用于替换测试环境的文档目录。
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../helpers/sqlite_loader.dart';

class _TestDocuments extends PathProviderPlatform {
  _TestDocuments(this.path);

  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  loadSqliteForHostTests();

  test('旧版内置库会被替换，用户数据库不受影响', () async {
    final directory = await Directory.systemTemp.createTemp('pokedex-refresh-');
    final previousPaths = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _TestDocuments(directory.path);
    final container = ProviderContainer();
    final db = container.read(pokedexDatabaseProvider);
    addTearDown(() async {
      await db.close();
      container.dispose();
      PathProviderPlatform.instance = previousPaths;
      await directory.delete(recursive: true);
    });

    final pokedexFile = File('${directory.path}/pokedex.db');
    final oldDb = PokedexDatabase(
      NativeDatabase(pokedexFile, enableMigrations: false),
    );
    try {
      await oldDb.customStatement(
        'CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
      );
      await oldDb.customStatement(
        "INSERT INTO meta (key, value) VALUES ('schema_version', '5')",
      );
    } finally {
      await oldDb.close();
    }
    expect(await PokedexDatabase.storedSchemaVersion(pokedexFile), 5);
    final userFile = File('${directory.path}/user.db');
    await userFile.writeAsBytes(const [2, 5, 9]);

    final repository = container.read(pokedexRepositoryProvider);
    final flavors = await repository.getFlavorTexts(906);
    for (final (versionId, identifier, textStart) in const [
      (40, 'scarlet', '毛茸茸的体毛'),
      (41, 'violet', '通过身体发出的甜甜香气'),
    ]) {
      expect(
        flavors
            .where((entry) => entry.versionIdentifier == identifier)
            .map((entry) => entry.language),
        containsAll(const ['zh_hans', 'zh_hant', 'en']),
      );
      final display = resolveFlavorSelection(flavors, versionId).selected!;
      expect(display.entryForDisplay()?.language, 'zh_hans');
      expect(display.entryForDisplay()?.text, startsWith(textStart));
      expect(flavorFallbackLanguageLabel(display), isNull);
    }
    expect(await db.metaDao.getMetaValue('schema_version'), '6');
    expect(await userFile.readAsBytes(), const [2, 5, 9]);
  });
}
