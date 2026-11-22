import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchHistoryProvider =
    AsyncNotifierProvider<SearchHistory, List<String>>(SearchHistory.new);

class SearchHistory extends AsyncNotifier<List<String>> {
  static const _prefsKey = 'search_history';
  static const _limit = 20;

  Future<bool> _pendingWrite = Future.value(true);

  @override
  Future<List<String>> build() async {
    final prefs = await SharedPreferences.getInstance();
    return List.unmodifiable(prefs.getStringList(_prefsKey) ?? const []);
  }

  Future<bool> record(String query) {
    final term = query.trim();
    if (term.isEmpty) return Future.value(true);
    final key = term.toLowerCase();
    return _update((current) => [
          term,
          ...current.where((entry) => entry.toLowerCase() != key),
        ].take(_limit).toList());
  }

  Future<bool> remove(String term) =>
      _update((current) => current.where((entry) => entry != term).toList());

  Future<bool> clear() => _update((_) => const []);

  Future<bool> _update(List<String> Function(List<String>) change) {
    // 每次从上一次成功写入的记录继续修改，避免连续操作相互覆盖。
    return _pendingWrite = _pendingWrite.then((_) async {
      try {
        final current = await future;
        final next = change(current);
        if (listEquals(current, next)) return true;

        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setStringList(_prefsKey, next)) return false;
        state = AsyncData(List.unmodifiable(next));
        return true;
      } on Object catch (error) {
        debugPrint('search_history write failed: ${error.runtimeType}');
        return false;
      }
    });
  }
}
