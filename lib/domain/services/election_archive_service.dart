import '../models/candidate.dart';
import '../models/election.dart';
import '../models/election_archive.dart';
import '../models/election_scale.dart';

/// 選挙アーカイブの純粋ロジックを集めたサービス。
///
/// 副作用・I/O・現在時刻への依存は一切持たない（完全な静的メソッドのみ）。
/// docコメント内のID形式は `election_` + ミリ秒 である。
class ElectionArchiveService {
  ElectionArchiveService._();

  /// 選挙ID `election_<millis>` から発生日時を復元する。
  ///
  /// 形式が違う・数値として解析不能な場合は null。
  static DateTime? timestampFromId(String id) {
    const prefix = 'election_';
    if (!id.startsWith(prefix)) return null;
    final millisPart = id.substring(prefix.length);
    final millis = int.tryParse(millisPart);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// 完了した選挙をアーカイブエントリへ変換する。
  ///
  /// - winnerId または voteCounts が null（未完了）→ null
  /// - winnerId が候補に存在しない → null
  /// - runnerUpVotes は得票数降順→id昇順で2番目（候補1件なら0）
  static ElectionArchiveEntry? toEntry(Election election) {
    final winnerId = election.winnerId;
    final voteCounts = election.voteCounts;
    if (winnerId == null || voteCounts == null) return null;

    Candidate? winner;
    for (final c in election.candidates) {
      if (c.id == winnerId) {
        winner = c;
        break;
      }
    }
    if (winner == null) return null;

    // 2位候補の得票数: 得票数降順 → id昇順 で2番目
    final rankedIds = election.candidates
        .map((c) => c.id)
        .toList()
      ..sort((a, b) {
        final va = voteCounts[a] ?? 0;
        final vb = voteCounts[b] ?? 0;
        if (va != vb) return vb - va; // 得票数降順
        return a.compareTo(b); // id昇順
      });
    final runnerUpVotes =
        rankedIds.length >= 2 ? (voteCounts[rankedIds[1]] ?? 0) : 0;

    var totalVotes = 0;
    for (final v in voteCounts.values) {
      totalVotes += v;
    }

    return ElectionArchiveEntry(
      electionId: election.id,
      title: election.title,
      scale: election.scale,
      winnerId: winnerId,
      winnerName: winner.name,
      winnerVotes: voteCounts[winnerId] ?? 0,
      totalVotes: totalVotes,
      runnerUpVotes: runnerUpVotes,
      occurredAt: timestampFromId(election.id),
    );
  }

  /// 完了済み選挙のみをアーカイブエントリ化し、発生日時順に並べる。
  ///
  /// - occurredAt 昇順
  /// - occurredAt が null のものは常に末尾
  /// - 同時刻・null同士は electionId 昇順（安定ソート）
  static List<ElectionArchiveEntry> build(List<Election> elections) {
    final entries = <ElectionArchiveEntry>[];
    for (final e in elections) {
      final entry = toEntry(e);
      if (entry != null) entries.add(entry);
    }
    entries.sort((a, b) {
      final at = a.occurredAt;
      final bt = b.occurredAt;
      if (at == null && bt == null) {
        return a.electionId.compareTo(b.electionId);
      }
      if (at == null) return 1; // nullは末尾
      if (bt == null) return -1;
      final cmp = at.compareTo(bt);
      if (cmp != 0) return cmp;
      return a.electionId.compareTo(b.electionId);
    });
    return List.unmodifiable(entries);
  }

  /// アーカイブ全体のサマリーを計算する。
  static ElectionArchiveSummary summarize(
    List<ElectionArchiveEntry> entries,
  ) {
    if (entries.isEmpty) {
      return ElectionArchiveSummary(
        totalCount: 0,
        winnerWinCounts: const {},
        averageWinnerShare: 0.0,
        largestMarginEntry: null,
        closestElectionEntry: null,
        scaleCounts: const {},
      );
    }

    // 当選者別当選回数（回数降順 → 名前昇順のLinkedHashMap）
    final counts = <String, int>{};
    for (final e in entries) {
      counts[e.winnerName] = (counts[e.winnerName] ?? 0) + 1;
    }
    final sortedNames = counts.keys.toList()
      ..sort((a, b) {
        final ca = counts[a] ?? 0;
        final cb = counts[b] ?? 0;
        if (ca != cb) return cb - ca; // 回数降順
        return a.compareTo(b); // 名前昇順
      });
    final winnerWinCounts = <String, int>{
      for (final name in sortedNames) name: counts[name] ?? 0,
    };

    var shareSum = 0.0;
    for (final e in entries) {
      shareSum += e.winnerShare;
    }
    final averageWinnerShare = shareSum / entries.length;

    ElectionArchiveEntry? largestMarginEntry;
    ElectionArchiveEntry? closestElectionEntry;
    for (final e in entries) {
      if (largestMarginEntry == null || e.margin > largestMarginEntry.margin) {
        largestMarginEntry = e;
      }
      if (closestElectionEntry == null || e.margin < closestElectionEntry.margin) {
        closestElectionEntry = e;
      }
    }

    // スケール別件数（ElectionScale.values の宣言順を保持・0件も含める）
    final scaleCounts = <ElectionScale, int>{
      for (final scale in ElectionScale.values) scale: 0,
    };
    for (final e in entries) {
      scaleCounts[e.scale] = (scaleCounts[e.scale] ?? 0) + 1;
    }

    return ElectionArchiveSummary(
      totalCount: entries.length,
      winnerWinCounts: winnerWinCounts,
      averageWinnerShare: averageWinnerShare,
      largestMarginEntry: largestMarginEntry,
      closestElectionEntry: closestElectionEntry,
      scaleCounts: scaleCounts,
    );
  }

  /// 到達したスケールを宣言順（村→町→市）で返す。
  static List<ElectionScale> reachedScales(
    List<ElectionArchiveEntry> entries,
  ) {
    final reached = <ElectionScale>[];
    for (final scale in ElectionScale.values) {
      if (entries.any((e) => e.scale == scale)) {
        reached.add(scale);
      }
    }
    return List.unmodifiable(reached);
  }

  /// 当選得票率の時系列推移（build() と同じ順序）。
  static List<double> winnerShareTrend(List<ElectionArchiveEntry> entries) {
    return List.unmodifiable(entries.map((e) => e.winnerShare));
  }

  /// 指定スケールで絞り込む（入力順を保持）。
  static List<ElectionArchiveEntry> filterByScale(
    List<ElectionArchiveEntry> entries,
    ElectionScale scale,
  ) {
    return List.unmodifiable(
      entries.where((e) => e.scale == scale).toList(),
    );
  }

  /// タイトルで部分一致検索する（大文字小文字を無視・入力順を保持）。
  ///
  /// query が空（トリム後）なら全件を返す。
  static List<ElectionArchiveEntry> searchByTitle(
    List<ElectionArchiveEntry> entries,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(List.of(entries));
    return List.unmodifiable(
      entries.where((e) => e.title.toLowerCase().contains(q)).toList(),
    );
  }
}