import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_chart.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/election_chart_service.dart';

ElectionArchiveEntry entry({
  required String electionId,
  DateTime? occurredAt,
  int winnerVotes = 60,
  int totalVotes = 100,
  String winnerName = '山田太郎',
  String winnerId = 'candidate_1',
  String title = '選挙',
}) {
  return ElectionArchiveEntry(
    electionId: electionId,
    title: title,
    scale: ElectionScale.town,
    winnerId: winnerId,
    winnerName: winnerName,
    winnerVotes: winnerVotes,
    totalVotes: totalVotes,
    runnerUpVotes: 30,
    occurredAt: occurredAt,
  );
}

Election election({
  required String id,
  required List<Candidate> candidates,
  Map<String, int>? voteCounts,
}) {
  return Election(
    id: id,
    title: '選挙',
    scale: ElectionScale.town,
    candidates: candidates,
    voteCounts: voteCounts,
  );
}

Candidate cand(String id, String faction) =>
    Candidate(id: id, name: 'n_$id', portraitKey: 'p', faction: faction, personality: '', policies: const []);

void main() {
  group('buildPoints', () {
    test('① occurredAt昇順に並ぶ', () {
      final points = ElectionChartService.buildPoints([
        entry(electionId: 'election_2000', occurredAt: DateTime(2026, 1, 2)),
        entry(electionId: 'election_1000', occurredAt: DateTime(2026, 1, 1)),
      ]);
      expect(points.map((p) => p.electionId).toList(), ['election_1000', 'election_2000']);
    });

    test('① occurredAtがnullのものは末尾', () {
      final points = ElectionChartService.buildPoints([
        entry(electionId: 'election_2000'),
        entry(electionId: 'election_1000', occurredAt: DateTime(2026, 1, 1)),
      ]);
      expect(points.map((p) => p.electionId).toList(), ['election_1000', 'election_2000']);
    });

    test('① 同時刻はelectionId昇順', () {
      final t = DateTime(2026, 3, 1);
      final points = ElectionChartService.buildPoints([
        entry(electionId: 'election_2000', occurredAt: t),
        entry(electionId: 'election_1000', occurredAt: t),
      ]);
      expect(points.map((p) => p.electionId).toList(), ['election_1000', 'election_2000']);
    });

    test('① null同士はelectionId昇順', () {
      final points = ElectionChartService.buildPoints([
        entry(electionId: 'election_2000'),
        entry(electionId: 'election_1000'),
      ]);
      expect(points.map((p) => p.electionId).toList(), ['election_1000', 'election_2000']);
    });

    test('② labelは並べ替え後の順に第1回,第2回,...と採番', () {
      final points = ElectionChartService.buildPoints([
        entry(electionId: 'election_2000', occurredAt: DateTime(2026, 2, 1)),
        entry(electionId: 'election_1000', occurredAt: DateTime(2026, 1, 1)),
        entry(electionId: 'election_3000', occurredAt: DateTime(2026, 3, 1)),
      ]);
      expect(points.map((p) => p.label).toList(), ['第1回', '第2回', '第3回']);
    });

    test('② pointの値はentryを写像する', () {
      final t = DateTime(2026, 1, 1);
      final points = ElectionChartService.buildPoints(
        [entry(electionId: 'election_1', occurredAt: t, winnerVotes: 52, totalVotes: 100, winnerName: '鈴木一郎')],
      );
      final p = points.single;
      expect(p.winnerShare, closeTo(0.52, 1e-9));
      expect(p.totalVotes, 100);
      expect(p.winnerName, '鈴木一郎');
      expect(p.occurredAt, t);
      expect(p.electionId, 'election_1');
    });

    test('⑬ 入力リストを破壊しない', () {
      final input = [
        entry(electionId: 'election_2000', occurredAt: DateTime(2026, 2, 1)),
        entry(electionId: 'election_1000', occurredAt: DateTime(2026, 1, 1)),
      ];
      ElectionChartService.buildPoints(input);
      expect(input.map((e) => e.electionId).toList(), ['election_2000', 'election_1000']);
    });
  });

  group('ElectionChartPoint 検証', () {
    test('⑫ winnerShareが1.0超はArgumentError', () {
      expect(() => ElectionChartPoint(electionId: 'e', label: '第1回', winnerShare: 1.5, totalVotes: 10, winnerName: 'x'), throwsArgumentError);
    });

    test('⑫ winnerShareが0未満はArgumentError', () {
      expect(() => ElectionChartPoint(electionId: 'e', label: '第1回', winnerShare: -0.1, totalVotes: 10, winnerName: 'x'), throwsArgumentError);
    });

    test('⑫ totalVotesが負はArgumentError', () {
      expect(() => ElectionChartPoint(electionId: 'e', label: '第1回', winnerShare: 0.5, totalVotes: -1, winnerName: 'x'), throwsArgumentError);
    });

    test('⑪ 境界値0.0と1.0は許容', () {
      expect(
        () => ElectionChartPoint(electionId: 'e', label: 'l', winnerShare: 0.0, totalVotes: 0, winnerName: 'x'),
        returnsNormally,
      );
      expect(
        () => ElectionChartPoint(electionId: 'e', label: 'l', winnerShare: 1.0, totalVotes: 10, winnerName: 'x'),
        returnsNormally,
      );
    });

    test('⑪ sharePercentLabel書式', () {
      final p = ElectionChartPoint(electionId: 'e', label: 'l', winnerShare: 0.523, totalVotes: 100, winnerName: 'x');
      expect(p.sharePercentLabel, '52.3%');
    });

    test('値等価: == と hashCode', () {
      final a = ElectionChartPoint(electionId: 'e1', label: '第1回', winnerShare: 0.5, totalVotes: 10, winnerName: 'x');
      final b = ElectionChartPoint(electionId: 'e1', label: '第1回', winnerShare: 0.5, totalVotes: 10, winnerName: 'x');
      final c = ElectionChartPoint(electionId: 'e2', label: '第1回', winnerShare: 0.5, totalVotes: 10, winnerName: 'x');
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('ElectionComparison', () {
    test('③ 0件でisEmpty', () {
      final cmp = ElectionChartService.compare([]);
      expect(cmp.isEmpty, isTrue);
      expect(cmp.totalElections, 0);
      expect(cmp.highestSharePoint, isNull);
      expect(cmp.lowestSharePoint, isNull);
      expect(cmp.averageWinnerShare, 0.0);
      expect(cmp.shareChange, 0.0);
    });

    test('④ 1件でshareChangeは0.0', () {
      final cmp = ElectionChartService.compare(
        [entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 40, totalVotes: 100)],
      );
      expect(cmp.shareChange, 0.0);
      expect(cmp.totalElections, 1);
    });

    test('⑤ highest/lowest の同値タイブレークは先頭優先', () {
      final t = DateTime(2026, 1, 1);
      final cmp = ElectionChartService.compare([
        entry(electionId: 'election_1', occurredAt: t, winnerVotes: 50, totalVotes: 100),
        entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 50, totalVotes: 100),
        entry(electionId: 'election_3', occurredAt: DateTime(2026, 3, 1), winnerVotes: 30, totalVotes: 100),
      ]);
      expect(cmp.highestSharePoint!.electionId, 'election_1');
      expect(cmp.lowestSharePoint!.electionId, 'election_3');
    });

    test('⑤ lowest の同値タイブレークは先頭優先', () {
      final cmp = ElectionChartService.compare([
        entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 40, totalVotes: 100),
        entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 20, totalVotes: 100),
        entry(electionId: 'election_3', occurredAt: DateTime(2026, 3, 1), winnerVotes: 20, totalVotes: 100),
      ]);
      expect(cmp.lowestSharePoint!.electionId, 'election_2');
    });

    test('④ shareChangeは最終-最初', () {
      final cmp = ElectionChartService.compare([
        entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 30, totalVotes: 100),
        entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 62, totalVotes: 100),
      ]);
      expect(cmp.shareChange, closeTo(0.32, 1e-9));
      expect(cmp.shareChangeLabel, '+32.0pt');
    });

    test('⑪ averageWinnerShare', () {
      final cmp = ElectionChartService.compare([
        entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 40, totalVotes: 100),
        entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 60, totalVotes: 100),
      ]);
      expect(cmp.averageWinnerShare, closeTo(0.5, 1e-9));
    });

    test('compareはelectionsが空ならseriesが空', () {
      final cmp = ElectionChartService.compare(
        [entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1))],
      );
      expect(cmp.series, isEmpty);
    });
  });

  group('buildPartySeries', () {
    test('⑥ faction合算とシェア算出', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'A'), cand('c3', 'B')], voteCounts: {'c1': 20, 'c2': 10, 'c3': 70}),
      ]);
      final a = series.firstWhere((s) => s.faction == 'A');
      final b = series.firstWhere((s) => s.faction == 'B');
      expect(a.shares, [closeTo(0.3, 1e-9)]);
      expect(b.shares, [closeTo(0.7, 1e-9)]);
    });

    test('⑥ totalVotes=0は全faction 0.0', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'B')], voteCounts: {'c1': 0, 'c2': 0}),
      ]);
      expect(series.every((s) => s.shares.single == 0.0), isTrue);
    });

    test('⑥ voteCountsがnullの選挙は全faction 0.0', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'B')]),
      ]);
      expect(series.every((s) => s.shares.single == 0.0), isTrue);
    });

    test('⑥ voteCountsの候補者ID以外のキーは無視', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A')], voteCounts: {'c1': 50, 'ghost': 50}),
      ]);
      expect(series.first.shares.single, closeTo(1.0, 1e-9));
    });

    test('⑥ 空文字factionは無所属として扱う', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', '')], voteCounts: {'c1': 50}),
      ]);
      expect(series.first.faction, '無所属');
    });

    test('⑦ seriesはaverageShare降順→faction昇順でソート', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', '低'), cand('c2', '高')], voteCounts: {'c1': 10, 'c2': 90}),
      ]);
      expect(series.map((s) => s.faction).toList(), ['高', '低']);
    });

    test('⑦ 同averageShareならfaction昇順', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', '甲'), cand('c2', '乙')], voteCounts: {'c1': 50, 'c2': 50}),
      ]);
      expect(series.map((s) => s.faction).toList(), ['乙', '甲']);
    });

    test('⑧ maxSeries指定で上位件のみ', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'B'), cand('c3', 'C')], voteCounts: {'c1': 40, 'c2': 40, 'c3': 20}),
      ], maxSeries: 2);
      expect(series.length, 2);
      expect(series.map((s) => s.faction).toSet(), {'A', 'B'});
    });

    test('系列のaverageShare/latestShare/peakShare', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'B')], voteCounts: {'c1': 30, 'c2': 70}),
        election(id: 'election_2000', candidates: [cand('c1', 'A'), cand('c2', 'B')], voteCounts: {'c1': 80, 'c2': 20}),
      ]);
      final a = series.firstWhere((s) => s.faction == 'A');
      expect(a.shares.length, 2);
      expect(a.averageShare, closeTo(0.55, 1e-9));
      expect(a.latestShare, closeTo(0.8, 1e-9));
      expect(a.peakShare, closeTo(0.8, 1e-9));
      // sharesはunmodifiable
      expect(() => a.shares.add(0.5), throwsUnsupportedError);
    });

    test('⑥ 複数選挙の並びはtimestampFromIdによる時系列順', () {
      final series = ElectionChartService.buildPartySeries([
        election(id: 'election_2000', candidates: [cand('c1', 'A'), cand('c2', 'B')], voteCounts: {'c1': 60, 'c2': 40}),
        election(id: 'election_1000', candidates: [cand('c1', 'A'), cand('c2', 'B')], voteCounts: {'c1': 20, 'c2': 80}),
      ]);
      final a = series.firstWhere((s) => s.faction == 'A');
      // election_1000 が先 → shares = [0.2, 0.6]
      expect(a.shares.map((s) => s.toStringAsFixed(1)).toList(), ['0.2', '0.6']);
    });
  });

  group('trendLabel', () {
    ElectionPartySeries make(List<double> shares) => ElectionPartySeries(
          faction: 'A',
          shares: shares,
          averageShare: 0.5,
          latestShare: shares.isEmpty ? 0.0 : shares.last,
          peakShare: 0.9,
        );

    test('⑨ +0.01超は上昇', () {
      expect(make([0.5, 0.8]).trendLabel, '上昇');
    });

    test('⑨ -0.01未満は下降', () {
      expect(make([0.8, 0.5]).trendLabel, '下降');
    });

    test('⑨ 差が±0.01以下は横ばい', () {
      expect(make([0.5, 0.505]).trendLabel, '横ばい');
    });

    test('⑨ 空sharesは横ばい', () {
      expect(make([]).trendLabel, '横ばい');
    });

    test('⑪ latestPercentLabel書式', () {
      final s = ElectionPartySeries(faction: 'A', shares: [0.34], averageShare: 0.34, latestShare: 0.34, peakShare: 0.34);
      expect(s.latestPercentLabel, '34.0%');
    });
  });

  group('selectEntries', () {
    test('⑩ selectedIdsに含まれるもののみ・元の順序を保持', () {
      final input = [
        entry(electionId: 'election_1'),
        entry(electionId: 'election_2'),
        entry(electionId: 'election_3'),
      ];
      final result = ElectionChartService.selectEntries(input, {'election_3', 'election_1'});
      expect(result.map((e) => e.electionId).toList(), ['election_1', 'election_3']);
    });

    test('⑩ 空集合なら空リスト', () {
      final result = ElectionChartService.selectEntries(
        [entry(electionId: 'election_1')],
        <String>{},
      );
      expect(result, isEmpty);
    });
  });

  group('percentLabel / shareChangeLabel', () {
    test('⑪ percentLabel', () {
      expect(ElectionChartService.percentLabel(0.123), '12.3%');
      expect(ElectionChartService.percentLabel(1.0), '100.0%');
      expect(ElectionChartService.percentLabel(0.0), '0.0%');
    });

    test('⑪ shareChangeLabelの三分岐', () {
      // +3.2pt: 0.56 → 0.592（140/250 → 148/250）
      expect(
        ElectionChartService.compare([
          entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 140, totalVotes: 250),
          entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 148, totalVotes: 250),
        ]).shareChangeLabel,
        '+3.2pt',
      );
      // -10.0pt: 0.60 → 0.50
      expect(
        ElectionChartService.compare([
          entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 60, totalVotes: 100),
          entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 50, totalVotes: 100),
        ]).shareChangeLabel,
        '-10.0pt',
      );
      // ±0.0pt: 変化なし
      expect(
        ElectionChartService.compare([
          entry(electionId: 'election_1', occurredAt: DateTime(2026, 1, 1), winnerVotes: 50, totalVotes: 100),
          entry(electionId: 'election_2', occurredAt: DateTime(2026, 2, 1), winnerVotes: 50, totalVotes: 100),
        ]).shareChangeLabel,
        '±0.0pt',
      );
    });

    test('compare(0件)のseriesはelections指定でもpointsから系列構築に使用される', () {
      final cmp = ElectionChartService.compare(
        [],
        elections: [election(id: 'election_1', candidates: [cand('c1', 'A')], voteCounts: {'c1': 10})],
      );
      expect(cmp.isEmpty, isTrue);
      expect(cmp.series.length, 1);
    });
  });
}
