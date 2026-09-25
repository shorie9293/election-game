import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/opinion_service.dart';
import 'package:election_game/domain/services/support_simulation_service.dart';

/// 投票率（有権者参加率）の推定・可視化を提供する純粋関数サービス
class TurnoutService {
  TurnoutService._();

  /// 職業ごとの投票率倍率
  static const Map<Job, double> jobMultipliers = {
    Job.farmer: 1.10,
    Job.fisher: 1.02,
    Job.carpenter: 0.98,
    Job.merchant: 0.95,
    Job.teacher: 1.15,
    Job.doctor: 1.08,
    Job.official: 1.12,
    Job.artisan: 0.90,
    Job.student: 0.70,
    Job.unemployed: 0.55,
  };

  /// 規模別の基礎参加率
  static double baseTurnoutRate(ElectionScale scale) {
    switch (scale) {
      case ElectionScale.village:
        return 0.72;
      case ElectionScale.town:
        return 0.62;
      case ElectionScale.city:
        return 0.54;
    }
  }

  /// 有権者数 = scale.npcCount * 10
  static int eligibleVotersFor(ElectionScale scale) => scale.npcCount * 10;

  /// 全体投票率の推定値 (0.25-0.95 に clamp)
  ///
  /// rate = base + (mood - 0.5) * 0.20 + (stubbornness - 0.5) * 0.10
  static double estimateRate({
    required SocietyState society,
    required ElectionScale scale,
  }) {
    final base = baseTurnoutRate(scale);
    final moodTerm = (society.mood - 0.5) * 0.20;
    final stubbornness = OpinionService.computeStubbornness(society);
    final stubbornTerm = (stubbornness - 0.5) * 0.10;
    return (base + moodTerm + stubbornTerm).clamp(0.25, 0.95).toDouble();
  }

  /// 職業別内訳つきの投票率スナップショットを計算する
  ///
  /// jobBreakdown は Job.values の宣言順（全10職）。
  /// playerAbstained == true かつ player の職業が該当なら voted を1減らす。
  static TurnoutSnapshot compute({
    required Election election,
    required SocietyState society,
    required ElectionScale scale,
    Citizen? player,
    bool playerAbstained = false,
  }) {
    final rate = estimateRate(society: society, scale: scale);
    final playerAbstainsJob =
        playerAbstained && player != null ? player.job : null;

    final breakdown = <JobTurnout>[];
    for (final job in Job.values) {
      final multiplier = jobMultipliers[job] ?? 1.0;
      final jobRate = (rate * multiplier).clamp(0.05, 1.0).toDouble();
      var voted = (scale.npcCount * jobRate).round();
      if (playerAbstainsJob == job && voted > 0) {
        voted -= 1;
      }
      breakdown.add(JobTurnout(
        job: job,
        eligible: scale.npcCount,
        voted: voted,
      ));
    }

    return TurnoutSnapshot(
      electionTitle: election.title,
      scale: scale,
      jobBreakdown: breakdown,
      playerAbstained: playerAbstained,
    );
  }

