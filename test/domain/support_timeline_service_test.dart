import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/models/support_timeline.dart';
import 'package:election_game/domain/services/support_timeline_service.dart';

void main() {
  final t0 = DateTime.utc(2026, 10, 24, 9, 0);
  final t1 = DateTime.utc(2026, 10, 24, 10, 0);
  final t2 = DateTime.utc(2026, 10, 24, 11, 0);

  SupportSimulation sim({
    String title = '秋の模擬選挙',
    String leaderId = 'cand_a',
    String leaderName = '候補者A',
    double leaderRate = 0.42,
    int voterCount = 10,
    String moodLabel = '穏やかな世論',
    bool empty = false,
  }) {
    if (empty) {
      return SupportSimulation(
        electionTitle: title,
        snapshots: const [],
        voterCount: voterCount,
        moodLabel: moodLabel,
        stubbornnessLabel: '慎重な世論',
        hasHistory: false,
      );
    }
    return SupportSimulation(
      electionTitle: title,
      snapshots: [
        SupportSnapshot(
          candidateId: leaderId,
          candidateName: leaderName,
          supportRate: leaderRate,
          rawAffinity: 0.5,
          supporterCount: 4,
        ),
        SupportSnapshot(
          candidateId: 'cand_z',
          candidateName: '候補者Z',
          supportRate: 1.0 - leaderRate,
          rawAffinity: 0.4,
          supporterCount: 6,
        ),
      ],
      voterCount: voterCount,
      moodLabel: moodLabel,
      stubbornnessLabel: '慎重な世論',
      hasHistory: false,
    );
  }

  SupportTimelineEntry entry(
    String id,
    DateTime at, {
    String leaderId = 'cand_a',
    double rate = 0.42,
  }) {
    return SupportTimelineEntry(
      id: id,
      recordedAt: at,
      electionTitle: '秋の模擬選挙',
      leaderCandidateId: leaderId,
      leaderCandidateName: '候補者A',
      leaderSupportRate: rate,
      voterCount: 10,
      moodLabel: '穏やかな世論',
    );
  }

  group('buildEntry', () {
    test('snapshots が空なら null', () {
      expect(
        SupportTimelineService.buildEntry(simulation: sim(empty: true), now: t0),
        isNull,
      );
    });

    test('首位候補者と世論情報を反映する', () {
      final e = SupportTimelineService.buildEntry(
        simulation: sim(leaderRate: 0.61, voterCount: 12, moodLabel: '熱狂'),
        now: t0,
      )!;
      expect(e.recordedAt, t0);
      expect(e.electionTitle, '秋の模擬選挙');
      expect(e.leaderCandidateId, 'cand_a');
      expect(e.leaderCandidateName, '候補者A');
      expect(e.leaderSupportRate, 0.61);
      expect(e.voterCount, 12);
      expect(e.moodLabel, '熱狂');
    });

    test('既定 id は now のマイクロ秒から生成する', () {
      final e = SupportTimelineService.buildEntry(simulation: sim(), now: t1)!;
      expect(e.id, 'support_${t1.microsecondsSinceEpoch}');
    });

    test('id を明示するとそれを使う', () {
      final e = SupportTimelineService.buildEntry(
        simulation: sim(),
        now: t1,
        id: 'fixed_id',
      )!;
      expect(e.id, 'fixed_id');
    });
  });

  group('sortAscending', () {
    test('recordedAt 昇順・同時刻は id 昇順で整列する', () {
      final input = [
        entry('b', t1),
        entry('c', t0),
        entry('a', t1),
        entry('d', t2),
      ];
      final sorted = SupportTimelineService.sortAscending(input);
      expect(sorted.map((e) => e.id).toList(), ['c', 'a', 'b', 'd']);
    });

    test('入力リストを破壊しない', () {
      final input = [entry('b', t1), entry('a', t0)];
      final before = input.map((e) => e.id).toList();
      SupportTimelineService.sortAscending(input);
      expect(input.map((e) => e.id).toList(), before);
    });
  });

  group('append', () {
    test('追加後に昇順で並ぶ', () {
      final result = SupportTimelineService.append(
        [entry('a', t0), entry('c', t2)],
        entry('b', t1),
      );
      expect(result.map((e) => e.id).toList(), ['a', 'b', 'c']);
    });

    test('同一 id は追加しない', () {
      final result = SupportTimelineService.append(
        [entry('a', t0)],
        entry('a', t2),
      );
      expect(result.length, 1);
      expect(result.single.recordedAt, t0);
    });

    test('limit を超えたら古い順に捨てる', () {
      final input = [entry('a', t0), entry('b', t1)];
      final result = SupportTimelineService.append(
        input,
        entry('c', t2),
        limit: 2,
      );
      expect(result.map((e) => e.id).toList(), ['b', 'c']);
    });

    test('limit <= 0 は ArgumentError', () {
      expect(
        () => SupportTimelineService.append([], entry('a', t0), limit: 0),
        throwsArgumentError,
      );
      expect(
        () => SupportTimelineService.append([], entry('a', t0), limit: -1),
        throwsArgumentError,
      );
    });

    test('入力リストを破壊しない', () {
      final input = [entry('a', t0)];
      SupportTimelineService.append(input, entry('b', t1));
      expect(input.map((e) => e.id).toList(), ['a']);
    });

    test('200件上限で新しい200件が残る', () {
      final many = List.generate(
        200,
        (i) => entry('id_${i.toString().padLeft(3, '0')}',
            t0.add(Duration(minutes: i))),
      );
      final result = SupportTimelineService.append(
        many,
        entry('id_200', t0.add(const Duration(minutes: 200))),
      );
      expect(result.length, 200);
      expect(result.first.id, 'id_001');
      expect(result.last.id, 'id_200');
    });
  });

  group('deltaAt', () {
    test('直前要素との差分を返す', () {
      final entries = [
        entry('a', t0, rate: 0.40),
        entry('b', t1, rate: 0.43),
      ];
      final d = SupportTimelineService.deltaAt(entries, 'b')!;
      expect(d.entryId, 'b');
      expect(d.previousEntryId, 'a');
      expect(d.shareDelta, closeTo(0.03, 1e-9));
      expect(d.leaderChanged, isFalse);
      expect(d.leaderChangeLabel, '');
      expect(d.deltaLabel, '+3.0pt');
    });

    test('首位が変わったら leaderChanged とラベルが立つ', () {
      final entries = [
        entry('a', t0, leaderId: 'cand_a', rate: 0.40),
        entry('b', t1, leaderId: 'cand_b', rate: 0.45),
      ];
      final d = SupportTimelineService.deltaAt(entries, 'b')!;
      expect(d.leaderChanged, isTrue);
      expect(d.leaderChangeLabel, '首位交代');
      expect(d.shareDelta, closeTo(0.05, 1e-9));
    });

    test('入力順が乱れていても時系列で判定する', () {
      final entries = [
        entry('b', t1, rate: 0.45),
        entry('a', t0, rate: 0.40),
      ];
      final d = SupportTimelineService.deltaAt(entries, 'b')!;
      expect(d.previousEntryId, 'a');
      expect(d.shareDelta, closeTo(0.05, 1e-9));
    });

    test('先頭要素は null', () {
      final entries = [entry('a', t0)];
      expect(SupportTimelineService.deltaAt(entries, 'a'), isNull);
    });

    test('未知の id は null', () {
      final entries = [entry('a', t0), entry('b', t1)];
      expect(SupportTimelineService.deltaAt(entries, 'zzz'), isNull);
    });

    test('空リストは null', () {
      expect(SupportTimelineService.deltaAt(const [], 'a'), isNull);
    });
  });

  group('recent', () {
    test('末尾 max 件を昇順のまま返す', () {
      final entries = [
        entry('d', t2),
        entry('a', t0),
        entry('c', t1.add(const Duration(minutes: 30))),
        entry('b', t1),
      ];
      final result = SupportTimelineService.recent(entries, max: 2);
      expect(result.map((e) => e.id).toList(), ['c', 'd']);
    });

    test('max <= 0 は空リスト', () {
      final entries = [entry('a', t0)];
      expect(SupportTimelineService.recent(entries, max: 0), isEmpty);
      expect(SupportTimelineService.recent(entries, max: -3), isEmpty);
    });

    test('件数が max 未満なら全件を昇順で返す', () {
      final entries = [entry('b', t1), entry('a', t0)];
      final result = SupportTimelineService.recent(entries);
      expect(result.map((e) => e.id).toList(), ['a', 'b']);
    });
  });

  group('trendLabel', () {
    test('0件は「記録なし」', () {
      expect(SupportTimelineService.trendLabel(const []), '記録なし');
    });

    test('1件は「初回の記録」', () {
      expect(
        SupportTimelineService.trendLabel([entry('a', t0)]),
        '初回の記録',
      );
    });

    test('2件以上は前回との差分を表示する', () {
      final entries = [
        entry('a', t0, rate: 0.40),
        entry('b', t1, rate: 0.43),
      ];
      expect(
        SupportTimelineService.trendLabel(entries),
        '前回から +3.0pt',
      );
    });

    test('差分が微小なら ±0.0pt', () {
      final entries = [
        entry('a', t0, rate: 0.40),
        entry('b', t1, rate: 0.4001),
      ];
      expect(
        SupportTimelineService.trendLabel(entries),
        '前回から ±0.0pt',
      );
    });
  });
}
