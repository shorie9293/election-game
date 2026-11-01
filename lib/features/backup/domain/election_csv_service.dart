import 'dart:convert';

import 'package:election_game/domain/models/election.dart';

/// 選挙結果CSVのヘッダ行（BOMなし）。
const electionResultsCsvHeader =
    '選挙ID,選挙名,規模,候補者名,政党,得票数,得票率(%),当選';

/// 選挙結果を RFC4180 準拠のCSV文字列へ変換する純粋サービス。
///
/// 列は実測モデルにのみ基づく:
/// - `Election.id` / `title` / `scale.displayName` / `voteCounts` / `winnerId`
/// - `Candidate.id` / `name` / `faction`（政党）
class ElectionCsvService {
  const ElectionCsvService();

  /// 選挙結果をCSVへ変換する。戻り値に BOM は含めない（ファイル化層で付与）。
  String exportResultsCsv(List<Election> elections) {
    final buffer = StringBuffer('$electionResultsCsvHeader\r\n');
    for (final election in elections) {
      final counts = election.voteCounts ?? const <String, int>{};
      final totalVotes = counts.values.fold<int>(0, (sum, v) => sum + v);
      for (final candidate in election.candidates) {
        final votes = counts[candidate.id] ?? 0;
        final share = totalVotes <= 0
            ? '0.0'
            : (votes * 100 / totalVotes).toStringAsFixed(1);
        buffer.write(_row([
          election.id,
          election.title,
          election.scale.displayName,
          candidate.name,
          candidate.faction,
          '$votes',
          share,
          election.winnerId == candidate.id ? '当選' : '',
        ]));
      }
    }
    return buffer.toString();
  }

  static String _row(List<String> cells) =>
      '${cells.map(_escape).join(',')}\r\n';

  /// RFC4180: `,` `"` 改行を含む値は `"` で囲み、内側の `"` は `""` にする。
  static String _escape(String value) {
    final needsQuote = value.contains(',') ||
        value.contains('"') ||
        value.contains('\r') ||
        value.contains('\n');
    if (!needsQuote) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}

/// CSV文字列の先頭に UTF-8 BOM (U+FEFF) を1個だけ付与する。
String withUtf8Bom(String csv) => '\uFEFF$csv';

/// BOM付きUTF-8バイト列を返す（先頭3バイトは 0xEF 0xBB 0xBF）。
///
/// `codeUnits` は使わない（日本語が壊れる）。必ず [utf8.encode] を通す。
List<int> csvBytes(String csv) => utf8.encode(withUtf8Bom(csv));

/// 共有ファイル名 `election_results_<yyyyMMdd>.csv` を生成する。
String electionCsvFileName(DateTime now) {
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return 'election_results_$y$m$d.csv';
}