  /// 棄権の反実仮想を計算する（選挙が完了していること）
  ///
  /// 実際の票を [TurnoutSnapshot.votesCast] にスケールし、
  /// 棄権者を支持変動の平均重みで按分して当選者が変わるかを判定する。
  static TurnoutCounterfactual counterfactual({
    required Election election,
    required TurnoutSnapshot turnout,
    required SocietyState society,
    List<Citizen>? voters,
  }) {
    if (election.voteCounts == null || election.winnerId == null) {
      throw ArgumentError.value(
          election, 'election', '選挙が未完了のため反実仮想を計算できない');
    }
    final raw = election.voteCounts!;
    final candidates = election.candidates;
    if (candidates.isEmpty) {
      throw ArgumentError.value(candidates, 'candidates', '候補者が空');
    }

    final total = turnout.votesCast;
    final abstentionCount = turnout.abstentionCount;

    // 1) 実際の投票を votesCast にスケール
    final actualVotes = <String, int>{};
    var sumRaw = 0;
    for (final c in candidates) {
      sumRaw += raw[c.id] ?? 0;
    }
    if (sumRaw <= 0) {
      // 均等割り
      var assigned = 0;
      for (var i = 0; i < candidates.length; i++) {
        final c = candidates[i];
        if (i == candidates.length - 1) {
          actualVotes[c.id] = total - assigned;
        } else {
          final share = total ~/ candidates.length;
          actualVotes[c.id] = share;
          assigned += share;
        }
      }
    } else {
      var assigned = 0;
      for (var i = 0; i < candidates.length; i++) {
        final c = candidates[i];
        if (i == candidates.length - 1) {
          actualVotes[c.id] = total - assigned;
        } else {
          final share = total * (raw[c.id] ?? 0) ~/ sumRaw;
          actualVotes[c.id] = share;
          assigned += share;
        }
      }
    }

    // 3) 棄権者の重み（支持変動の平均）
    final effectiveVoters = (voters == null || voters.isEmpty)
        ? SupportSimulationService.buildDefaultVoters()
        : voters;
    final weights = <String, double>{};
    for (final c in candidates) {
      if (effectiveVoters.isEmpty) {
        weights[c.id] = 0.0;
        continue;
      }
      var sum = 0.0;
      for (final voter in effectiveVoters) {
        sum += OpinionService.computeSupportChange(
            voter, c, society, election);
      }
      weights[c.id] = sum / effectiveVoters.length;
    }

    final totalWeight = weights.values.fold<double>(0, (a, b) => a + b);

    // 4) 按分（floor して残差を重み降順・同率 candidate.id 昇順で加算）
    final addition = <String, int>{};
    for (final c in candidates) {
      addition[c.id] = 0;
    }
    if (abstentionCount > 0) {
      if (totalWeight <= 0) {
        // 均等割り
        var assigned = 0;
        for (var i = 0; i < candidates.length; i++) {
          final c = candidates[i];
          if (i == candidates.length - 1) {
            addition[c.id] = abstentionCount - assigned;
          } else {
            final share = abstentionCount ~/ candidates.length;
            addition[c.id] = share;
            assigned += share;
          }
        }
      } else {
        var floorSum = 0;
        for (final c in candidates) {
          final share = (abstentionCount * weights[c.id]! / totalWeight)
              .floor();
          addition[c.id] = share;
          floorSum += share;
        }
        var rem = abstentionCount - floorSum;
        // 重み降順・同率 candidate.id 昇順
        final order = candidates.toList()
          ..sort((a, b) {
            final cmp = weights[b.id]!.compareTo(weights[a.id]!);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });
        var idx = 0;
        while (rem > 0) {
          addition[order[idx % order.length].id] =
              addition[order[idx % order.length].id]! + 1;
          rem--;
          idx++;
        }
      }
    }

    // 5) 反実仮想の票
    final counterfactualVotes = <String, int>{};
    for (final c in candidates) {
      counterfactualVotes[c.id] = actualVotes[c.id]! + addition[c.id]!;
    }

    // 6) 当選者（最大票・同率は candidate.id 昇順）
    String? resolveName(String? id) {
      if (id == null) return null;
      for (final c in candidates) {
        if (c.id == id) return c.name;
      }
      return null;
    }

    final counterfactualWinnerId = _maxVotesWinner(counterfactualVotes, candidates);
    // 実際の当選者は election.winnerId で確定済み
    final actualWinnerId = election.winnerId;

    return TurnoutCounterfactual(
      actualWinnerId: actualWinnerId,
      actualWinnerName: resolveName(actualWinnerId),
      counterfactualWinnerId: counterfactualWinnerId,
      counterfactualWinnerName: resolveName(counterfactualWinnerId),
      actualVotes: actualVotes,
      counterfactualVotes: counterfactualVotes,
      abstentionCount: abstentionCount,
    );
  }

  /// 投票マップから当選者IDを解決（同率は candidate.id 昇順で先）
  static String? _maxVotesWinner(
      Map<String, int> votes, List<Candidate> candidates) {
    String? bestId;
    int? bestVotes;
    for (final c in candidates) {
      final id = c.id;
      final v = votes[id] ?? 0;
      if (bestVotes == null ||
          v > bestVotes ||
          (v == bestVotes && id.compareTo(bestId!) < 0)) {
        bestId = id;
        bestVotes = v;
      }
    }
    return bestId;
  }

  /// ゲーム状態からスナップショットを計算する
  ///
  /// currentElection が無ければ pastElections の最後を用いる。
  /// どちらも無ければ null。
  static TurnoutSnapshot? forGameState(
    GameState state, {
    bool playerAbstained = false,
  }) {
    final election =
        state.currentElection ?? (state.pastElections.isNotEmpty ? state.pastElections.last : null);
    if (election == null) return null;
    return compute(
      election: election,
      society: state.society,
      scale: state.scale,
      player: state.citizen,
      playerAbstained: playerAbstained,
    );
  }

  /// ゲーム状態から反実仮想を計算する
  ///
  /// 選挙が無い・未完了の場合は null を返す（例外を投げない）。
  static TurnoutCounterfactual? counterfactualForGameState(
    GameState state, {
    bool playerAbstained = false,
  }) {
    final election =
        state.currentElection ?? (state.pastElections.isNotEmpty ? state.pastElections.last : null);
    if (election == null) return null;
    final turnout = forGameState(state, playerAbstained: playerAbstained);
    if (turnout == null) return null;
    if (election.voteCounts == null || election.winnerId == null) {
      return null;
    }
    try {
      return counterfactual(
        election: election,
        turnout: turnout,
        society: state.society,
      );
    } on ArgumentError {
      return null;
    }
  }
}
