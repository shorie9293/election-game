import '../../../domain/models/candidate.dart';
import '../../../domain/models/election.dart';
import 'election_prediction.dart';

/// 予想と実際の結果を評価する純粋サービス（staticのみ・インスタンス化不可）。
class PredictionService {
  PredictionService._();

  /// 指定候補の得票率（%）。total==0 なら 0。
  static int actualShare(Election election, String candidateId) {
    final voteCounts = election.voteCounts;
    if (voteCounts == null) {
      throw ArgumentError('voteCounts must not be null');
    }
    final total =
        voteCounts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) return 0;
    return ((voteCounts[candidateId] ?? 0) * 100 / total).round();
  }

  /// 得票数降順の候補者IDリスト（同数は宣言順を保つ安定ソート）。
  ///
  /// Dart の `List.sort` は非安定ゆえ、同数を宣言順で確定させるため
  /// 元の index をタイブレークに用いる（親探針で非安定性を実証済み）。
  static List<String> ranking(Election election) {
    final voteCounts = election.voteCounts;
    if (voteCounts == null) {
      throw ArgumentError('voteCounts must not be null');
    }
    final indexed = election.candidates.asMap().entries.toList()
      ..sort((a, b) {
        final byCount = (voteCounts[b.value.id] ?? 0)
            .compareTo(voteCounts[a.value.id] ?? 0);
        if (byCount != 0) return byCount;
        return a.key.compareTo(b.key);
      });
    return indexed.map((entry) => entry.value.id).toList();
  }

  /// 予想と実際の結果を突き合わせて評価する。
  static PredictionOutcome evaluate(
    ElectionPrediction prediction,
    Election election,
  ) {
    if (!election.completed) {
      throw ArgumentError('election must be completed');
    }
    final knownIds = election.candidates.map((Candidate c) => c.id).toSet();
    if (!knownIds.contains(prediction.predictedWinnerId)) {
      throw ArgumentError(
        'predictedWinnerId is not a candidate: ${prediction.predictedWinnerId}',
      );
    }
    final winnerId = election.winnerId!;
    final share = actualShare(election, winnerId);
    return PredictionOutcome(
      prediction: prediction,
      actualWinnerId: winnerId,
      actualShare: share,
      actualRanking: ranking(election),
    );
  }
}