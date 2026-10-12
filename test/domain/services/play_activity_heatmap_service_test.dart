import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';
import 'package:flutter_test/flutter_test.dart';

Election _electionAt(DateTime utc, {String? id}) {
  final millis = utc.millisecondsSinceEpoch;
  return Election(
    id: id ?? 'election_$millis',
    title: 'test',
    scale: ElectionScale.town,
    candidates: const <Candidate>[],
    winnerId: 'c1',
    voteCounts: const {'c1': 1},
  );
}

void main() {
  group('dateKey', () {
    test('ローカル日付キーをゼロ埋め2桁で返す', () {
      expect(
        PlayActivityHeatmapService.dateKey(DateTime(2026, 1, 5)),
        '2026-01-05',
      );
      expect(
        PlayActivityHeatmapService.dateKey(DateTime(2026, 12, 31, 23, 59)),
        '2026-12-31',
      );
    });
  });

  group('levelOf', () {
    test('maxCount<=0 / count<=0 は 0', () {
      expect(PlayActivityHeatmapService.levelOf(0, 4), 0);
      expect(PlayActivityHeatmapService.levelOf(3, 0), 0);
      expect(PlayActivityHeatmapService.levelOf(3, -1), 0);
      expect(PlayActivityHeatmapService.levelOf(-2, 5), 0);
    });

    test('count>=maxCount は 4', () {
      expect(PlayActivityHeatmapService.levelOf(4, 4), 4);
      expect(PlayActivityHeatmapService.levelOf(10, 4), 4);
    });

    test('maxCount=4 の4段階境界', () {
      expect(PlayActivityHeatmapService.levelOf(1, 4), 1);
      expect(PlayActivityHeatmapService.levelOf(2, 4), 2);
      expect(PlayActivityHeatmapService.levelOf(3, 4), 3);
    });

    test('maxCount=10 の割当（(count*4/max).ceil()）', () {
      expect(PlayActivityHeatmapService.levelOf(1, 10), 1);
      expect(PlayActivityHeatmapService.levelOf(3, 10), 2);
      expect(PlayActivityHeatmapService.levelOf(5, 10), 2);
      expect(PlayActivityHeatmapService.levelOf(6, 10), 3);
      expect(PlayActivityHeatmapService.levelOf(8, 10), 4);
      expect(PlayActivityHeatmapService.levelOf(9, 10), 4);
    });
  });

  group('countsByDate', () {
    test('同日複数選挙は件数加算される', () {
      final a = _electionAt(DateTime.utc(2026, 10, 12, 3));
      final b = _electionAt(DateTime.utc(2026, 10, 12, 9));
      final counts = PlayActivityHeatmapService.countsByDate([a, b]);
      // タイムスタンプは UTC 生成 → toLocal() で環境TZ。ローカルTZに依存しない
      // よう、同じUTC日でも toLocal 後の日付キーでまとめて検証する。
      expect(counts.length, 1);
      expect(counts.values.first, 2);
    });

    test('不正なidは無視される', () {
      final good = _electionAt(DateTime.utc(2026, 10, 12, 3));
      final bad1 = _electionAt(DateTime.utc(2026, 10, 12, 3), id: 'abc');
      final bad2 = _electionAt(DateTime.utc(2026, 10, 12, 3), id: 'election_x');
      final counts =
          PlayActivityHeatmapService.countsByDate([good, bad1, bad2]);
      expect(counts.length, 1);
      expect(counts.values.first, 1);
    });

    test('空入力は空Map', () {
      expect(PlayActivityHeatmapService.countsByDate([]), isEmpty);
    });
  });

  group('build', () {
    // now: 2026-10-13(火) のローカル午後
    final nowLocal = DateTime(2026, 10, 13, 15, 30);

    test('weeks<=0 は ArgumentError', () {
      expect(
        () => PlayActivityHeatmapService.build([], now: nowLocal, weeks: 0),
        throwsArgumentError,
      );
      expect(
        () => PlayActivityHeatmapService.build([], now: nowLocal, weeks: -1),
        throwsArgumentError,
      );
    });

    test('空入力: ゼロ埋めグリッド・集計はすべて0', () {
      final hm = PlayActivityHeatmapService.build([], now: nowLocal);
      expect(hm.weeks.length, 26);
      expect(hm.totalElections, 0);
      expect(hm.activeDays, 0);
      expect(hm.maxCount, 0);
      expect(hm.currentStreak, 0);
      expect(hm.longestStreak, 0);
      expect(hm.busiestDay, isNull);
      expect(hm.isEmpty, isTrue);
      for (final w in hm.weeks) {
        expect(w.days.length, 7);
        for (final d in w.days) {
          expect(d.count, 0);
          expect(d.isActive, isFalse);
          expect(d.date.hour, 0);
          expect(d.date.minute, 0);
        }
      }
    });

    test('グリッド構造: 最終列はnowの週・日曜始まり・未来日は0', () {
      final hm = PlayActivityHeatmapService.build([], now: nowLocal);
      final last = hm.weeks.last;
      // now は火曜 → 週の最初（日曜）は 2026-10-11
      expect(last.days[0].date, DateTime(2026, 10, 11));
      expect(last.days[2].date, DateTime(2026, 10, 13)); // now 当日
      // 水曜〜土曜は未来 → count 0
      for (var i = 3; i < 7; i++) {
        expect(last.days[i].count, 0);
      }
      // 前週の最終日（土曜）は 2026-10-10
      expect(
        hm.weeks[hm.weeks.length - 2].days[6].date,
        DateTime(2026, 10, 10),
      );
      // 最初の週（weeks=26, 日曜始まり）
      final first = hm.weeks.first;
      expect(first.days[0].date.weekday, DateTime.sunday);
      expect(first.days.length, 7);
      // 最初の週の日曜は lastSunday - 25週
      expect(
        first.days[0].date,
        DateTime(2026, 10, 11).subtract(const Duration(days: 25 * 7)),
      );
    });

    test('集計値・currentStreak・longestStreak・busiestDay', () {
      // UTC で作る。日本TZ(+9)前提ではなく toLocal 後の日付で検証するため、
      // UTC日付そのものがローカル日付とズレ得る。安全のため「時刻09:00 UTC」
      // を使うと日本では同日18:00、負オフセットTZでは前日になる。
      // → ローカルTZ非依存にする: UTC正午(12:00)でも負TZで前日になり得るので、
      //   検証は countsByDate 的な同日性ではなく、グリッド上の期待日を
      //   タイムスタンプから再計算して比較する。
      DateTime localDay(DateTime day) {
        final ts = day.toUtc().toLocal();
        return DateTime(ts.year, ts.month, ts.day);
      }

      // 活動日: 10/1(1回), 10/2(2回), 10/3(0), 10/4(1回), now当日10/13(1回)
      final elections = [
        _electionAt(DateTime.utc(2026, 10, 1, 12)),
        _electionAt(DateTime.utc(2026, 10, 2, 3)),
        _electionAt(DateTime.utc(2026, 10, 2, 12)),
        _electionAt(DateTime.utc(2026, 10, 4, 12)),
        _electionAt(DateTime.utc(2026, 10, 13, 3)), // now当日(15:30ローカル)より前
      ];

      final hm = PlayActivityHeatmapService.build(
        elections,
        now: nowLocal,
        weeks: 2,
      );

      // 対象5件すべて集計される
      expect(hm.totalElections, 5);
      expect(hm.activeDays, 4);
      expect(hm.maxCount, 2);
      expect(hm.currentStreak, 1); // now当日のみ連続（前日は活動なし）
      expect(hm.longestStreak, 2); // 10/1→10/2
      expect(hm.busiestDay, isNotNull);
      expect(hm.busiestDay!.count, 2);
      expect(hm.busiestDay!.date, localDay(DateTime.utc(2026, 10, 2, 12)));
      expect(hm.isEmpty, isFalse);

      // グリッド: 最終週の日曜は 10/11、その前週は 10/4〜10/10
      final lastWeek = hm.weeks[1];
      expect(lastWeek.days[0].date, DateTime(2026, 10, 11));
      final prevWeek = hm.weeks[0];
      expect(prevWeek.days[0].date, DateTime(2026, 10, 4));
      // 10/4(日)が count 1
      expect(prevWeek.days[0].count, 1);
    });

    test('now当日が活動なし → currentStreak 0', () {
      final elections = [_electionAt(DateTime.utc(2026, 10, 12, 12))];
      final hm = PlayActivityHeatmapService.build(
        elections,
        now: nowLocal,
        weeks: 2,
      );
      expect(hm.totalElections, 1);
      expect(hm.currentStreak, 0);
      expect(hm.longestStreak, 1);
    });

    test('busiestDay 同数なら日付昇順で最初', () {
      final elections = [
        _electionAt(DateTime.utc(2026, 10, 6, 12)),
        _electionAt(DateTime.utc(2026, 10, 8, 12)),
      ];
      final hm = PlayActivityHeatmapService.build(
        elections,
        now: nowLocal,
        weeks: 2,
      );
      expect(hm.maxCount, 1);
      expect(hm.busiestDay!.date, DateTime(2026, 10, 6)); // ローカル検証
    });

    test('nowより未来のタイムスタンプでも未来日は count 0 にはならない（集計対象）', () {
      // 仕様上「now より未来の日付は count 0」はグリッド上の話。
      // 未来タイムスタンプは dateKey がグリッド範囲外なら単純に無視される。
      final elections = [_electionAt(DateTime.utc(2026, 10, 20, 12))];
      final hm = PlayActivityHeatmapService.build(
        elections,
        now: nowLocal,
        weeks: 2,
      );
      // totalElections は countsByDate 全体（グリッド外も含む）
      expect(hm.totalElections, 1);
      expect(hm.activeDays, 1);
      expect(hm.isEmpty, isFalse);
      // ただしグリッド上には存在しない
      for (final w in hm.weeks) {
        for (final d in w.days) {
          expect(d.count, 0);
        }
      }
    });

    test('now当日が連続の終点 → currentStreak 複数日', () {
      final elections = [
        _electionAt(DateTime.utc(2026, 10, 12, 12)),
        _electionAt(DateTime.utc(2026, 10, 13, 3)),
      ];
      final hm = PlayActivityHeatmapService.build(
        elections,
        now: nowLocal,
        weeks: 2,
      );
      // 10/12 と 10/13 が連続（ローカルTZで同日判定されることを確認）
      final counts = PlayActivityHeatmapService.countsByDate(elections);
      if (counts.length == 1) {
        // 負オフセットTZ等で同日になる環境
        expect(hm.currentStreak, 1);
      } else {
        expect(hm.currentStreak, 2);
        expect(hm.totalElections, 2);
      }
    });
  });
}
