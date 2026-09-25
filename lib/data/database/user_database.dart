import 'package:drift/drift.dart';

part 'user_database.g.dart';

/// 收藏（species_id 为主键，created_at 为 ISO8601 UTC 文本）。
@DataClassName('FavoriteRow')
class Favorites extends Table {
  @override
  String get tableName => 'favorites';

  IntColumn get speciesId => integer().named('species_id')();

  TextColumn get createdAt => text().named('created_at')();

  @override
  Set<Column> get primaryKey => {speciesId};
}

/// 最近浏览（species_id 为主键，viewed_at 为 ISO8601 UTC 文本，上限 30 条）。
@DataClassName('RecentRow')
class Recents extends Table {
  @override
  String get tableName => 'recents';

  IntColumn get speciesId => integer().named('species_id')();

  TextColumn get viewedAt => text().named('viewed_at')();

  @override
  Set<Column> get primaryKey => {speciesId};
}

/// 用户个人数据可写库（与只读图鉴库分离，随应用存档）。
///
/// 执行器由外部注入（应用侧在 lib/core/di.dart 组装 LazyDatabase），
/// 本文件保持纯 Dart 依赖——codegen 需要完整 resolve 本库。
@DriftDatabase(tables: [Favorites, Recents])
class UserDatabase extends _$UserDatabase {
  UserDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
