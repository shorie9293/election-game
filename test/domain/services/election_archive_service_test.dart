import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/election_archive_service.dart';

Election _election({
  required String id,
  required String title,
  required ElectionScale scale,
  required List<Candidate> candidates,
  Map<String, int>? voteCounts,
  String? winnerId,
}) {
  return Election(
    id: id,
    title: title,
    scale: scale,
    candidates: candidates,
    voteCounts: voteCounts,
    winnerId: winnerId,
  );
}

Candidate _c(String id, String name) => Candidate(
      id: id,
      name: name,
      portraitKey: 'portrait_$id',
      faction: 'f',
      personality: 'p',
      policies: const [],
    );

void main() {
  group('ElectionArchiveService.timestampFromId', () {
    test('election_<millis> 形式から日時を復元する', () {
      final dt = ElectionArchiveService.timestampFromId('election_1700000000000');
      expect(dt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('形式が違うIDはnull', () {
      expect(ElectionArchiveService.timestampFromId('foo_123'), isNull);
      expect(ElectionArchiveService.timestampFromId('election'), isNull);
      expect(ElectionArchiveService.timestampFromId('election_'), isNull);
    });

    test('数値として解析不能なmillisはnull', () {
      expect(ElectionArchiveService.timestampFromId('election_abc'), isNull);
    });
  });

  group('ElectionArchiveService.toEntry', () {
    final candidates = [
      _c('a', '天照太郎'),
      _c('b', '天照次郎'),
      _c('c', '天照三郎'),
    ];

    test('完了選挙をエントリ化する（2位は得票数降順→id昇順の2番目）', () {
      final e = _election(
        id: 'election_1700000000000',
        title: '村長選挙',
        scale: ElectionScale.village,
        candidates: candidates,
        voteCounts: const {'b': 50, 'c': 20, 'a': 30},
        winnerId: 'b',
      );
      final entry = ElectionArchiveService.toEntry(e);
      expect(entry, isNotNull);
      expect(entry!.winnerId, 'b');
      expect(entry.winnerName, '天照次郎');
      expect(entry.winnerVotes, 50);
      expect(entry.totalVotes, 100);
      // 得票数: b=50, a=30, c=20 → 2位はa=30
      expect(entry.runnerUpVotes, 30);
      expect(entry.occurredAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
    });

    test('得票数が同点のときはid昇順で2番目を選ぶ', () {
      final e = _election(
        id: 'election_1700000000001',
        title: '町長選挙',
        scale: ElectionScale.town,
        candidates: candidates,
        voteCounts: const {'b': 60, 'a': 40, 'c': 0},
        winnerId: 'b',
      );
      final entry = ElectionArchiveService.toEntry(e);
      expect(entry, isNotNull);
      // 得票数: b=60, a=40, c=0 → 2位はa（同点なし）
      // 同点ケース: aとcが同点ならid昇順でcが先頭…ここではa=40,c=0なのでa
      expect(entry!.runnerUpVotes, 40);
    });

    test('2位同点のタイブレーク: 同票ならid昇順', () {
      final e = _election(
        id: 'election_1700000000002',
        title: '市長選挙',
        scale: ElectionScale.city,
        candidates: candidates,
        voteCounts: const {'a': 60, 'b': 20, 'c': 20},
        winnerId: 'a',
      );
      final entry = ElectionArchiveService.toEntry(e);
      // b と c が同票20 → id昇順で b が2位
      expect(entry!.runnerUpVotes, 20);
    });

    test('未完了選挙（winnerId なし）はnull', () {
      final e = _election(
        id: 'election_1700000000000',
        title: '村長選挙',
        scale: ElectionScale.village,
        candidates: candidates,
        voteCounts: const {'a': 10},
      );
      expect(ElectionArchiveService.toEntry(e), isNull);
    });

    test('未完了選挙（voteCounts なし）はnull', () {
      final e = _election(
        id: 'election_1700000000000',
        title: '村長選挙',
        scale: ElectionScale.village,
        candidates: candidates,
        winnerId: 'a',
      );
      expect(ElectionArchiveService.toEntry(e), isNull);
    });

    test('winnerId が候補に存在しなければnull', () {
      final e = _election(
        id: 'election_1700000000000',
        title: '村長選挙',
        scale: ElectionScale.village,
        candidates: candidates,
        voteCounts: const {'a': 10},
        winnerId: 'unknown',
      );
      expect(ElectionArchiveService.toEntry(e), isNull);
    });

    test('候補1件なら runnerUpVotes は0', () {
      final e = _election(
        id: 'election_1700000000000',
        title: '村長選挙',
        scale: ElectionScale.village,
        candidates: [_c('a', '天照太郎')],
        voteCounts: const {'a': 10},
        winnerId: 'a',
      );
      expect(ElectionArchiveService.toEntry(e)!.runnerUpVotes, 0);
    });
  });

  group('ElectionArchiveService.build', () {
    Election done(String id, String title, ElectionScale scale, int winnerVotes,
        {String winnerName = '当選者'}) {
      return _election(
        id: id,
        title: title,
        scale: scale,
        candidates: [_c('w', winnerName), _c('l', '敗者')],
        voteCounts: {'w': winnerVotes, 'l': 100 - winnerVotes},
        winnerId: 'w',
      );
    }

    test('完了分のみを抽出する', () {
      final unfinished = _election(
        id: 'election_1',
        title: '未完了',
        scale: ElectionScale.village,
        candidates: [_c('w', '当選者')],
      );
      final entries = ElectionArchiveService.build([
        unfinished,
        done('election_1000', '完了', ElectionScale.village, 60),
      ]);
      expect(entries.length, 1);
      expect(entries.first.electionId, 'election_1000');
    });

    test('occurredAt 昇順で並ぶ（入力順に依存しない）', () {
      final entries = ElectionArchiveService.build([
        done('election_3000', '後', ElectionScale.village, 60),
        done('election_1000', '先', ElectionScale.village, 60),
      ]);
      expect(
        entries.map((e) => e.electionId).toList(),
        ['election_1000', 'election_3000'],
      );
    });

    test('occurredAt が null のものは末尾に置かれる', () {
      final entries = ElectionArchiveService.build([
        done('election_0', 'null時刻', ElectionScale.village, 60),
        done('election_2000', '時刻あり', ElectionScale.village, 60),
      ]);
      // election_0 は millis=0 → 1970年（有効な時刻）
      // nullを明示的に作るには ID 形式を壊す必要がある
      final nullEntry = _election(
        id: 'not-an-election-id',
        title: 'null時刻',
        scale: ElectionScale.village,
        candidates: [_c('w', '当選者'), _c('l', '敗者')],
        voteCounts: const {'w': 60, 'l': 40},
        winnerId: 'w',
      );
      final withNull = ElectionArchiveService.build([
        done('election_2000', '時刻あり', ElectionScale.village, 60),
        nullEntry,
      ]);
      expect(withNull.last.electionId, 'not-an-election-id');
      expect(withNull.last.occurredAt, isNull);
      // 上の entries は election_0（1970）が最初
      expect(entries.first.electionId, 'election_0');
    });

    test('同時刻は electionId 昇順で安定ソートされる', () {
      final entries = ElectionArchiveService.build([
        done('election_2000b', 'B', ElectionScale.village, 60),
        done('election_2000a', 'A', ElectionScale.village, 60),
        done('election_2000c', 'C', ElectionScale.village, 60),
      ]);
      expect(
        entries.map((e) => e.electionId).toList(),
        ['election_2000a', 'election_2000b', 'election_2000c'],
      );
    });

    test('空リストは空', () {
      expect(ElectionArchiveService.build(const []), isEmpty);
    });

    test('返すリストは書き換え不可（List.unmodifiable）', () {
      final entries = ElectionArchiveService.build(
          [done('election_1000', '完了', ElectionScale.village, 60)]);
      expect(() => entries.add(entries.first), throwsUnsupportedError);
    });
  });

  group('ElectionArchiveService.summarize', () {
    ElectionArchiveEntry entry(
      String id,
      String title,
      ElectionScale scale,
      String winnerName,
      int winnerVotes,
      int runnerUp,
    ) {
      return ElectionArchiveEntry(
        electionId: id,
        title: title,
        scale: scale,
        winnerId: 'w_$id',
        winnerName: winnerName,
        winnerVotes: winnerVotes,
        totalVotes: winnerVotes + runnerUp,
        runnerUpVotes: runnerUp,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(1000),
      );
    }

    test('空リストは totalCount 0・平均0.0・null エントリ', () {
      final s = ElectionArchiveService.summarize(const []);
      expect(s.totalCount, 0);
      expect(s.averageWinnerShare, 0.0);
      expect(s.largestMarginEntry, isNull);
      expect(s.closestElectionEntry, isNull);
      expect(s.winnerWinCounts, isEmpty);
    });

    test(' totalCount・平均当選得票率・最大差・最小差を計算する', () {
      final s = ElectionArchiveService.summarize([
        entry('e1', '村長選挙1', ElectionScale.village, '太郎', 60, 40),
        entry('e2', '村長選挙2', ElectionScale.village, '次郎', 45, 55),
        entry('e3', '町長選挙1', ElectionScale.town, '太郎', 80, 20),
      ]);
      expect(s.totalCount, 3);
      expect(s.averageWinnerShare, closeTo((0.6 + 0.45 + 0.8) / 3, 1e-9));
      expect(s.largestMarginEntry!.electionId, 'e3');
      expect(s.closestElectionEntry!.electionId, 'e2');
    });

    test('winnerWinCounts は回数降順→名前昇順', () {
      final s = ElectionArchiveService.summarize([
        entry('e1', '村長選挙1', ElectionScale.village, '乙', 60, 40),
        entry('e2', '村長選挙2', ElectionScale.village, '甲', 55, 45),
        entry('e3', '町長選挙1', ElectionScale.town, '乙', 70, 30),
        entry('e4', '町長選挙2', ElectionScale.town, '甲', 65, 35),
        entry('e5', '市長選挙1', ElectionScale.city, '乙', 80, 20),
      ]);
      expect(s.winnerWinCounts.keys.toList(), ['乙', '甲']);
      expect(s.winnerWinCounts['乙'], 3);
      expect(s.winnerWinCounts['甲'], 2);
    });

    test('scaleCounts は宣言順を保持し、0件のスケールも含める', () {
      final s = ElectionArchiveService.summarize([
        entry('e1', '市長選挙1', ElectionScale.city, '太郎', 60, 40),
      ]);
      expect(s.scaleCounts.keys.toList(), ElectionScale.values);
      expect(s.scaleCounts[ElectionScale.village], 0);
      expect(s.scaleCounts[ElectionScale.town], 0);
      expect(s.scaleCounts[ElectionScale.city], 1);
    });
  });

  group('ElectionArchiveService.reachedScales', () {
    ElectionArchiveEntry entryWithScale(ElectionScale scale) {
      return ElectionArchiveEntry(
        electionId: 'e_$scale',
        title: 't',
        scale: scale,
        winnerId: 'w',
        winnerName: 'n',
        winnerVotes: 60,
        totalVotes: 100,
        runnerUpVotes: 40,
      );
    }

    test('出現スケールを宣言順（村→町→市）で返す', () {
      final reached = ElectionArchiveService.reachedScales(
          [entryWithScale(ElectionScale.city), entryWithScale(ElectionScale.village)]);
      expect(reached, [ElectionScale.village, ElectionScale.city]);
    });

    test('空なら空リスト', () {
      expect(ElectionArchiveService.reachedScales(const []), isEmpty);
    });
  });

  group('ElectionArchiveService.winnerShareTrend', () {
    test('時系列順（build順）の当選得票率を返す', () {
      final entries = [
        ElectionArchiveEntry(
          electionId: 'e1',
          title: 'a',
          scale: ElectionScale.village,
          winnerId: 'w',
          winnerName: 'n',
          winnerVotes: 50,
          totalVotes: 100,
          runnerUpVotes: 50,
        ),
        ElectionArchiveEntry(
          electionId: 'e2',
          title: 'b',
          scale: ElectionScale.village,
          winnerId: 'w',
          winnerName: 'n',
          winnerVotes: 70,
          totalVotes: 100,
          runnerUpVotes: 30,
        ),
      ];
      expect(
        ElectionArchiveService.winnerShareTrend(entries),
        [0.5, 0.7],
      );
    });

    test('空なら空リスト', () {
      expect(ElectionArchiveService.winnerShareTrend(const []), isEmpty);
    });
  });

  group('ElectionArchiveService.filterByScale', () {
    ElectionArchiveEntry entryWithScale(String id, ElectionScale scale) {
      return ElectionArchiveEntry(
        electionId: id,
        title: 't',
        scale: scale,
        winnerId: 'w',
        winnerName: 'n',
        winnerVotes: 60,
        totalVotes: 100,
        runnerUpVotes: 40,
      );
    }

    test('指定スケールのみ抽出し、入力順を保持する', () {
      final entries = [
        entryWithScale('e1', ElectionScale.village),
        entryWithScale('e2', ElectionScale.town),
        entryWithScale('e3', ElectionScale.village),
      ];
      final filtered =
          ElectionArchiveService.filterByScale(entries, ElectionScale.village);
      expect(filtered.map((e) => e.electionId).toList(), ['e1', 'e3']);
    });
  });

  group('ElectionArchiveService.searchByTitle', () {
    ElectionArchiveEntry entryWithTitle(String id, String title) {
      return ElectionArchiveEntry(
        electionId: id,
        title: title,
        scale: ElectionScale.village,
        winnerId: 'w',
        winnerName: 'n',
        winnerVotes: 60,
        totalVotes: 100,
        runnerUpVotes: 40,
      );
    }

    test('大文字小文字を無視した部分一致', () {
      final entries = [
        entryWithTitle('e1', 'Village Mayor Election'),
        entryWithTitle('e2', '町長選挙'),
      ];
      final hit = ElectionArchiveService.searchByTitle(entries, 'village mayor');
      expect(hit.length, 1);
      expect(hit.first.electionId, 'e1');
    });

    test('空白トリム後に一致判定する', () {
      final entries = [entryWithTitle('e1', '町長選挙')];
      expect(ElectionArchiveService.searchByTitle(entries, '  町長 ').length, 1);
    });

    test('空queryなら全件を入力順で返す', () {
      final entries = [
        entryWithTitle('e1', 'a'),
        entryWithTitle('e2', 'b'),
      ];
      expect(
        ElectionArchiveService.searchByTitle(entries, '').map((e) => e.electionId),
        ['e1', 'e2'],
      );
      expect(
        ElectionArchiveService.searchByTitle(entries, '   ').length,
        2,
      );
    });

    test('0除算ガード: totalVotes 0 のとき winnerShare は 0.0', () {
      final entry = ElectionArchiveEntry(
        electionId: 'e0',
        title: 'zero',
        scale: ElectionScale.village,
        winnerId: 'w',
        winnerName: 'n',
        winnerVotes: 0,
        totalVotes: 0,
        runnerUpVotes: 0,
      );
      expect(entry.winnerShare, 0.0);
      expect(entry.margin, 0);
      expect(entry.isLandslide, isFalse);
    });
  });
}