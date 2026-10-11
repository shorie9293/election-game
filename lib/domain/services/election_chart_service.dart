import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_chart.dart';
import 'package:election_game/domain/services/election_archive_service.dart';

/// 選挙結果グラフの構築ロジックを集めた純粋サービス。
///
/// 副作用・I/O・現在時刻・乱数への依存は一切持たない（完全な静的メソッドのみ）。
/// 選挙の並び規則は [ElectionArchiveService.build] と同一である。
class ElectionChartService {
  ElectionChartService._();

  /// occurredAt 昇順・nullは末尾・同時刻/null同士は electionId 昇順でソートする。
  ///
  /// 入力リストは破壊しない。
  static List<ElectionArchiveEntry> _sorted(List<ElectionArchiveEntry> entries) {
    final sorted = List.of(entries)
      ..sort((a, b) {
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
    return sorted;
  }

  /// グラフ用プロット点を構築する。
  ///
  /// - 選挙の並び: occurredAt 昇順・null は末尾・同時刻は electionId 昇順
  /// - label は並べ替え後の順に '第1回','第2回',... （1始まり）
  /// - 入力リストは破壊しない
  static List<ElectionChartPoint> buildPoints(
    List<ElectionArchiveEntry> entries,
  ) {
    final sorted = _sorted(entries);
    final points = <ElectionChartPoint>[];
    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      points.add(
        ElectionChartPoint(
          electionId: entry.electionId,
          label: '第${i + 1}回',
          occurredAt: entry.occurredAt,
          winnerShare: entry.winnerShare,
          totalVotes: entry.totalVotes,
          winnerName: entry.winnerName,
        ),
      );
    }
    return List.unmodifiable(points);
  }

  /// 政党（派閥）別の時系列シェア系列を構築する。
  ///
  /// - 各選挙について faction 別に voteCounts を合算し totalVotes で割る
  ///   （totalVotes<=0・voteCounts が null/空 は全 faction 0.0）
  /// - voteCounts に候補者ID以外のキーがあっても無視する
  /// - faction が空文字の候補は '無所属' として扱う
  /// - series は averageShare 降順 → faction 昇順でソートする
  /// - [maxSeries] 指定時は上位 maxSeries 件のみ返す
  static List<ElectionPartySeries> buildPartySeries(
    List<Election> elections, {
    int? maxSeries,
  }) {
    final sorted = List.of(elections)
      ..sort((a, b) {
        final at = ElectionArchiveService.timestampFromId(a.id);
        final bt = ElectionArchiveService.timestampFromId(b.id);
        if (at == null && bt == null) return a.id.compareTo(b.id);
        if (at == null) return 1; // nullは末尾
        if (bt == null) return -1;
        final cmp = at.compareTo(bt);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

    // 全 faction を収集（空文字は'無所属'）
    final factions = <String>{};
    for (final election in sorted) {
      for (final c in election.candidates) {
        factions.add(c.faction.isEmpty ? '無所属' : c.faction);
      }
    }

    // faction -> shares
    final sharesByFaction = <String, List<double>>{
      for (final f in factions) f: <double>[],
    };
    for (final election in sorted) {
      final voteCounts = election.voteCounts ?? const <String, int>{};
      var totalVotes = 0;
      final perFaction = <String, int>{};
      for (final c in election.candidates) {
        final faction = c.faction.isEmpty ? '無所属' : c.faction;
        final votes = voteCounts[c.id] ?? 0;
        perFaction[faction] = (perFaction[faction] ?? 0) + votes;
        totalVotes += votes; // 候補者ID以外のキーは無視
      }
      for (final entry in sharesByFaction.entries) {
        final votes = perFaction[entry.key] ?? 0;
        final share = totalVotes <= 0 ? 0.0 : votes / totalVotes;
        entry.value.add(share);
      }
    }

    final series = <ElectionPartySeries>[];
    for (final entry in sharesByFaction.entries) {
      final shares = entry.value;
      if (shares.isEmpty) continue;
      var sum = 0.0;
      for (final s in shares) {
        sum += s;
      }
      series.add(
        ElectionPartySeries(
          faction: entry.key,
          shares: shares,
          averageShare: sum / shares.length,
          latestShare: shares.last,
          peakShare: shares.reduce((a, b) => a > b ? a : b),
        ),
      );
    }
    series.sort((a, b) {
      final cmp = b.averageShare.compareTo(a.averageShare); // 降順
      if (cmp != 0) return cmp;
      return a.faction.compareTo(b.faction); // 昇順
    });
    final limited =
        maxSeries == null ? series : series.take(maxSeries).toList();
    return List.unmodifiable(limited);
  }

  /// グラフ用の比較サマリーを構築する。
  ///
  /// - points は [buildPoints] による
  /// - series は [elections] が空なら空リスト、そうでなければ
  ///   [buildPartySeries] の結果（[maxSeries] で件数制限）
  static ElectionComparison compare(
    List<ElectionArchiveEntry> entries, {
    List<Election> elections = const [],
    int? maxSeries,
  }) {
    final points = buildPoints(entries);
    final series = elections.isEmpty
        ? const <ElectionPartySeries>[]
        : buildPartySeries(elections, maxSeries: maxSeries);

    if (points.isEmpty) {
      return ElectionComparison(
        points: points,
        series: series,
        averageWinnerShare: 0.0,
        shareChange: 0.0,
        highestSharePoint: null,
        lowestSharePoint: null,
      );
    }

    var sum = 0.0;
    ElectionChartPoint? highest;
    ElectionChartPoint? lowest;
    for (final p in points) {
      sum += p.winnerShare;
      if (highest == null || p.winnerShare > highest.winnerShare) {
        highest = p; // 同値は先頭優先
      }
      if (lowest == null || p.winnerShare < lowest.winnerShare) {
        lowest = p; // 同値は先頭優先
      }
    }
    final shareChange = points.length >= 2
        ? points.last.winnerShare - points.first.winnerShare
        : 0.0;

    return ElectionComparison(
      points: points,
      series: series,
      averageWinnerShare: sum / points.length,
      shareChange: shareChange,
      highestSharePoint: highest,
      lowestSharePoint: lowest,
    );
  }

  /// [selectedIds] に含まれる electionId のエントリのみを元の順序で残す。
  ///
  /// [selectedIds] が空なら空リストを返す。
  static List<ElectionArchiveEntry> selectEntries(
    List<ElectionArchiveEntry> entries,
    Set<String> selectedIds,
  ) {
    if (selectedIds.isEmpty) return const <ElectionArchiveEntry>[];
    return List.unmodifiable(
      entries.where((e) => selectedIds.contains(e.electionId)).toList(),
    );
  }

  /// 小数を '12.3%' 形式のラベルへ変換する。
  static String percentLabel(double value) =>
      '${(value * 100).toStringAsFixed(1)}%';
}
