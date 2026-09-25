import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_pokedex/data/database/user_database.dart';
import 'package:fl_pokedex/data/repository/favorites_repository_impl.dart';
import 'package:fl_pokedex/domain/repositories/favorites_repository.dart';

import '../helpers/sqlite_loader.dart';

/// UserDatabase（内存库）+ FavoritesRepositoryImpl 的行为验证。
void main() {
  loadSqliteForHostTests();

  late UserDatabase db;
  late FavoritesRepository repo;

  setUp(() {
    db = UserDatabase(NativeDatabase.memory());
    repo = FavoritesRepositoryImpl(db);
  });

  tearDown(() => db.close());

  /// Windows 宿主 DateTime.now() 精度有限，连发写入可能拿到相同时间戳；
  /// 间隔数毫秒模拟真实浏览节奏，保证时间可比。
  Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 3));

  group('收藏', () {
    test('toggleFavorite 添加后再次切换即移除，watch 推送变化', () async {
      final emissions = <List<int>>[];
      final sub = repo.watchFavoriteSpeciesIds().listen(emissions.add);
      await pumpEventQueue();
      expect(emissions.first, isEmpty); // 初始空列表

      await repo.toggleFavorite(25);
      await pumpEventQueue();
      expect(emissions.last, [25]);

      await tick();
      await repo.toggleFavorite(133);
      await pumpEventQueue();
      expect(emissions.last, [133, 25]); // 新收藏在前（created_at DESC）

      await repo.toggleFavorite(25);
      await pumpEventQueue();
      expect(emissions.last, [133]);

      await sub.cancel();
    });
  });

  group('最近浏览', () {
    test('addRecent 去重取最新且上限 30 条', () async {
      for (var i = 1; i <= 35; i++) {
        await repo.addRecent(i);
        await tick();
      }
      final list = await repo.watchRecentSpeciesIds().first;
      expect(list, hasLength(30)); // 上限
      expect(list.first, 35); // 最新在前
      expect(list, contains(6));
      expect(list, isNot(contains(5))); // 最旧的 1..5 被裁剪
      expect(list, equals(List<int>.generate(30, (i) => 35 - i)));

      // 重复浏览 #6 → 移到最新位，总量不变
      await repo.addRecent(6);
      final updated = await repo.watchRecentSpeciesIds().first;
      expect(updated.first, 6);
      expect(updated, hasLength(30));
      expect(updated[1], 35); // 原"最新"退居第二
    });

    test('watchRecentSpeciesIds 推送写入后的最新状态', () async {
      final emissions = <List<int>>[];
      final sub = repo.watchRecentSpeciesIds().listen(emissions.add);
      await pumpEventQueue();
      expect(emissions.first, isEmpty);

      await repo.addRecent(1);
      await tick();
      await repo.addRecent(2);
      await pumpEventQueue();
      expect(emissions.last, [2, 1]);

      await sub.cancel();
    });
  });
}
