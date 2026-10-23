import 'package:election_game/domain/models/support_snapshot.dart';
import 'package:election_game/domain/models/support_timeline.dart';

/// 世論タイムラインの純粋関数サービス。
///
/// 時刻は必ず引数 `now` で注入する（内部で DateTime.now() を読まない）。
class SupportTimelineService {
  SupportTimelineService._();

  /// 既定の保持上限
  static const int defaultLimit = 200;

  /// シミュレーション結果から1エントリを生成する。
  ///
  /// 首位候補者が存在しない（snapshots が空）場合は null。
  static SupportTimelineEntry? buildEntry({
    required SupportSimulation simulation,
    required DateTime now,
    String? id,
  }) {
    if (simulation.isEmpty) return null;
    final leader = simulation.leader;
    if (leader == null) return null;

    return SupportTimelineEntry(
      id: id ?? 'support_${now.microsecondsSinceEpoch}',
      recordedAt: now,
      electionTitle: simulation.electionTitle,
      leaderCandidateId: leader.candidateId,
      leaderCandidateName: leader.candidateName,
      leaderSupportRate: leader.supportRate,
      voterCount: simulation.voterCount,
      moodLabel: simulation.moodLabel,
    );
  }

  /// recordedAt 昇順、同時刻は id 昇順で整列した新しいリストを返す。
  ///
  /// 入力リストは破壊しない。
  static List<SupportTimelineEntry> sortAscending(
    List<SupportTimelineEntry> entries,
  ) {
    final sorted = List<SupportTimelineEntry>.from(entries);
    sorted.sort((a, b) {
      final cmp = a.recordedAt.compareTo(b.recordedAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// エントリを追加する。
  ///
  /// 同一 [entry].id が既にあれば追加しない（既存を維持）。
  /// 追加後に昇順整列し、[limit] を超えたら古い順に捨てて新しい [limit] 件を残す。
  /// 入力リストは破壊しない。
  static List<SupportTimelineEntry> append(
    List<SupportTimelineEntry> entries,
    SupportTimelineEntry entry, {
    int limit = defaultLimit,
  }) {
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', '1 以上を指定');
    }

    final work = sortAscending(entries);
    if (work.any((e) => e.id == entry.id)) {
      return work;
    }
    work.add(entry);
    final sorted = sortAscending(work);
    if (sorted.length <= limit) return sorted;
    return sorted.sublist(sorted.length - limit);
  }

  /// [entryId] の直前エントリとの差分を返す。
  ///
  /// 先頭要素・未知の id・空リストでは null。
  static SupportTimelineDelta? deltaAt(
    List<SupportTimelineEntry> entries,
    String entryId,
  ) {
    final sorted = sortAscending(entries);
    final index = sorted.indexWhere((e) => e.id == entryId);
    if (index <= 0) return null;

    final current = sorted[index];
    final previous = sorted[index - 1];
    final leaderChanged =
        previous.leaderCandidateId != current.leaderCandidateId;

    return SupportTimelineDelta(
      entryId: current.id,
      previousEntryId: previous.id,
      leaderChanged: leaderChanged,
      shareDelta: current.leaderSupportRate - previous.leaderSupportRate,
      leaderChangeLabel: leaderChanged ? '首位交代' : '',
    );
  }

  /// 昇順の並びの末尾 [max] 件を昇順のまま返す。
  ///
  /// [max] が 0 以下なら空リスト。
  static List<SupportTimelineEntry> recent(
    List<SupportTimelineEntry> entries, {
    int max = 20,
  }) {
    if (max <= 0) return <SupportTimelineEntry>[];
    final sorted = sortAscending(entries);
    if (sorted.length <= max) return sorted;
    return sorted.sublist(sorted.length - max);
  }

  /// 件数に応じた推移ラベル。
  ///
  /// 0件 '記録なし' / 1件 '初回の記録' / 2件以上 '前回から [deltaLabel]'。
  static String trendLabel(List<SupportTimelineEntry> entries) {
    if (entries.isEmpty) return '記録なし';
    final sorted = sortAscending(entries);
    if (sorted.length == 1) return '初回の記録';

    final current = sorted.last;
    final previous = sorted[sorted.length - 2];
    final delta = SupportTimelineDelta(
      entryId: current.id,
      previousEntryId: previous.id,
      leaderChanged: previous.leaderCandidateId != current.leaderCandidateId,
      shareDelta: current.leaderSupportRate - previous.leaderSupportRate,
      leaderChangeLabel: '',
    );
    return '前回から ${delta.deltaLabel}';
  }
}
