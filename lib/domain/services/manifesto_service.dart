import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/manifesto.dart';

/// 公約（マニフェスト）実現度トラッカーの純粋ドメインサービス。
/// すべてstatic・純粋関数・入力を破壊しない。
class ManifestoService {
  ManifestoService._();

  /// 当選者の公約を生活パラメータkey単位に分解し、実現度を評価する。
  ///
  /// - key順序: LifeParamKeys.all のうち totals に存在するもの（この宣言順）、
  ///   続いて totals にあって LifeParamKeys.all に無いkeyを昇順。
  /// - promisedDelta: winner.totalEffects の該当key（全公約の合算）。
  /// - actualDelta: after - before（欠損keyは0扱い）。
  /// - policyTitles: そのkeyに触れた公約タイトル（重複除去・宣言順）。
  static List<ManifestoPledge> pledgesFor(
    Candidate winner,
    Map<String, int> before,
    Map<String, int> after,
  ) {
    final totals = winner.totalEffects;
    final titlesByKey = <String, List<String>>{};
    for (final policy in winner.policies) {
      for (final key in policy.effects.keys) {
        final titles = titlesByKey.putIfAbsent(key, () => <String>[]);
        if (!titles.contains(policy.title)) {
          titles.add(policy.title);
        }
      }
    }

    final keys = <String>[
      ...LifeParamKeys.all.where(totals.containsKey),
      ...totals.keys.where((k) => !LifeParamKeys.all.contains(k)).toList()
        ..sort(),
    ];

    return [
      for (final key in keys)
        ManifestoPledge(
          lifeParamKey: key,
          promisedDelta: totals[key] ?? 0,
          actualDelta: (after[key] ?? 0) - (before[key] ?? 0),
          policyTitles: List<String>.unmodifiable(titlesByKey[key] ?? const <String>[]),
        ),
    ];
  }

  /// 当選者の公約実現度を1選挙分の ManifestoRecord として評価する。
  static ManifestoRecord evaluate({
    required String electionId,
    required String title,
    required Candidate winner,
    required Map<String, int> before,
    required Map<String, int> after,
    DateTime? occurredAt,
  }) {
    final pledges = pledgesFor(winner, before, after);
    return ManifestoRecord(
      electionId: electionId,
      title: title,
      winnerId: winner.id,
      winnerName: winner.name,
      occurredAt: occurredAt,
      pledges: pledges,
    );
  }

  /// 完了済み選挙から ManifestoRecord を組み立てる。
  /// 未完了・当選者不在なら null。
  static ManifestoRecord? fromResult({
    required Election result,
    required Map<String, int> before,
    required Map<String, int> after,
  }) {
    if (!result.completed) return null;
    Candidate? winner;
    for (final candidate in result.candidates) {
      if (candidate.id == result.winnerId) {
        winner = candidate;
        break;
      }
    }
    if (winner == null) return null;
    return evaluate(
      electionId: result.id,
      title: result.title,
      winner: winner,
      before: before,
      after: after,
    );
  }

  /// occurredAt 降順でソートする（非破壊）。
  /// null は末尾。同時刻（null同士含む）は electionId 昇順でタイブレーク。
  static List<ManifestoRecord> sortByDateDesc(List<ManifestoRecord> records) {
    int compare(ManifestoRecord a, ManifestoRecord b) {
      final aAt = a.occurredAt;
      final bAt = b.occurredAt;
      if (aAt == null && bAt == null) {
        return a.electionId.compareTo(b.electionId);
      }
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      final byDate = bAt.compareTo(aAt);
      if (byDate != 0) return byDate;
      return a.electionId.compareTo(b.electionId);
    }

    final sorted = [...records]..sort(compare);
    return sorted;
  }

  /// winnerName / title の部分一致検索（正規化比較・順序保持）。
  static List<ManifestoRecord> search(
    List<ManifestoRecord> records,
    String query,
  ) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return List<ManifestoRecord>.unmodifiable(records);
    return [
      for (final record in records)
        if (_normalize(record.winnerName).contains(normalized) ||
            _normalize(record.title).contains(normalized))
          record,
    ];
  }

  /// 全レコードの fulfilledCount 合計。
  static int fulfilledTotal(List<ManifestoRecord> records) =>
      records.fold(0, (sum, record) => sum + record.fulfilledCount);

  /// 全角英数→半角・全角スペース→半角・小文字化・trim。
  static String _normalize(String value) {
    var normalized = value;
    final buffer = StringBuffer();
    for (final codeUnit in normalized.runes) {
      // 全角英数（U+FF01..U+FF5E）→半角ASCII（U+0021..U+007E）
      if (codeUnit >= 0xFF01 && codeUnit <= 0xFF5E) {
        buffer.writeCharCode(codeUnit - 0xFEE0);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    normalized = buffer.toString().replaceAll('　', ' ');
    return normalized.toLowerCase().trim();
  }
}
