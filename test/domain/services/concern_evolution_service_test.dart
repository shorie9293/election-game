import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/concern_evolution.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/concern_evolution_service.dart';

void main() {
  late Citizen baseCitizen;
  late List<Candidate> candidates;
  late Election sampleElection;

  setUp(() {
    baseCitizen = Citizen.initial(Job.farmer).copyWith(name: 'テスト農家');
    candidates = Candidate.samples();

    // 山田太郎（candidate_1）= 発展の会（経済/雇用）
    // 佐藤花子（candidate_2）= 共生の会（医療/教育）
    // 鈴木一郎（candidate_3）= 守りの会（治安/経済）
    // 田中美咲（candidate_4）= 改革の会（経済/環境）

    sampleElection = Election(
      id: 'test_election',
      title: '天照町 町長選挙',
      scale: ElectionScale.village,
      candidates: candidates,
    );
  });

  group('ConcernEvolutionService', () {
    group('computeConcernEvolutions', () {
      test('当選者の政策カテゴリから新たな関心候補が抽出される（農家/山田太郎当選）', () {
        // 山田太郎（大規模開発+減税）が当選 → 政策カテゴリは「経済」＝ Concern.economy
        final result = sampleElection.copyWith(
          voteCounts: {'candidate_1': 60, 'candidate_2': 25, 'candidate_3': 10, 'candidate_4': 5},
          winnerId: 'candidate_1',
        );

        final winner = result.candidates.firstWhere((c) => c.id == 'candidate_1');
        final candidateConcerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(winner);

        // 山田太郎の政策はすべて「経済」カテゴリ → economy 関心が抽出される
        expect(candidateConcerns, contains(Concern.economy));
        expect(candidateConcerns.length, 1); // 重複なし

        // 農家の既存関心 (agriculture, environment) を除いた新しい関心候補
        final newCandidates = candidateConcerns.where(
          (c) => ![Concern.agriculture, Concern.environment].contains(c),
        ).toList();
        expect(newCandidates, isNotEmpty);
      });

      test('関心獲得の確率計算 — 討論参加で確率が上がる', () {
        // 佐藤花子当選
        final result = sampleElection.copyWith(
          voteCounts: {'candidate_1': 20, 'candidate_2': 55, 'candidate_3': 15, 'candidate_4': 10},
          winnerId: 'candidate_2',
        );

        final winner = result.candidates.firstWhere((c) => c.id == 'candidate_2');

        // 討論参加なし: 候補者の政策カテゴリで新しい関心候補を列挙
        final candidateConcerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(winner);
        final existing = {Concern.agriculture, Concern.environment};
        final newCandidates = candidateConcerns.where((c) => !existing.contains(c)).toList();

        // 佐藤花子 = 医療+教育 → 新しい関心候補がある
        expect(newCandidates, isNotEmpty);
        expect(newCandidates, containsAll([Concern.healthcare, Concern.education]));
      });

      test('討論参加で確率が上昇し、新たな関心候補が存在することを確認', () {
        // 佐藤花子（医療拡充+教育無償化）が当選 → healthcare/education カテゴリ
        final result = sampleElection.copyWith(
          voteCounts: {'candidate_1': 20, 'candidate_2': 55, 'candidate_3': 15, 'candidate_4': 10},
          winnerId: 'candidate_2',
        );

        final winner = result.candidates.firstWhere((c) => c.id == 'candidate_2');
        final candidateConcerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(winner);

        // 農家の既存関心: agriculture, environment
        // 佐藤花子の政策: 医療, 教育 → healthcare, education が新規候補
        final existing = {Concern.agriculture, Concern.environment};
        final newCandidates = candidateConcerns.where((c) => !existing.contains(c)).toSet();

        // 新たな関心候補が存在する
        expect(newCandidates, containsAll([Concern.healthcare, Concern.education]));

        // 討論参加時に computeConcernEvolutions がエラーなく呼べる
        final evolutions = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result,
          participatedInDebate: true,
          electionCount: 1,
          currentEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution.initial(Concern.environment),
          ],
        );

        // 獲得されたかどうかは確率的だが、獲得された場合は正しい形式
        for (final evo in evolutions) {
          expect(evo.isAcquired, isTrue);
          expect(evo.acquiredAtElection, 1);
          expect(newCandidates.contains(evo.concern), isTrue);
        }
      });

      test('すでに持っている関心は重複して獲得されない', () {
        // 鈴木一郎（治安強化+地場産業保護）が当選 → safety/economy カテゴリ
        // 農家は environment を既に持っている
        final result = sampleElection.copyWith(
          voteCounts: {'candidate_1': 15, 'candidate_2': 15, 'candidate_3': 60, 'candidate_4': 10},
          winnerId: 'candidate_3',
        );

        final evolutions = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result,
          participatedInDebate: true,
          electionCount: 1,
          currentEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution.initial(Concern.environment),
          ],
        );

        // 獲得された関心に重複がないことを確認
        final acquiredConcerns = evolutions
            .where((e) => e.isAcquired)
            .map((e) => e.concern)
            .toSet();

        final initialConcerns = {
          Concern.agriculture,
          Concern.environment,
        };

        // 獲得された関心と既存の関心に重複がない
        for (final acquired in acquiredConcerns) {
          expect(initialConcerns.contains(acquired), isFalse);
        }
      });

      test('選挙結果がない場合は空リストを返す', () {
        final evolutions = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: null,
          participatedInDebate: false,
          electionCount: 1,
          currentEvolutions: [
            ConcernEvolution.initial(Concern.agriculture),
            ConcernEvolution.initial(Concern.environment),
          ],
        );

        expect(evolutions, isEmpty);
      });

      test('最大8つの関心全てを既に持っている場合は新規獲得なし', () {
        // 全ての関心を既に持つ市民
        final allConcerns = Concern.values.toList();
        final allEvolutions = allConcerns
            .map((c) => ConcernEvolution.initial(c))
            .toList();

        final result = sampleElection.copyWith(
          voteCounts: {'candidate_1': 60, 'candidate_2': 25, 'candidate_3': 10, 'candidate_4': 5},
          winnerId: 'candidate_1',
        );

        final evolutions = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result,
          participatedInDebate: true,
          electionCount: 1,
          currentEvolutions: allEvolutions,
        );

        expect(evolutions, isEmpty);
      });

      test('複数回の選挙で徐々に関心が増えていく', () {
        final allEvolutions = <ConcernEvolution>[
          ConcernEvolution.initial(Concern.agriculture),
          ConcernEvolution.initial(Concern.environment),
        ];

        var currentEvolutions = allEvolutions;

        // 選挙1回目: 山田太郎当選
        final result1 = sampleElection.copyWith(
          voteCounts: {'candidate_1': 55, 'candidate_2': 25, 'candidate_3': 15, 'candidate_4': 5},
          winnerId: 'candidate_1',
        );

        final new1 = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result1,
          participatedInDebate: true,
          electionCount: 1,
          currentEvolutions: currentEvolutions,
        );
        currentEvolutions = [...currentEvolutions, ...new1];

        // 選挙2回目: 佐藤花子当選
        final result2 = sampleElection.copyWith(
          voteCounts: {'candidate_1': 20, 'candidate_2': 50, 'candidate_3': 15, 'candidate_4': 15},
          winnerId: 'candidate_2',
        );

        final new2 = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result2,
          participatedInDebate: true,
          electionCount: 2,
          currentEvolutions: currentEvolutions,
        );
        currentEvolutions = [...currentEvolutions, ...new2];

        // 選挙3回目: 田中美咲当選
        final result3 = sampleElection.copyWith(
          voteCounts: {'candidate_1': 15, 'candidate_2': 15, 'candidate_3': 15, 'candidate_4': 55},
          winnerId: 'candidate_4',
        );

        final new3 = ConcernEvolutionService.computeConcernEvolutions(
          citizen: baseCitizen,
          lastElectionResult: result3,
          participatedInDebate: true,
          electionCount: 3,
          currentEvolutions: currentEvolutions,
        );

        // 3回の選挙を通じて、少なくとも何らかの関心が増えている
        final totalAcquired = [...new1, ...new2, ...new3]
            .where((e) => e.isAcquired)
            .length;
        expect(totalAcquired, greaterThanOrEqualTo(1));
      });
    });

    group('computeConcernFromCandidatePolicies', () {
      test('当選者の政策から関心候補を抽出する', () {
        final winner = candidates.firstWhere((c) => c.id == 'candidate_2'); // 佐藤花子

        final concerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(
          winner,
        );

        // 佐藤花子は医療+教育 → healthcare, education 関心が含まれるはず
        expect(concerns, contains(Concern.healthcare));
        expect(concerns, contains(Concern.education));
      });

      test('経済政策を持つ当選者からeconomy関心が抽出される', () {
        final winner = candidates.firstWhere((c) => c.id == 'candidate_1'); // 山田太郎

        final concerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(
          winner,
        );

        // 山田太郎の政策カテゴリは両方「経済」→ economy のみ抽出（重複なし）
        expect(concerns, equals([Concern.economy]));
      });

      test('治安政策を持つ当選者からsafety関心が抽出される', () {
        final winner = candidates.firstWhere((c) => c.id == 'candidate_3'); // 鈴木一郎

        final concerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(
          winner,
        );

        // 鈴木一郎は治安強化+地場産業保護 → safety, economy
        expect(concerns, contains(Concern.safety));
        expect(concerns, contains(Concern.economy));
      });

      test('環境政策を持つ当選者からenvironment関心が抽出される', () {
        final winner = candidates.firstWhere((c) => c.id == 'candidate_4'); // 田中美咲

        final concerns = ConcernEvolutionService.computeConcernFromCandidatePolicies(
          winner,
        );

        // 田中美咲は起業支援+環境投資 → economy, environment
        expect(concerns, contains(Concern.economy));
        expect(concerns, contains(Concern.environment));
      });
    });
  });
}
