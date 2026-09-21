import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/domain/services/support_simulation_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// テスト用の候補者（農業寄り・医療寄り）
List<Candidate> _testCandidates() => [
      Candidate(
        id: 'a_farm',
        name: '農家候補',
        portraitKey: 'p1',
        faction: '農',
        personality: '農業第一',
        policies: [
          const Policy(
            title: '農業振興',
            description: '農家を支援',
            category: '農業',
            effects: {'employment': 10, 'environment': 5},
          ),
        ],
      ),
      Candidate(
        id: 'b_health',
        name: '医療候補',
        portraitKey: 'p2',
        faction: '医',
        personality: '医療第一',
        policies: [
          const Policy(
            title: '医療拡充',
            description: '医療を充実',
            category: '医療',
            effects: {'healthcare': 10, 'education': 5},
          ),
        ],
      ),
    ];

Election _lastElection(String winnerId, {required List<Candidate> candidates}) {
  return Election(
    id: 'past_1',
    title: '前回の選挙',
    scale: ElectionScale.town,
    candidates: candidates,
    turnDeadline: 3,
    voteCounts: const {'a_farm': 5, 'b_health': 4},
    winnerId: winnerId,
  );
}

void main() {
  group('buildDefaultVoters', () {
    test('全職業ぶんの 10 人を返す', () {
      final voters = SupportSimulationService.buildDefaultVoters();
      expect(voters.length, 10);
      expect(
        voters.map((v) => v.job).toSet(),
        Job.values.toSet(),
      );
    });
  });

  group('stubbornnessLabel', () {
    // computeStubbornness の返り値が閾値を跨ぐ mood 値を選ぶ
    test('mood 0.0（頑固さ0.8）→ 変化を嫌う世論', () {
      expect(
        SupportSimulationService.stubbornnessLabel(
            SocietyState(happiness: 50, mood: 0.0, electionCount: 0)),
        '変化を嫌う世論',
      );
    });

    test('mood 0.3（頑固さ0.5）→ 慎重な世論', () {
      expect(
        SupportSimulationService.stubbornnessLabel(
            SocietyState(happiness: 50, mood: 0.3, electionCount: 0)),
        '慎重な世論',
      );
    });

    test('mood 0.5（頑固さ0.2）→ 開かれた世論', () {
      expect(
        SupportSimulationService.stubbornnessLabel(
            SocietyState(happiness: 50, mood: 0.5, electionCount: 0)),
        '開かれた世論',
      );
    });

    test('境界: 頑固さ 0.35 未満/以上は mood で決まる（0.34→慎重, 0.65→変化嫌い）', () {
      // mood 0.35 付近は頑固さ 0.5（融和）→ 慎重
      final s034 = SocietyState(happiness: 50, mood: 0.34, electionCount: 0);
      final s035 = SocietyState(happiness: 50, mood: 0.35, electionCount: 0);
      // mood 0.6-0.8 は頑固さ 0.7 → 変化を嫌う世論
      final s064 = SocietyState(happiness: 50, mood: 0.64, electionCount: 0);
      final s065 = SocietyState(happiness: 50, mood: 0.65, electionCount: 0);
      expect(SupportSimulationService.stubbornnessLabel(s034), '慎重な世論');
      expect(SupportSimulationService.stubbornnessLabel(s035), '慎重な世論');
      expect(SupportSimulationService.stubbornnessLabel(s064), '変化を嫌う世論');
      expect(SupportSimulationService.stubbornnessLabel(s065), '変化を嫌う世論');
    });
  });

  group('compute', () {
    test('決定性: 同条件で同一結果', () {
      final candidates = _testCandidates();
      final society = SocietyState.initial();
      final a = SupportSimulationService.compute(
          candidates: candidates, society: society);
      final b = SupportSimulationService.compute(
          candidates: candidates, society: society);
      expect(a, equals(b));
    });

    test('supportRate の総和が 1.0 になる（許容誤差 1e-9）', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      final sum =
          sim.snapshots.fold<double>(0, (acc, s) => acc + s.supportRate);
      expect((sum - 1.0).abs(), lessThan(1e-9));
    });

    test('supportRate は 0.0-1.0 に収まる', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      for (final s in sim.snapshots) {
        expect(s.supportRate, inInclusiveRange(0.0, 1.0));
        expect(s.rawAffinity, inInclusiveRange(0.0, 1.0));
      }
    });

    test('snapshots は supportRate 降順・同率は candidateId 昇順', () {
      // 4サンプル候補で確認
      final sim = SupportSimulationService.compute(
        candidates: Candidate.samples(),
        society: SocietyState.initial(),
      );
      for (var i = 0; i < sim.snapshots.length - 1; i++) {
        final cur = sim.snapshots[i];
        final next = sim.snapshots[i + 1];
        if (cur.supportRate == next.supportRate) {
          expect(cur.candidateId.compareTo(next.candidateId), lessThan(0));
        } else {
          expect(cur.supportRate, greaterThan(next.supportRate));
        }
      }
    });

    test('supporterCount の合計が voterCount に一致', () {
      final voters = [
        Citizen.initial(Job.farmer),
        Citizen.initial(Job.doctor),
      ];
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
        voters: voters,
      );
      final sum = sim.snapshots.fold<int>(0, (acc, s) => acc + s.supporterCount);
      expect(sim.voterCount, voters.length);
      expect(sum, sim.voterCount);
    });

    test('自作 voters リストが使われる（1人だと supporterCount は一人が全票）', () {
      final voters = [Citizen.initial(Job.farmer)];
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
        voters: voters,
      );
      expect(sim.voterCount, 1);
      // 農家は農業政策に親和するので a_farm が全票
      final top = sim.leader!;
      expect(top.candidateId, 'a_farm');
      expect(top.supporterCount, 1);
      expect(top.supportRate, 1.0);
    });

    test('voters が null/空なら buildDefaultVoters にフォールバック', () {
      final simNull = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      final simEmpty = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
        voters: const [],
      );
      expect(simNull.voterCount, 10);
      expect(simEmpty.voterCount, 10);
      expect(simNull, equals(simEmpty));
    });

    test('lastElection があると electionTitle がそのタイトルになる', () {
      final candidates = _testCandidates();
      final sim = SupportSimulationService.compute(
        candidates: candidates,
        society: SocietyState.initial(),
        lastElection: _lastElection('a_farm', candidates: candidates),
      );
      expect(sim.electionTitle, '前回の選挙');
      expect(sim.hasHistory, isTrue);
    });

    test('lastElection が無いと electionTitle はデフォルト・hasHistory false', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      expect(sim.electionTitle, '支持率シミュレーション');
      expect(sim.hasHistory, isFalse);
    });

    test('winnerId 無しの lastElection は hasHistory false', () {
      final candidates = _testCandidates();
      final last = _lastElection('a_farm', candidates: candidates)
          .copyWith(clearWinner: true);
      final sim = SupportSimulationService.compute(
        candidates: candidates,
        society: SocietyState.initial(),
        lastElection: last,
      );
      expect(sim.hasHistory, isFalse);
    });

    test('moodLabel が society から伝播する', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState(happiness: 50, mood: 0.5, electionCount: 0),
      );
      expect(sim.moodLabel, '健全な対立');
    });

    test('stubbornnessLabel が計算される', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(), // mood 0.3 → 頑固さ 0.5
      );
      expect(sim.stubbornnessLabel, '慎重な世論');
    });

    test('候補者ゼロで空 simulation が返る', () {
      final sim = SupportSimulationService.compute(
        candidates: [],
        society: SocietyState.initial(),
      );
      expect(sim.isEmpty, isTrue);
      expect(sim.snapshots, isEmpty);
      expect(sim.leader, isNull);
      expect(sim.voterCount, 10);
    });

    test('leader は snapshots.first・snapshotFor は ID 検索・不明は null', () {
      final sim = SupportSimulationService.compute(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      expect(sim.leader, same(sim.snapshots.first));
      final found = sim.snapshotFor('b_health');
      expect(found, isNotNull);
      expect(found!.candidateId, 'b_health');
      expect(sim.snapshotFor('nonexistent'), isNull);
    });
  });

  group('topJobPerCandidate', () {
    test('候補者ごとに最適な職業が返る', () {
      final jobs = SupportSimulationService.topJobPerCandidate(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
      );
      expect(jobs.keys, containsAll(['a_farm', 'b_health']));
      // 農業政策には farmer が最適
      expect(jobs['a_farm'], Job.farmer);
    });

    test('voters null/空はデフォルト有権者を使う', () {
      final jobs = SupportSimulationService.topJobPerCandidate(
        candidates: _testCandidates(),
        society: SocietyState.initial(),
        voters: const [],
      );
      expect(jobs.length, 2);
    });

    test('政策ゼロの候補者も含まれる（親和性 0.5 で計算）', () {
      final noPolicy = Candidate(
        id: 'c_none',
        name: '無公約',
        portraitKey: 'p3',
        faction: '無',
        personality: '自由',
        policies: const [],
      );
      final jobs = SupportSimulationService.topJobPerCandidate(
        candidates: [noPolicy],
        society: SocietyState.initial(),
      );
      expect(jobs.containsKey('c_none'), isTrue);
      expect(jobs['c_none'], isA<Job>());
    });
  });

  group('forGameState', () {
    test('currentElection 無しでも determineCandidates 経由で候補者が得られる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.farmer),
        society: SocietyState.initial(),
      );
      final sim = SupportSimulationService.forGameState(state);
      expect(sim.isEmpty, isFalse);
      // determineCandidates が何人返しても空でない
      final expected = ElectionService.determineCandidates(state.society);
      expect(sim.snapshots.length, expected.length);
      expect(sim.electionTitle, '支持率シミュレーション');
    });

    test('currentElection の候補者とタイトルを使う', () {
      final candidates = _testCandidates();
      final state = GameState(
        citizen: Citizen.initial(Job.farmer),
        society: SocietyState.initial(),
        currentElection: Election(
          id: 'now_1',
          title: '現職選挙',
          scale: ElectionScale.village,
          candidates: candidates,
        ),
      );
      final sim = SupportSimulationService.forGameState(state);
      expect(sim.electionTitle, '現職選挙');
      expect(sim.snapshots.length, 2);
    });

    test('pastElections の最後が lastElection になる（hasHistory）', () {
      final candidates = _testCandidates();
      final state = GameState(
        citizen: Citizen.initial(Job.farmer),
        society: SocietyState.initial(),
        pastElections: [_lastElection('a_farm', candidates: candidates)],
      );
      final sim = SupportSimulationService.forGameState(state);
      expect(sim.electionTitle, '前回の選挙');
      expect(sim.hasHistory, isTrue);
    });

    test('自作 voters を渡せる', () {
      final state = GameState(
        citizen: Citizen.initial(Job.doctor),
        society: SocietyState.initial(),
      );
      final sim = SupportSimulationService.forGameState(
        state,
        voters: [Citizen.initial(Job.doctor)],
      );
      expect(sim.voterCount, 1);
    });
  });

  group('SupportSimulation 検証', () {
    test('負の voterCount は ArgumentError', () {
      expect(
        () => SupportSimulation(
          electionTitle: 't',
          snapshots: const [],
          voterCount: -1,
          moodLabel: '融和',
          stubbornnessLabel: '慎重な世論',
          hasHistory: false,
        ),
        throwsArgumentError,
      );
    });

    test('SupportSimulation の copyWith が機能する', () {
      final base = SupportSimulation(
        electionTitle: 't',
        snapshots: const [],
        voterCount: 5,
        moodLabel: '融和',
        stubbornnessLabel: '慎重な世論',
        hasHistory: false,
      );
      final updated = base.copyWith(voterCount: 9, hasHistory: true);
      expect(updated.voterCount, 9);
      expect(updated.hasHistory, isTrue);
      expect(updated.electionTitle, 't');
    });
  });
}
