import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/opinion_service.dart';

void main() {
  group('OpinionService.computeProfessionPolicyAffinity', () {
    test('Farmerが農業/環境候補に高い親和性を持つ', () {
      final farmer = Citizen.initial(Job.farmer);
      // 環境政策を持つ候補 (田中美咲: 環境投資)
      final envCandidate = Candidate.samples()[3]; // 田中美咲
      // 田中美咲: '環境' policies
      final affinity = OpinionService.computeProfessionPolicyAffinity(
        farmer.job,
        envCandidate,
      );

      // farmer concerns: agriculture, environment → 'agriculture', 'environment' category matches
      // 田中美咲 has 2 policies: '経済' (起業支援) and '環境' (環境投資)
      // '環境' matches environment concern
      // effects of '環境投資': {environment: 8, lifeCost: 3} = 11
      // effects of '起業支援': {employment: 8, lifeCost: -3} = 5
      // total effects sum = 11 + 5 = 16
      // matching sum = 11
      // affinity = 11/16 ≈ 0.6875
      expect(affinity, greaterThan(0.5));
      expect(affinity, lessThanOrEqualTo(1.0));
    });

    test('Merchantが経済/税制候補に高い親和性を持つ', () {
      final merchant = Citizen.initial(Job.merchant);
      // 山田太郎: 2つとも '経済' policy
      final economyCandidate = Candidate.samples()[0]; // 山田太郎

      final affinity = OpinionService.computeProfessionPolicyAffinity(
        merchant.job,
        economyCandidate,
      );

      // merchant concerns: economy, tax → 'economy', 'tax'
      // 山田太郎: 2 policies both '経済' → matches 'economy'
      // All policies match → affinity = 1.0
      expect(affinity, 1.0);
    });

    test('無職が雇用/医療候補に高い親和性を持つ', () {
      final unemployed = Citizen.initial(Job.unemployed);
      // 佐藤花子: '医療'(医療拡充) and '教育'(教育無償化)
      final candidate = Candidate.samples()[1]; // 佐藤花子

      final affinity = OpinionService.computeProfessionPolicyAffinity(
        unemployed.job,
        candidate,
      );

      // unemployed concerns: employment, healthcare
      // 佐藤花子: '医療' (医療拡充) matches healthcare
      // Total effects: 10+5 + 10+5 = 30
      // Matching (医療拡充): 10+5 = 15
      // affinity = 15/30 = 0.5
      expect(affinity, greaterThan(0.0));
      expect(affinity, lessThanOrEqualTo(1.0));
    });

    test('候補者が公約なしの場合は0.5を返す', () {
      final farmer = Citizen.initial(Job.farmer);
      final noPolicyCandidate = Candidate(
        id: 'no_policy',
        name: '無公約',
        portraitKey: 'none',
        faction: '無所属',
        personality: '静観',
        policies: [],
      );

      final affinity = OpinionService.computeProfessionPolicyAffinity(
        farmer.job,
        noPolicyCandidate,
      );

      expect(affinity, 0.5);
    });
  });

  group('OpinionService.computeIncumbentAchievement', () {
    test('良い政策で満足度が高い', () {
      final citizen = Citizen.initial(Job.merchant);
      // 生活パラメータを低めに設定
      final poorCitizen = citizen.copyWith(
        lifeParams: {
          'lifeCost': 30,
          'healthcare': 30,
          'education': 30,
          'employment': 30,
          'environment': 30,
          'safety': 30,
        },
      );
      // 当選者が生活を改善する政策を持っている
      final goodWinner = Candidate(
        id: 'good_winner',
        name: '良い当選者',
        portraitKey: 'none',
        faction: '良政の会',
        personality: '皆のために',
        policies: [
          Policy(
            title: '雇用創出',
            description: '雇用を増やす',
            category: '経済',
            effects: {'employment': 15, 'lifeCost': 5},
          ),
          Policy(
            title: '医療改善',
            description: '医療を良くする',
            category: '医療',
            effects: {'healthcare': 10},
          ),
        ],
      );

      final achievement = OpinionService.computeIncumbentAchievement(
        poorCitizen,
        goodWinner,
      );

      // totalEffects: {employment: 15, lifeCost: 5, healthcare: 10}
      // 3 params affected, all improved (positive values) → 3/3 = 1.0
      expect(achievement, 1.0);
    });

    test('悪い政策で満足度が低い', () {
      final citizen = Citizen.initial(Job.merchant);
      final goodCitizen = citizen.copyWith(
        lifeParams: {
          'lifeCost': 70,
          'healthcare': 70,
          'education': 70,
          'employment': 70,
          'environment': 70,
          'safety': 70,
        },
      );
      // 当選者が生活を悪化させる政策を持っている
      final badWinner = Candidate(
        id: 'bad_winner',
        name: '悪い当選者',
        portraitKey: 'none',
        faction: '悪政の会',
        personality: '自分のため',
        policies: [
          Policy(
            title: '増税',
            description: '税金を上げる',
            category: '経済',
            effects: {'lifeCost': -15, 'employment': -5},
          ),
          Policy(
            title: '医療削減',
            description: '医療費を削る',
            category: '医療',
            effects: {'healthcare': -10},
          ),
        ],
      );

      final achievement = OpinionService.computeIncumbentAchievement(
        goodCitizen,
        badWinner,
      );

      // totalEffects: {lifeCost: -15, employment: -5, healthcare: -10}
      // 3 params affected, all worsened (negative values) → 0/3 = 0.0
      expect(achievement, 0.0);
    });
  });

  group('OpinionService.computeStubbornness', () {
    test('ムード0.1（なれ合い）で頑固さ0.8', () {
      final society = SocietyState(happiness: 50, mood: 0.1, electionCount: 0);
      final stubbornness = OpinionService.computeStubbornness(society);
      expect(stubbornness, 0.8);
    });

    test('ムード0.3（融和）で頑固さ0.5', () {
      final society = SocietyState(happiness: 50, mood: 0.3, electionCount: 0);
      final stubbornness = OpinionService.computeStubbornness(society);
      expect(stubbornness, 0.5);
    });

    test('ムード0.5（健全な対立）で頑固さ0.2', () {
      final society = SocietyState(happiness: 50, mood: 0.5, electionCount: 0);
      final stubbornness = OpinionService.computeStubbornness(society);
      expect(stubbornness, 0.2);
    });

    test('ムード0.7（不健全な対立）で頑固さ0.7', () {
      final society = SocietyState(happiness: 50, mood: 0.7, electionCount: 0);
      final stubbornness = OpinionService.computeStubbornness(society);
      expect(stubbornness, 0.7);
    });

    test('ムード0.9（独裁）で頑固さ0.9', () {
      final society = SocietyState(happiness: 50, mood: 0.9, electionCount: 0);
      final stubbornness = OpinionService.computeStubbornness(society);
      expect(stubbornness, 0.9);
    });
  });

  group('OpinionService.computeSupportChange', () {
    test('前回選挙なしの場合、親和性をそのまま返す', () {
      final merchant = Citizen.initial(Job.merchant);
      final economyCandidate = Candidate.samples()[0]; // 山田太郎 (経済)

      final support = OpinionService.computeSupportChange(
        merchant,
        economyCandidate,
        SocietyState(happiness: 50, mood: 0.5, electionCount: 0),
        null,
      );

      // merchant affinity with economy candidate = 1.0, no stubbornness applied since no lastElection
      expect(support, 1.0);
    });

    test('現職が良い公約達成なら支持が上がる', () {
      final merchant = Citizen.initial(Job.merchant);
      final poorCitizen = merchant.copyWith(
        lifeParams: {
          'lifeCost': 30,
          'healthcare': 30,
          'education': 30,
          'employment': 30,
          'environment': 30,
          'safety': 30,
        },
      );

      final goodWinner = Candidate(
        id: 'good_winner',
        name: '良い当選者',
        portraitKey: 'none',
        faction: '良政の会',
        personality: '皆のために',
        policies: [
          Policy(
            title: '雇用創出',
            description: '雇用を増やす',
            category: '経済',
            effects: {'employment': 15, 'lifeCost': 5},
          ),
          Policy(
            title: '医療改善',
            description: '医療を良くする',
            category: '医療',
            effects: {'healthcare': 10},
          ),
        ],
      );

      final lastElection = Election(
        id: 'last_election',
        title: '前回選挙',
        scale: ElectionScale.village,
        candidates: [goodWinner],
        winnerId: 'good_winner',
        voteCounts: {'good_winner': 100},
      );

      final society = SocietyState(happiness: 50, mood: 0.5, electionCount: 1);

      // 現職（good_winner）への支持を計算
      final support = OpinionService.computeSupportChange(
        poorCitizen,
        goodWinner,
        society,
        lastElection,
      );

      // affinity: merchant x goodWinner (経済 policy) → high affinity
      // achievement: 3/3 = 1.0
      // base = affinity * 0.4 + 1.0 * 0.6
      // stubbornness = 0.2 (mood 0.5)
      // final = base * (1 - 0.2 * 0.5) = base * 0.9
      // Should be fairly high

      expect(support, greaterThan(0.5));
      expect(support, lessThanOrEqualTo(1.0));
    });

    test('現職が悪い公約なら支持が下がる', () {
      final merchant = Citizen.initial(Job.merchant);
      final goodCitizen = merchant.copyWith(
        lifeParams: {
          'lifeCost': 70,
          'healthcare': 70,
          'education': 70,
          'employment': 70,
          'environment': 70,
          'safety': 70,
        },
      );

      final badWinner = Candidate(
        id: 'bad_winner',
        name: '悪い当選者',
        portraitKey: 'none',
        faction: '悪政の会',
        personality: '自分のため',
        policies: [
          Policy(
            title: '増税',
            description: '税金を上げる',
            category: '経済',
            effects: {'lifeCost': -15, 'employment': -5},
          ),
          Policy(
            title: '医療削減',
            description: '医療費を削る',
            category: '医療',
            effects: {'healthcare': -10},
          ),
        ],
      );

      final lastElection = Election(
        id: 'last_election',
        title: '前回選挙',
        scale: ElectionScale.village,
        candidates: [badWinner],
        winnerId: 'bad_winner',
        voteCounts: {'bad_winner': 100},
      );

      final society = SocietyState(happiness: 50, mood: 0.5, electionCount: 1);

      final support = OpinionService.computeSupportChange(
        goodCitizen,
        badWinner,
        society,
        lastElection,
      );

      // affinity: merchant x badWinner (経済 policy) → high affinity
      // achievement: 0/3 = 0.0
      // base = affinity * 0.4 + 0.0 * 0.6 = affinity * 0.4
      // stubbornness = 0.2
      // final = base * (1 - 0.2 * 0.5) = base * 0.9
      // Should be lower than affinity alone

      expect(support, lessThan(0.6));
      expect(support, greaterThanOrEqualTo(0.0));
    });

    test('挑戦者が現職失敗時に支持を伸ばす', () {
      final merchant = Citizen.initial(Job.merchant);
      final goodCitizen = merchant.copyWith(
        lifeParams: {
          'lifeCost': 70,
          'healthcare': 70,
          'education': 70,
          'employment': 70,
          'environment': 70,
          'safety': 70,
        },
      );

      final badWinner = Candidate(
        id: 'bad_winner',
        name: '悪い当選者',
        portraitKey: 'none',
        faction: '悪政の会',
        personality: '自分のため',
        policies: [
          Policy(
            title: '増税',
            description: '税金を上げる',
            category: '経済',
            effects: {'lifeCost': -15, 'employment': -5},
          ),
          Policy(
            title: '医療削減',
            description: '医療費を削る',
            category: '医療',
            effects: {'healthcare': -10},
          ),
        ],
      );

      // 挑戦者: 経済政策を持つ (merchant好み)
      final challenger = Candidate(
        id: 'challenger',
        name: '挑戦者',
        portraitKey: 'none',
        faction: '改革の会',
        personality: '変革',
        policies: [
          Policy(
            title: '経済活性化',
            description: '経済を良くする',
            category: '経済',
            effects: {'employment': 10, 'lifeCost': 5},
          ),
        ],
      );

      final lastElection = Election(
        id: 'last_election',
        title: '前回選挙',
        scale: ElectionScale.village,
        candidates: [badWinner, challenger],
        winnerId: 'bad_winner',
        voteCounts: {'bad_winner': 60, 'challenger': 40},
      );

      final society = SocietyState(happiness: 50, mood: 0.5, electionCount: 1);

      final support = OpinionService.computeSupportChange(
        goodCitizen,
        challenger,
        society,
        lastElection,
      );

      // challenger is NOT the winner
      // affinity: merchant x challenger (経済 policy) → high
      // achievement of badWinner = 0.0
      // base = affinity * 0.7 + (1-0.0) * 0.3 = affinity * 0.7 + 0.3
      // stubbornness = 0.2
      // final = base * (1 - 0.1)
      // Should be quite high because incumbent failed

      expect(support, greaterThan(0.5));
      expect(support, lessThanOrEqualTo(1.0));
    });

    test('前回選挙に当選者なしの場合、親和性ベースで頑固さ適用', () {
      final merchant = Citizen.initial(Job.merchant);
      final economyCandidate = Candidate.samples()[0];

      final lastElection = Election(
        id: 'last_election',
        title: '前回選挙',
        scale: ElectionScale.village,
        candidates: [economyCandidate],
        // winnerId: null — no winner
      );

      final society = SocietyState(happiness: 50, mood: 0.1, electionCount: 1); // high stubbornness

      final support = OpinionService.computeSupportChange(
        merchant,
        economyCandidate,
        society,
        lastElection,
      );

      // No winner → return affinity directly (or apply stubbornness?)
      // The spec says: "If lastElection exists and has a winner" — so no winner means go to no-lastElection path
      // Return affinity directly = 1.0
      expect(support, 1.0);
    });
  });
}
