import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/search/search_history.dart';

/// 検索履歴の保存先を抽象化した窓口（テストで差し替え可能にする）。
abstract class SearchHistoryStore {
  /// 保存済みの履歴を新しい順で返す。失敗時は空。
  Future<List<String>> load();

  /// 履歴を保存する。失敗しても例外は投げない。
  Future<void> save(List<String> entries);
}

/// SharedPreferences 実装。
class SharedPreferencesSearchHistoryStore implements SearchHistoryStore {
  const SharedPreferencesSearchHistoryStore();

  /// 保存キー（形式変更時は v2 へ上げる）。
  static const String storageKey = 'glossary_search_history_v1';

  @override
  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return SearchHistory.decode(prefs.getString(storageKey)).entries;
    } catch (_) {
      // プラグイン未初期化（テスト・起動直後）でも画面を壊さない。
      return const <String>[];
    }
  }

  @override
  Future<void> save(List<String> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        storageKey,
        SearchHistory.fromList(entries).encode(),
      );
    } catch (_) {
      // 保存失敗は無視する（履歴は補助機能）。
    }
  }
}
