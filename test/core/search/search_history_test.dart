import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/search/search_history.dart';

void main() {
  group('SearchHistory.add', () {
    test('新しい語が先頭に積まれる', () {
      final history = SearchHistory.empty().add('選挙').add('投票');
      expect(history.entries, <String>['投票', '選挙']);
      expect(history.length, 2);
    });

    test('全角空白は半角へ、連続空白は1つへ、前後空白は除去される', () {
      final history = SearchHistory.empty().add('  小選挙区\u3000\u3000比例  ');
      expect(history.entries, <String>['小選挙区 比例']);
    });

    test('空文字・空白のみは無視される', () {
      final base = SearchHistory.empty().add('選挙');
      expect(base.add('').entries, <String>['選挙']);
      expect(base.add('   ').entries, <String>['選挙']);
      expect(base.add('\u3000\u3000').entries, <String>['選挙']);
    });

    test('大小無視の重複は先頭へ移動する', () {
      final history = SearchHistory.empty().add('Vote').add('選挙').add('vote');
      expect(history.entries, <String>['vote', '選挙']);
    });

    test('重複時は表記が新しい入力で更新される', () {
      final history = SearchHistory.empty().add('vote').add('Vote');
      expect(history.entries, <String>['Vote']);
    });

    test('上限8件を超えると古いものから落ちる', () {
      var history = SearchHistory.empty();
      for (var i = 1; i <= 10; i++) {
        history = history.add('語$i');
      }
      expect(history.length, SearchHistory.maxEntries);
      expect(history.entries.first, '語10');
      expect(history.entries.last, '語3');
      expect(history.entries.contains('語1'), isFalse);
    });

    test('追加しても元のインスタンスは変わらない', () {
      final base = SearchHistory.empty().add('選挙');
      final next = base.add('投票');
      expect(base.entries, <String>['選挙']);
      expect(next.entries, <String>['投票', '選挙']);
    });

    test('entries は変更できない', () {
      final history = SearchHistory.empty().add('選挙');
      expect(() => history.entries.add('投票'), throwsUnsupportedError);
    });
  });

  group('SearchHistory.fromList', () {
    test('先頭が最新として扱い、正規化・重複排除・上限を適用する', () {
      final history = SearchHistory.fromList(<String>[
        '投票',
        ' 選挙 ',
        '投票',
        '',
      ]);
      expect(history.entries, <String>['投票', '選挙']);
    });

    test('9件以上は新しい8件だけ残す', () {
      final history = SearchHistory.fromList(
        List<String>.generate(12, (index) => '語$index'),
      );
      expect(history.length, SearchHistory.maxEntries);
      expect(history.entries.first, '語0');
      expect(history.entries.last, '語7');
    });
  });

  group('SearchHistory.encode/decode', () {
    test('符号化と復号で往復できる', () {
      final history = SearchHistory.empty().add('選挙').add('比例代表');
      expect(SearchHistory.decode(history.encode()).entries, history.entries);
    });

    test('null・空文字は空の履歴になる', () {
      expect(SearchHistory.decode(null).isEmpty, isTrue);
      expect(SearchHistory.decode('').isEmpty, isTrue);
    });

    test('壊れたJSONでも例外を投げず空になる', () {
      expect(SearchHistory.decode('{oops').isEmpty, isTrue);
      expect(SearchHistory.decode('not json at all').isEmpty, isTrue);
    });

    test('JSONがリストでなければ空になる', () {
      expect(SearchHistory.decode('{"a":1}').isEmpty, isTrue);
      expect(SearchHistory.decode('"選挙"').isEmpty, isTrue);
    });

    test('文字列以外の要素は捨てる', () {
      final history = SearchHistory.decode('["選挙",123,null,"投票"]');
      expect(history.entries, <String>['選挙', '投票']);
    });

    test('復号時も正規化と上限が効く', () {
      final history = SearchHistory.decode(
        '["  選挙  ","選挙",${List<String>.generate(9, (i) => '"語$i"').join(',')}]',
      );
      expect(history.length, SearchHistory.maxEntries);
      expect(history.entries.first, '選挙');
    });
  });
}
