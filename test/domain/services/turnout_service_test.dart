import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/turnout_service.dart';
import 'package:flutter_test/flutter_test.dart';

List<Candidate> _candidates() => [
      const Candidate(
        id: 'a',
        name: '候補A',
        portraitKey: 'p1',
        faction: 'A',
        personality: '穏健',
        policies: [
          Policy(
            title: '農業振興',
            description: 'd',
            category: '農業',
            effects: {'employment': 10, 'environment': 5},
          ),
        ],
      ),
      const Candidate(
        id: 'b',
        name: '候補B',
        portraitKey: 'p2',
        faction: 'B',
        personality: '改草',
        policies: [
          Policy(
            title: '医療拡充',
            description: 'd',
            category: '医療',
            effects: {'healthcare': 10, 'education': 5},
          ),
        ],
      ),
    ];

Election _completedElection({
  Map<String, int>? voteCounts,
  String winnerId = 'a',
  String title = '天照村 村長選挙',
}) {
  return Election(
    id: 'e1',
    title: title,
    scale: ElectionScale.village,
    candidates: _candidates(),
    voteCounts: voteCounts ?? const {'a': 6, 'b': 4},
    winnerId: winnerId,
  );
}

GameState _state({
  Election? currentElection,
  List<Election> pastElections = const [],
}) {
  return GameState(
    citizen: Citizen.initial(Job.farmer),
    society: SocietyState.initial(),
    currentElection: currentElection,
    pastElections: pastElections,
    scale: ElectionScale.village,
  );
}

