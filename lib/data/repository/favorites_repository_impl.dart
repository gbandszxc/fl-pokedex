import 'package:drift/drift.dart';

import '../../domain/repositories/favorites_repository.dart';
import '../database/user_database.dart';

/// [FavoritesRepository] 的 drift 实现。
///
/// watch() 基于 drift 的表更新流：任何写入提交后自动推送最新列表。
class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._db);

  final UserDatabase _db;

  static const int maxRecents = 30;

  @override
  Stream<List<int>> watchFavoriteSpeciesIds() =>
      (_db.select(_db.favorites)
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.createdAt),
              (tbl) => OrderingTerm.desc(tbl.speciesId), // 时间并列时确定性排序
            ]))
          .map((row) => row.speciesId)
          .watch();

  @override
  Future<void> toggleFavorite(int speciesId) => _db.transaction(() async {
        final existing = await (_db.select(_db.favorites)
              ..where((tbl) => tbl.speciesId.equals(speciesId)))
            .getSingleOrNull();
        if (existing == null) {
          await (_db.into(_db.favorites)).insert(
            FavoritesCompanion.insert(
              speciesId: Value(speciesId),
              createdAt: _nowIso(),
            ),
          );
        } else {
          await (_db.delete(_db.favorites)
                ..where((tbl) => tbl.speciesId.equals(speciesId)))
              .go();
        }
      });

  @override
  Stream<List<int>> watchRecentSpeciesIds() =>
      (_db.select(_db.recents)
            ..orderBy([
              (tbl) => OrderingTerm.desc(tbl.viewedAt),
              (tbl) => OrderingTerm.desc(tbl.speciesId), // 与裁剪语句同一 tiebreak
            ]))
          .map((row) => row.speciesId)
          .watch();

  @override
  Future<void> addRecent(int speciesId) => _db.transaction(() async {
        // 去重取最新：主键冲突时刷新 viewed_at。
        await (_db.into(_db.recents)).insertOnConflictUpdate(
          RecentRow(speciesId: speciesId, viewedAt: _nowIso()),
        );
        // 保持 ≤ 30 条：删掉最新 30 条以外的旧行（species_id 兜底打破并列）。
        await _db.customStatement(
          'DELETE FROM recents WHERE species_id NOT IN ('
          'SELECT species_id FROM recents '
          'ORDER BY viewed_at DESC, species_id DESC LIMIT $maxRecents)',
        );
      });

  static String _nowIso() => DateTime.now().toUtc().toIso8601String();
}
