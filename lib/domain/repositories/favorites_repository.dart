/// 用户个人数据仓储（architecture.md §4，签名逐字锁死）。
abstract class FavoritesRepository {
  Stream<List<int>> watchFavoriteSpeciesIds();

  Future<void> toggleFavorite(int speciesId);

  Stream<List<int>> watchRecentSpeciesIds();

  /// 上限 30，去重取最新。
  Future<void> addRecent(int speciesId);
}
