import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_recap.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/election_recap_service.dart';
import 'package:flutter_test/flutter_test.dart';

ElectionArchiveEntry _entry({
  String electionId = 'election_123',
  String title = '天照町長選',
  ElectionScale scale = ElectionScale.town,
  String winnerName = '太郎',
  int winnerVotes = 600,
  int totalVotes = 1000,
  int runnerUpVotes = 300,
  DateTime? occurredAt,
}) =>
    ElectionArchiveEntry(
      electionId: electionId,
      title: title,
      scale: scale,
      winnerId: 'w1',
      winnerName: winnerName,
      winnerVotes: winnerVotes,
      totalVotes: totalVotes,
      runnerUpVotes: runnerUpVotes,
      occurredAt: occurredAt,
    );

TurnoutSnapshot _turnout({
  int eligible = 2000,
  int voted = 1200,
}) =>
    TurnoutSnapshot(
      electionTitle: '天照町長選',
      scale: ElectionScale.town,
      jobBreakdown: [
        JobTurnout(job: Job.farmer, eligible: eligible, voted: voted),
      ],
    );

void main() {
  group('ElectionRecap 検証系', () {
    test('空title → ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 1,
          totalVotes: 1,
          runnerUpVotes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('空winnerName → ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '',
          winnerVotes: 1,
          totalVotes: 1,
          runnerUpVotes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('負のwinnerVotes → ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: -1,
          totalVotes: 1,
          runnerUpVotes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('負のtotalVotes → ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 0,
          totalVotes: -1,
          runnerUpVotes: 0,
        ),
        throwsArgumentError,
      );
    });

    test('負のrunnerUpVotes → ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 0,
          totalVotes: 1,
          runnerUpVotes: -1,
        ),
        throwsArgumentError,
      );
    });

    test('turnoutRate 範囲外（1.1）→ ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 1,
          totalVotes: 1,
          runnerUpVotes: 0,
          turnoutRate: 1.1,
        ),
        throwsArgumentError,
      );
    });

    test('turnoutRate 範囲外（-0.1）→ ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 1,
          totalVotes: 1,
          runnerUpVotes: 0,
          turnoutRate: -0.1,
        ),
        throwsArgumentError,
      );
    });

    test('turnoutLabel だけ指定（rate が null）→ ArgumentError', () {
      expect(
        () => ElectionRecap(
          electionId: 'e1',
          title: '選挙',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: 1,
          totalVotes: 1,
          runnerUpVotes: 0,
          turnoutLabel: 'ふつう',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ElectionRecap 計算系', () {
    test('winnerShare は winnerVotes / totalVotes', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '町',
        winnerName: '太郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 300,
      );
      expect(r.winnerShare, closeTo(0.6, 1e-9));
    });

    test('totalVotes=0 → winnerShare 0.0', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 0,
        totalVotes: 0,
        runnerUpVotes: 0,
      );
      expect(r.winnerShare, 0.0);
    });

    test('margin = winnerVotes - runnerUpVotes', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 500,
        totalVotes: 1000,
        runnerUpVotes: 320,
      );
      expect(r.margin, 180);
    });

    test('isLandslide 境界: 0.6ちょうど → true', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 400,
      );
      expect(r.isLandslide, isTrue);
    });

    test('isLandslide 境界: 0.599.. → false', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 599,
        totalVotes: 1000,
        runnerUpVotes: 401,
      );
      expect(r.isLandslide, isFalse);
    });

    test('hasTurnout は turnoutRate の有無を反映', () {
      final withTurnout = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 1,
        totalVotes: 2,
        runnerUpVotes: 1,
        turnoutRate: 0.5,
        turnoutLabel: 'ふつう',
      );
      final withoutTurnout = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '村',
        winnerName: '太郎',
        winnerVotes: 1,
        totalVotes: 2,
        runnerUpVotes: 1,
      );
      expect(withTurnout.hasTurnout, isTrue);
      expect(withoutTurnout.hasTurnout, isFalse);
    });
  });

  group('ElectionRecap ラベル系', () {
    ElectionRecap recap({
      int winnerVotes = 600,
      int totalVotes = 1000,
      double? turnoutRate,
      String? turnoutLabel,
      DateTime? occurredAt,
    }) =>
        ElectionRecap(
          electionId: 'e1',
          title: '天照町長選',
          scaleLabel: '町',
          winnerName: '太郎',
          winnerVotes: winnerVotes,
          totalVotes: totalVotes,
          runnerUpVotes: 300,
          occurredAt: occurredAt,
          turnoutRate: turnoutRate,
          turnoutLabel: turnoutLabel,
        );

    test('sharePercentLabel', () {
      expect(recap().sharePercentLabel, '60.0%');
    });

    test('turnoutPercentLabel: あり', () {
      expect(recap(turnoutRate: 0.624, turnoutLabel: '高い関心')
          .turnoutPercentLabel, '62.4%');
    });

    test('turnoutPercentLabel: 不明は —', () {
      expect(recap().turnoutPercentLabel, '—');
    });

    test('marginLabel', () {
      expect(recap(winnerVotes: 500).marginLabel, '200票差');
    });

    test('dateLabel: null → 日付不明', () {
      expect(recap().dateLabel, '日付不明');
    });

    test('dateLabel: ゼロ埋め YYYY/MM/DD', () {
      expect(
        recap(occurredAt: DateTime(2026, 3, 7)).dateLabel,
        '2026/03/07',
      );
      expect(
        recap(occurredAt: DateTime(2026, 12, 31)).dateLabel,
        '2026/12/31',
      );
    });
  });

  group('ElectionRecap lines/text', () {
    test('6行の順序と内容（圧勝・投票率あり）', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '天照町長選',
        scaleLabel: '町',
        winnerName: '太郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 300,
        occurredAt: DateTime(2026, 5, 2),
        turnoutRate: 0.624,
        turnoutLabel: '高い関心',
      );
      expect(r.lines, [
        '【天照町長選】当選: 太郎',
        '得票率: 60.0%（600票 / 総投票 1000票）',
        '2位との差: 300票差（圧勝）',
        '投票率: 62.4%（高い関心）',
        '規模: 町',
        '実施日: 2026/05/02',
      ]);
      expect(r.text, r.lines.join('\n'));
    });

    test('非圧勝・投票率なし', () {
      final r = ElectionRecap(
        electionId: 'e1',
        title: '天照村長選',
        scaleLabel: '村',
        winnerName: '花子',
        winnerVotes: 400,
        totalVotes: 1000,
        runnerUpVotes: 350,
      );
      expect(r.lines[0], '【天照村長選】当選: 花子');
      expect(r.lines[2], '2位との差: 50票差');
      expect(r.lines[3], '投票率: —');
    });
  });

  group('ElectionRecap ==/hashCode', () {
    test('同値ペアは等しく、違いは等しくない', () {
      final a = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '町',
        winnerName: '太郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 300,
      );
      final b = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '町',
        winnerName: '太郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 300,
      );
      final c = ElectionRecap(
        electionId: 'e1',
        title: '選挙',
        scaleLabel: '町',
        winnerName: '次郎',
        winnerVotes: 600,
        totalVotes: 1000,
        runnerUpVotes: 300,
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });

  group('ElectionRecapService.build', () {
    test('entry から写像（turnout あり）', () {
      final r = ElectionRecapService.build(
        _entry(occurredAt: DateTime(2026, 5, 2)),
        turnout: _turnout(),
      );
      expect(r.electionId, 'election_123');
      expect(r.title, '天照町長選');
      expect(r.scaleLabel, '町');
      expect(r.winnerName, '太郎');
      expect(r.winnerVotes, 600);
      expect(r.totalVotes, 1000);
      expect(r.runnerUpVotes, 300);
      expect(r.occurredAt, DateTime(2026, 5, 2));
      expect(r.turnoutRate, closeTo(0.6, 1e-9));
      expect(r.turnoutLabel, '高い関心');
    });

    test('turnout なし → turnoutRate/turnoutLabel は null', () {
      final r = ElectionRecapService.build(_entry());
      expect(r.hasTurnout, isFalse);
      expect(r.turnoutRate, isNull);
      expect(r.turnoutLabel, isNull);
    });
  });

  group('ElectionRecapService.latest', () {
    test('空リスト → null', () {
      expect(ElectionRecapService.latest(const []), isNull);
    });

    test('末尾エントリを採用', () {
      final e1 = _entry(electionId: 'e1', title: '最初の選挙', winnerName: '甲');
      final e2 = _entry(electionId: 'e2', title: '最新の選挙', winnerName: '乙');
      final r = ElectionRecapService.latest([e1, e2])!;
      expect(r.electionId, 'e2');
      expect(r.title, '最新の選挙');
      expect(r.winnerName, '乙');
    });

    test('turnoutsByElectionId を引き当てる', () {
      final e1 = _entry(electionId: 'e1');
      final e2 = _entry(electionId: 'e2');
      final r = ElectionRecapService.latest(
        [e1, e2],
        turnoutsByElectionId: {'e2': _turnout()},
      )!;
      expect(r.hasTurnout, isTrue);
    });

    test('引き当てられなければ turnout なし', () {
      final e1 = _entry(electionId: 'e1');
      final r = ElectionRecapService.latest(
        [e1],
        turnoutsByElectionId: {'other': _turnout()},
      )!;
      expect(r.hasTurnout, isFalse);
    });
  });
}