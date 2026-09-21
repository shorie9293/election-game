import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/services/election_service.dart';
import 'package:election_game/domain/services/opinion_service.dart';

/// 支持率シミュレーションを提供する純粋関数サービス
///
/// 候補者ごとの支持シェア・有権者の第一選択・職業別親和性を計算する。
class SupportSimulationService {
  SupportSimulationService._();

  /// 既定の有権者集合（全職業ぶんの初期市民、10人）
  static List<Citizen> buildDefaultVoters() {
    return Job.values.map((j) => Citizen.initial(j)).toList();
  }

  /// 世論の頑固さに基づくラベル
  ///
  /// computeStubbornness の値 s に対し:
  /// - s < 0.35 → '開かれた世論'
  /// - s < 0.65 → '慎重な世論'
  /// - else → '変化を嫌う世論'
  static String stubbornnessLabel(SocietyState society) {
    final s = OpinionService.computeStubbornness(society);
    if (s < 0.35) return '開かれた世論';
    if (s < 0.65) return '慎重な世論';
    return '変化を嫌う世論';
  }

  /// 支持率シミュレーションを実行する
  ///
  /// [voters] が null または空の場合は [buildDefaultVoters] にフォールバックする。
  /// 各候補者について全有権者の支持変動値を平均した rawAffinity を求め、
  /// 総和で正規化して supportRate とする。supporterCount は各有権者の
  /// 第一選択（同値は candidateId 昇順で先のもの）を集計する。
  /// [title] を渡すと electionTitle をそれで上書きする（現在進行中の選挙名など）。
  static SupportSimulation compute({
    required List<Candidate> candidates,
    required SocietyState society,
    Election? lastElection,
    List<Citizen>? voters,
    String? title,
  }) {
    final effectiveVoters =
        (voters == null || voters.isEmpty) ? buildDefaultVoters() : voters;

    // 候補者ごとの rawAffinity（有権者平均の親和性）
    final rawAffinities = <String, double>{};
    for (final candidate in candidates) {
      if (effectiveVoters.isEmpty) {
        rawAffinities[candidate.id] = 0.0;
        continue;
      }
      var sum = 0.0;
      for (final voter in effectiveVoters) {
        sum += OpinionService.computeSupportChange(
            voter, candidate, society, lastElection);
      }
      rawAffinities[candidate.id] = sum / effectiveVoters.length;
    }

    // 第一選択の集計（同値は candidateId 昇順で先の候補者に票）
    final supporterCounts = <String, int>{};
    for (final candidate in candidates) {
      supporterCounts[candidate.id] = 0;
    }
    for (final voter in effectiveVoters) {
      String? bestId;
      double? bestValue;
      for (final candidate in candidates) {
        final value = OpinionService.computeSupportChange(
            voter, candidate, society, lastElection);
        if (bestValue == null ||
            value > bestValue ||
            (value == bestValue && candidate.id.compareTo(bestId!) < 0)) {
          bestId = candidate.id;
          bestValue = value;
        }
      }
      if (bestId != null) {
        supporterCounts[bestId] = supporterCounts[bestId]! + 1;
      }
    }

    // 正規化
    final totalWeight = rawAffinities.values.fold<double>(0, (a, b) => a + b);
    final snapshots = <SupportSnapshot>[];
    for (final candidate in candidates) {
      double supportRate;
      if (totalWeight <= 0) {
        // 総和ゼロなら均等割り（候補者ゼロならループ自体が回らない）
        supportRate = 1 / candidates.length;
      } else {
        supportRate = (rawAffinities[candidate.id]! / totalWeight)
            .clamp(0.0, 1.0)
            .toDouble();
      }
      snapshots.add(SupportSnapshot(
        candidateId: candidate.id,
        candidateName: candidate.name,
        supportRate: supportRate,
        rawAffinity: rawAffinities[candidate.id]!,
        supporterCount: supporterCounts[candidate.id] ?? 0,
      ));
    }

    // 支持率降順・同率は candidateId 昇順
    snapshots.sort((a, b) {
      final cmp = b.supportRate.compareTo(a.supportRate);
      if (cmp != 0) return cmp;
      return a.candidateId.compareTo(b.candidateId);
    });

    return SupportSimulation(
      electionTitle: title ?? lastElection?.title ?? '支持率シミュレーション',
      snapshots: snapshots,
      voterCount: effectiveVoters.length,
      moodLabel: society.moodLabel,
      stubbornnessLabel: stubbornnessLabel(society),
      hasHistory: lastElection != null && lastElection.winnerId != null,
    );
  }

  /// 候補者ごとに「職業別の平均親和性」が最大の職業を返す
  ///
  /// 同値は Job.index 昇順で先の職業を採用する。
  /// 有権者が居ない（voters が空でなくとも該当なしの場合は生じないが、
  /// voters が null/空の場合は [buildDefaultVoters] を用いる）。
  static Map<String, Job> topJobPerCandidate({
    required List<Candidate> candidates,
    required SocietyState society,
    Election? lastElection,
    List<Citizen>? voters,
  }) {
    final effectiveVoters =
        (voters == null || voters.isEmpty) ? buildDefaultVoters() : voters;

    final result = <String, Job>{};
    for (final candidate in candidates) {
      if (effectiveVoters.isEmpty) continue;

      // 職業ごとの平均親和性
      final affinityPerJob = <Job, double>{};
      for (final job in Job.values) {
        final jobVoters =
            effectiveVoters.where((v) => v.job == job).toList();
        if (jobVoters.isEmpty) continue;
        var sum = 0.0;
        for (final voter in jobVoters) {
          sum += OpinionService.computeSupportChange(
              voter, candidate, society, lastElection);
        }
        affinityPerJob[job] = sum / jobVoters.length;
      }
      if (affinityPerJob.isEmpty) continue;

      // 最大値の職業（同値は Job.index 昇順）
      Job? bestJob;
      double? bestValue;
      for (final job in Job.values) {
        final value = affinityPerJob[job];
        if (value == null) continue;
        if (bestValue == null || value > bestValue) {
          bestJob = job;
          bestValue = value;
        }
      }
      if (bestJob != null) {
        result[candidate.id] = bestJob;
      }
    }
    return result;
  }

  /// ゲーム状態からシミュレーションを実行する
  ///
  /// 現在の選挙が無い場合は ElectionService.determineCandidates で候補者を決定する。
  /// 前回選挙は pastElections の最後のものを用いる。
  static SupportSimulation forGameState(
    GameState state, {
    List<Citizen>? voters,
  }) {
    final candidates = state.currentElection?.candidates ??
        ElectionService.determineCandidates(state.society);
    final lastElection =
        state.pastElections.isNotEmpty ? state.pastElections.last : null;
    return compute(
      candidates: candidates,
      society: state.society,
      lastElection: lastElection,
      voters: voters,
      // 進行中の選挙があればその名前を優先する
      title: state.currentElection?.title,
    );
  }
}
