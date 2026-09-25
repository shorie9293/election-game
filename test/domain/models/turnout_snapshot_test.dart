import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

/// 1職業ぶんのスナップショットを作るヘルパー
TurnoutSnapshot _snapshotOf(int voted, int eligible) => TurnoutSnapshot(
      electionTitle: '試験選挙',
      scale: ElectionScale.village,
      jobBreakdown: [
        JobTurnout(job: Job.farmer, eligible: eligible, voted: voted),
      ],
    );

void main() {
  group('JobTurnout 不変条件', () {
    test('eligible < 0 → ArgumentError', () {
      expect(
        () => JobTurnout(job: Job.farmer, eligible: -1, voted: 0),
        throwsArgumentError,
      );
    });

    test('voted < 0 → ArgumentError', () {
      expect(
        () => JobTurnout(job: Job.farmer, eligible: 5, voted: -1),
        throwsArgumentError,
      );
    });

    test('voted > eligible → ArgumentError', () {
      expect(
        () => JobTurnout(job: Job.farmer, eligible: 5, voted: 6),
        throwsArgumentError,
      );
    });

    test('正当な値では生成できる', () {
      final jt = JobTurnout(job: Job.farmer, eligible: 5, voted: 3);
      expect(jt.eligible, 5);
      expect(jt.voted, 3);
      expect(jt.abstained, 2);
    });
  });

  group('JobTurnout 計算', () {
    test('rate: voted/eligible、eligible 0 なら 0.0', () {
      expect(JobTurnout(job: Job.farmer, eligible: 4, voted: 1).rate, 0.25);
      expect(JobTurnout(job: Job.farmer, eligible: 0, voted: 0).rate, 0.0);
    });

    test('rateLabel: 小数1桁のパーセント', () {
      expect(
        JobTurnout(job: Job.farmer, eligible: 8, voted: 3).rateLabel,
        '37.5%',
      );
      expect(
        JobTurnout(job: Job.farmer, eligible: 3, voted: 1).rateLabel,
        '33.3%',
      );
    });

    test('props による等価性', () {
      expect(
        JobTurnout(job: Job.farmer, eligible: 5, voted: 2),
        equals(JobTurnout(job: Job.farmer, eligible: 5, voted: 2)),
      );
      expect(
        JobTurnout(job: Job.farmer, eligible: 5, voted: 2),
        isNot(equals(JobTurnout(job: Job.farmer, eligible: 5, voted: 3))),
      );
    });
  });

  group('TurnoutSnapshot 不変条件', () {
    test('空タイトル → ArgumentError', () {
      expect(
        () => TurnoutSnapshot(
          electionTitle: '',
          scale: ElectionScale.village,
          jobBreakdown: [JobTurnout(job: Job.farmer, eligible: 5, voted: 3)],
        ),
        throwsArgumentError,
      );
    });

    test('空 jobBreakdown → ArgumentError', () {
      expect(
        () => TurnoutSnapshot(
          electionTitle: '村長選挙',
          scale: ElectionScale.village,
          jobBreakdown: [],
        ),
        throwsArgumentError,
      );
    });
  });

  group('TurnoutSnapshot 集計', () {
    final snapshot = TurnoutSnapshot(
      electionTitle: '天照村 村長選挙',
      scale: ElectionScale.village,
      jobBreakdown: [
        JobTurnout(job: Job.farmer, eligible: 10, voted: 8),
        JobTurnout(job: Job.fisher, eligible: 10, voted: 4),
        JobTurnout(job: Job.doctor, eligible: 10, voted: 6),
      ],
    );

    test('eligibleVoters は eligible の合計', () {
      expect(snapshot.eligibleVoters, 30);
    });

    test('votesCast は voted の合計', () {
      expect(snapshot.votesCast, 18);
    });

    test('abstentionCount = eligibleVoters - votesCast', () {
      expect(snapshot.abstentionCount, 12);
    });

    test('turnoutRate と turnoutPercentLabel', () {
      expect(snapshot.turnoutRate, closeTo(0.6, 1e-9));
      expect(snapshot.turnoutPercentLabel, '60.0%');
    });

    test('有権者0でも turnoutRate は 0.0 で割り算が起きない', () {
      final s = TurnoutSnapshot(
        electionTitle: 'x',
        scale: ElectionScale.village,
        jobBreakdown: [JobTurnout(job: Job.farmer, eligible: 0, voted: 0)],
      );
      expect(s.turnoutRate, 0.0);
      expect(s.turnoutPercentLabel, '0.0%');
      expect(s.turnoutLabel, '低い関心');
    });
  });

  group('turnoutLabel の3分岐（境界含む）', () {
    test('rate == 0.6 → 高い関心', () {
      expect(_snapshotOf(6, 10).turnoutLabel, '高い関心');
    });

    test('rate 0.61 → 高い関心', () {
      // 61/100 は作りにくいので 2 職業で構成: (6+1)/10 は 0.7
      final s = TurnoutSnapshot(
        electionTitle: 't',
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 100, voted: 61),
        ],
      );
      expect(s.turnoutLabel, '高い関心');
    });

    test('rate == 0.45 → ふつう（境界含む）', () {
      expect(_snapshotOf(45, 100).turnoutLabel, 'ふつう');
    });

    test('rate 0.5999… ぎりぎり下側 → ふつう', () {
      expect(_snapshotOf(599, 1000).turnoutLabel, 'ふつう');
    });

    test('rate 0.4499… → 低い関心', () {
      expect(_snapshotOf(449, 1000).turnoutLabel, '低い関心');
    });
  });

  group('highestJob / lowestJob', () {
    test('最大・最小の職業を返す', () {
      final s = TurnoutSnapshot(
        electionTitle: 't',
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 10, voted: 5),
          JobTurnout(job: Job.doctor, eligible: 10, voted: 9),
          JobTurnout(job: Job.student, eligible: 10, voted: 2),
        ],
      );
      expect(s.highestJob?.job, Job.doctor);
      expect(s.lowestJob?.job, Job.student);
    });

    test('同率は Job.index 昇順で先（highest: farmer vs doctor）', () {
      final s = TurnoutSnapshot(
        electionTitle: 't',
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.doctor, eligible: 10, voted: 7),
          JobTurnout(job: Job.farmer, eligible: 10, voted: 7),
        ],
      );
      expect(s.highestJob?.job, Job.farmer); // farmer.index < doctor.index
      expect(s.lowestJob?.job, Job.farmer); // どちらも同率なので index 先
    });

    test('空リストなら null（防御的）', () {
      // 不変条件で空は作れないため、private に擬似的には作れない。
      // ここでは breakdown が 1 件のとき highest == lowest を確認する。
      final s = _snapshotOf(3, 10);
      expect(s.highestJob?.job, Job.farmer);
      expect(s.lowestJob?.job, Job.farmer);
    });
  });

  group('TurnoutSnapshot props', () {
    test('playerAbstained が異なれば非等価', () {
      final a = TurnoutSnapshot(
        electionTitle: 't',
        scale: ElectionScale.village,
        jobBreakdown: [JobTurnout(job: Job.farmer, eligible: 5, voted: 3)],
      );
      final b = TurnoutSnapshot(
        electionTitle: 't',
        scale: ElectionScale.village,
        jobBreakdown: [JobTurnout(job: Job.farmer, eligible: 5, voted: 3)],
        playerAbstained: true,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('TurnoutCounterfactual', () {
    test('abstentionCount 負値 → ArgumentError', () {
      expect(
        () => TurnoutCounterfactual(
          actualWinnerId: 'a',
          actualWinnerName: 'A',
          counterfactualWinnerId: 'a',
          counterfactualWinnerName: 'A',
          actualVotes: const {'a': 5},
          counterfactualVotes: const {'a': 5},
          abstentionCount: -1,
        ),
        throwsArgumentError,
      );
    });

    test('winnerChanged / verdictLabel の2分岐', () {
      final same = TurnoutCounterfactual(
        actualWinnerId: 'a',
        actualWinnerName: 'A',
        counterfactualWinnerId: 'a',
        counterfactualWinnerName: 'A',
        actualVotes: {'a': 5, 'b': 3},
        counterfactualVotes: {'a': 6, 'b': 4},
        abstentionCount: 2,
      );
      expect(same.winnerChanged, isFalse);
      expect(same.verdictLabel, '棄権があっても当選者は変わらない');

      final changed = TurnoutCounterfactual(
        actualWinnerId: 'a',
        actualWinnerName: 'A',
        counterfactualWinnerId: 'b',
        counterfactualWinnerName: 'B',
        actualVotes: {'a': 5, 'b': 3},
        counterfactualVotes: {'a': 5, 'b': 6},
        abstentionCount: 3,
      );
      expect(changed.winnerChanged, isTrue);
      expect(changed.verdictLabel, '棄権が当選者を変えた');
    });

    test('当選者名が null でも比較可能', () {
      final c = TurnoutCounterfactual(
        actualWinnerId: null,
        actualWinnerName: null,
        counterfactualWinnerId: null,
        counterfactualWinnerName: null,
        actualVotes: {},
        counterfactualVotes: {},
        abstentionCount: 0,
      );
      expect(c.winnerChanged, isFalse);
      expect(c.verdictLabel, '棄権があっても当選者は変わらない');
    });
  });
}