void main() {
  group('baseTurnoutRate / eligibleVotersFor', () {
    test('規模別の基礎参加率', () {
      expect(TurnoutService.baseTurnoutRate(ElectionScale.village), 0.72);
      expect(TurnoutService.baseTurnoutRate(ElectionScale.town), 0.62);
      expect(TurnoutService.baseTurnoutRate(ElectionScale.city), 0.54);
    });

    test('有権者数 = npcCount * 10', () {
      expect(TurnoutService.eligibleVotersFor(ElectionScale.village), 50);
      expect(TurnoutService.eligibleVotersFor(ElectionScale.town), 80);
      expect(TurnoutService.eligibleVotersFor(ElectionScale.city), 120);
    });
  });

  group('estimateRate', () {
    test('mood 0.5（頑固さ0.2）の村: base 0.72 + 0 + (0.2-0.5)*0.10 = 0.69', () {
      final s = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      expect(
        TurnoutService.estimateRate(society: s, scale: ElectionScale.village),
        closeTo(0.72 - 0.03, 1e-9),
      );
    });

    test('mood 0.5（頑固さ0.2）の市: base 0.54 - 0.03 = 0.51', () {
      final s = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      expect(
        TurnoutService.estimateRate(society: s, scale: ElectionScale.city),
        closeTo(0.51, 1e-9),
      );
    });

    test('上限 clamp: 値が 0.95 を超えない', () {
      // mood 0.0 → 頑固さ 0.8 → (0-0.5)*0.2 + (0.8-0.5)*0.1 = -0.07 … 下がる
      // mood 0.4-0.6（頑固さ0.2）で mood 0.6: 0.72+0.02-0.03=0.71
      // clamp 上限に届くのは mood が高い&頑固さが低い場合だが組み合わせが無いので
      // ここでは式どおり 0.95 以下を確認
      for (final mood in [0.0, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9, 1.0]) {
        final s = SocietyState(happiness: 50, mood: mood, electionCount: 0);
        final r = TurnoutService.estimateRate(
            society: s, scale: ElectionScale.village);
        expect(r, lessThanOrEqualTo(0.95));
        expect(r, greaterThanOrEqualTo(0.25));
      }
    });

    test('下限 clamp: mood 0.0 の市でも 0.25 以上', () {
      final s = SocietyState(happiness: 50, mood: 0.0, electionCount: 0);
      final r = TurnoutService.estimateRate(
          society: s, scale: ElectionScale.city);
      expect(r, greaterThanOrEqualTo(0.25));
      expect(r, lessThanOrEqualTo(0.95));
    });

    test('mood 単調性: mood 0 → 0.5 で参加率は上昇する', () {
      // mood 0 → 0.5 は頑固さ 0.8→0.2 と mood 項の増加で上昇する
      final s0 = SocietyState(happiness: 50, mood: 0.0, electionCount: 0);
      final s05 = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      final r0 = TurnoutService.estimateRate(
          society: s0, scale: ElectionScale.village);
      final r05 = TurnoutService.estimateRate(
          society: s05, scale: ElectionScale.village);
      expect(r05, greaterThan(r0));
    });

    test('mood 式どおり: mood 0.5 より mood 0.9 の方が mood 項だけ高い', () {
      final s = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      final rHalf = TurnoutService.estimateRate(
          society: s, scale: ElectionScale.village);
      final sHigh = SocietyState(happiness: 50, mood: 0.9, electionCount: 0);
      final rHigh = TurnoutService.estimateRate(
          society: sHigh, scale: ElectionScale.village);
      // mood 0.5: 0.72 + 0 - 0.03 = 0.69 / mood 0.9: 0.72 + 0.08 + 0.04 = 0.84
      expect(rHalf, closeTo(0.69, 1e-9));
      expect(rHigh, closeTo(0.84, 1e-9));
      expect(rHigh, greaterThan(rHalf));
    });
  });

  group('compute（スナップショット生成）', () {
    test('全10職の breakdown、宣言順、eligible は全職 scale.npcCount', () {
      final election = _completedElection();
      final snapshot = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      expect(snapshot.jobBreakdown.length, Job.values.length);
      expect(
        snapshot.jobBreakdown.map((j) => j.job).toList(),
        Job.values.toList(),
      );
      expect(
        snapshot.jobBreakdown.every((j) => j.eligible == 5),
        isTrue,
      );
    });

    test('jobBreakdown の eligible 合計 == npcCount * 10、voted 合計 == votesCast', () {
      final snapshot = TurnoutService.compute(
        election: _completedElection(),
        society: SocietyState.initial(),
        scale: ElectionScale.town,
      );
      expect(snapshot.eligibleVoters, 8 * 10);
      expect(
        snapshot.jobBreakdown.fold<int>(0, (a, j) => a + j.voted),
        snapshot.votesCast,
      );
      expect(snapshot.votesCast, lessThanOrEqualTo(snapshot.eligibleVoters));
    });

    test('electionTitle は election.title', () {
      final snapshot = TurnoutService.compute(
        election: _completedElection(title: '特別選挙'),
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      expect(snapshot.electionTitle, '特別選挙');
    });

    test('決定性: 同条件で同一結果', () {
      final election = _completedElection();
      final a = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final b = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      expect(a, equals(b));
    });

    test('職業別: multiplier が最大の teacher が最小の unemployed より高い', () {
      final snapshot = TurnoutService.compute(
        election: _completedElection(),
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final byJob = {for (final j in snapshot.jobBreakdown) j.job: j};
      expect(byJob[Job.teacher]!.rate, greaterThan(byJob[Job.unemployed]!.rate));
    });

    test('playerAbstained=true で該当職の voted が1減り breakdown 合計も1減る', () {
      final election = _completedElection();
      final player = Citizen.initial(Job.student);
      final base = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final abstained = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
        player: player,
        playerAbstained: true,
      );
      final baseStudent =
          base.jobBreakdown.firstWhere((j) => j.job == Job.student).voted;
      final abstainedStudent = abstained.jobBreakdown
          .firstWhere((j) => j.job == Job.student)
          .voted;
      expect(abstainedStudent, baseStudent - 1);
      expect(abstained.votesCast, base.votesCast - 1);
      expect(abstained.playerAbstained, isTrue);
    });

    test('player==null なら playerAbstained=true でも変化なし', () {
      final election = _completedElection();
      final base = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final noPlayer = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
        playerAbstained: true,
      );
      expect(noPlayer.votesCast, base.votesCast);
      expect(noPlayer, isNot(equals(base))); // playerAbstained flag differs
    });

    test('voted が 0 の職業では playerAbstained でも 0 未満にならない', () {
      // unemployed は multiplier 0.55 で rate が低いが village では 0 にはならない。
      // city でも 0 にならないため、ここでは clamp 下限 0.05 の職業で voted >= 1 となる
      // ことを確認する（npcCount * 0.05 * 0.55 ≈ 0.33 → round 0 になる可能性）。
      final lowMood = SocietyState(happiness: 50, mood: 0.0, electionCount: 0);
      final snapshot = TurnoutService.compute(
        election: _completedElection(),
        society: lowMood,
        scale: ElectionScale.city,
        player: Citizen.initial(Job.unemployed),
        playerAbstained: true,
      );
      final unemployed = snapshot.jobBreakdown
          .firstWhere((j) => j.job == Job.unemployed);
      expect(unemployed.voted, greaterThanOrEqualTo(0));
    });
  });

  group('counterfactual', () {
    test('未完了選挙（voteCounts null）→ ArgumentError', () {
      final election = Election(
        id: 'e',
        title: 't',
        scale: ElectionScale.village,
        candidates: _candidates(),
      );
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      expect(
        () => TurnoutService.counterfactual(
          election: election,
          turnout: turnout,
          society: SocietyState.initial(),
        ),
        throwsArgumentError,
      );
    });

    test('未完了選挙（winnerId null）→ ArgumentError', () {
      final election = Election(
        id: 'e',
        title: 't',
        scale: ElectionScale.village,
        candidates: _candidates(),
        voteCounts: const {'a': 3, 'b': 2},
      );
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      expect(
        () => TurnoutService.counterfactual(
          election: election,
          turnout: turnout,
          society: SocietyState.initial(),
        ),
        throwsArgumentError,
      );
    });

    test('actualVotes の合計が votesCast と一致する', () {
      final election = _completedElection(voteCounts: const {'a': 7, 'b': 3});
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      final sumActual = cf.actualVotes.values.fold<int>(0, (a, b) => a + b);
      expect(sumActual, turnout.votesCast);
      expect(cf.abstentionCount, turnout.abstentionCount);
    });

    test('counterfactualVotes の合計は eligibleVoters', () {
      final election = _completedElection(voteCounts: const {'a': 7, 'b': 3});
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      final sumCf =
          cf.counterfactualVotes.values.fold<int>(0, (a, b) => a + b);
      expect(sumCf, turnout.eligibleVoters);
      expect(sumCf, turnout.votesCast + turnout.abstentionCount);
    });

    test('棄権者0なら winnerChanged = false', () {
      // 全員投票した状態のスナップショットは作れないので、
      // actualVotes の合計が votesCast == eligibleVoters となる職業別内訳を直に作る。
      final election = _completedElection(voteCounts: const {'a': 25, 'b': 25});
      final turnout = TurnoutSnapshot(
        electionTitle: election.title,
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 50, voted: 50),
        ],
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      expect(cf.abstentionCount, 0);
      expect(cf.winnerChanged, isFalse);
    });

    test('全棄権者が一人の候補者に寄る極端ケースで当選者が変わる', () {
      // 実際の票は b が僅差で勝ち、棄権者50人は全て a 支持（voters を a 寄りにする）
      final election = _completedElection(
        voteCounts: const {'a': 24, 'b': 25},
        winnerId: 'b',
      );
      final aSupporters = List<Citizen>.generate(
        50,
        (_) => Citizen.initial(Job.farmer),
      );
      final turnout = TurnoutSnapshot(
        electionTitle: election.title,
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 50, voted: 0),
        ],
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
        voters: aSupporters,
      );
      expect(cf.abstentionCount, 50);
      expect(cf.winnerChanged, isTrue);
      expect(cf.counterfactualWinnerId, 'a');
      expect(cf.counterfactualWinnerName, '候補A');
      expect(cf.verdictLabel, '棄権が当選者を変えた');
    });

    test('actualWinner は election.winnerId の名前を解決する', () {
      final election = _completedElection(
        voteCounts: const {'a': 6, 'b': 4},
        winnerId: 'a',
      );
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      expect(cf.actualWinnerId, 'a');
      expect(cf.actualWinnerName, '候補A');
    });

    test('voters が null なら buildDefaultVoters にフォールバック', () {
      final election = _completedElection(voteCounts: const {'a': 6, 'b': 4});
      final turnout = TurnoutService.compute(
        election: election,
        society: SocietyState.initial(),
        scale: ElectionScale.village,
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      expect(cf.counterfactualVotes['a'], isNotNull);
      expect(cf.counterfactualVotes['b'], isNotNull);
    });

    test('actualVotes は raw 票の比率を維持する（スケール確認）', () {
      // raw 2:1 → votesCast 30 なら 20:10
      final election = _completedElection(voteCounts: const {'a': 20, 'b': 10});
      final turnout = TurnoutSnapshot(
        electionTitle: election.title,
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 30, voted: 30),
        ],
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      expect(cf.actualVotes['a'], 20);
      expect(cf.actualVotes['b'], 10);
      expect(cf.actualWinnerId, 'a');
    });

    test('sumRaw <= 0 なら actualVotes は均等割り', () {
      final election = _completedElection(voteCounts: const {'a': 0, 'b': 0});
      final turnout = TurnoutSnapshot(
        electionTitle: election.title,
        scale: ElectionScale.village,
        jobBreakdown: [
          JobTurnout(job: Job.farmer, eligible: 31, voted: 31),
        ],
      );
      final cf = TurnoutService.counterfactual(
        election: election,
        turnout: turnout,
        society: SocietyState.initial(),
      );
      // 均等割り: 15 と 16（残差は最後の候補者が吸収）
      expect(cf.actualVotes['a'], 15);
      expect(cf.actualVotes['b'], 16);
    });
  });

  group('forGameState / counterfactualForGameState', () {
    test('currentElection あり → その選挙のスナップショット', () {
      final election = _completedElection();
      final state = _state(currentElection: election);
      final snapshot = TurnoutService.forGameState(state);
      expect(snapshot, isNotNull);
      expect(snapshot!.electionTitle, election.title);
    });

    test('currentElection 無し・pastElections のみ → 最後の過去選挙', () {
      final past = _completedElection(title: '過去の選挙');
      final state = _state(pastElections: [past]);
      final snapshot = TurnoutService.forGameState(state);
      expect(snapshot, isNotNull);
      expect(snapshot!.electionTitle, '過去の選挙');
    });

    test('どちらも無い → null', () {
      final state = _state();
      expect(TurnoutService.forGameState(state), isNull);
      expect(TurnoutService.counterfactualForGameState(state), isNull);
    });

    test('currentElection が pastElections より優先される', () {
      final past = _completedElection(title: '過去');
      final current = _completedElection(title: '現在');
      final state = _state(currentElection: current, pastElections: [past]);
      expect(TurnoutService.forGameState(state)!.electionTitle, '現在');
    });

    test('counterfactualForGameState: 完了選挙なら結果を返す', () {
      final election = _completedElection();
      final state = _state(currentElection: election);
      final cf = TurnoutService.counterfactualForGameState(state);
      expect(cf, isNotNull);
      expect(cf!.actualWinnerId, 'a');
    });

    test('counterfactualForGameState: 未完了なら null（例外を投げない）', () {
      final election = Election(
        id: 'e',
        title: 't',
        scale: ElectionScale.village,
        candidates: _candidates(),
      );
      final state = _state(currentElection: election);
      expect(TurnoutService.counterfactualForGameState(state), isNull);
    });

    test('forGameState に playerAbstained を渡せる', () {
      final election = _completedElection();
      final state = _state(currentElection: election);
      final s1 = TurnoutService.forGameState(state);
      final s2 = TurnoutService.forGameState(state, playerAbstained: true);
      expect(s2!.votesCast, s1!.votesCast - 1); // player job = farmer
    });
  });
}
