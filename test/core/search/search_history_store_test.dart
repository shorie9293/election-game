import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/search/search_history.dart';
import 'package:election_game/core/search/search_history_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const store = SharedPreferencesSearchHistoryStore();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('保存した履歴を同じ順序で読み戻せる', () async {
    await store.save(<String>['投票', '選挙']);
    expect(await store.load(), <String>['投票', '選挙']);
  });

  test('保存キーは glossary_search_history_v1 である', () async {
    await store.save(<String>['選挙']);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('glossary_search_history_v1'), isNotNull);
    expect(
      SharedPreferencesSearchHistoryStore.storageKey,
      'glossary_search_history_v1',
    );
  });

  test('保存値は符号化されたJSONで復号可能', () async {
    await store.save(<String>['選挙', '投票']);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      SharedPreferencesSearchHistoryStore.storageKey,
    );
    expect(SearchHistory.decode(raw).entries, <String>['選挙', '投票']);
  });

  test('未保存なら空を返す', () async {
    expect(await store.load(), isEmpty);
  });

  test('破損した保存値でも空を返し例外を投げない', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      SharedPreferencesSearchHistoryStore.storageKey: '{broken',
    });
    expect(await store.load(), isEmpty);
  });

  test('保存時に正規化・重複排除・上限8件が適用される', () async {
    await store.save(<String>[
      ' 選挙 ',
      '選挙',
      for (var i = 0; i < 10; i++) '語$i',
    ]);
    final loaded = await store.load();
    expect(loaded.first, '選挙');
    expect(loaded.length, SearchHistory.maxEntries);
    expect(loaded.where((value) => value == '選挙').length, 1);
  });
}
