import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/backup/domain/election_csv_service.dart';

const _header = '選挙ID,選挙名,規模,候補者名,政党,得票数,得票率(%),当選';

Candidate _candidate(String id, String name, String faction) {
  return Candidate(
    id: id,
    name: name,
    portraitKey: 'p_$id',
    faction: faction,
    personality: 'test',
    policies: const [],
  );
}

Election _election({
  String id = 'election_1',
  String title = '天照町 町長選挙',
  List<Candidate>? candidates,
  Map<String, int>? voteCounts,
  String? winnerId,
}) {
  final list = candidates ??
      [
        _candidate('c1', '山田太郎', '発展の会'),
        _candidate('c2', '佐藤花子', '共生の会'),
      ];
  return Election(
    id: id,
    title: title,
    scale: ElectionScale.town,
    candidates: list,
    voteCounts: voteCounts ?? {'c1': 60, 'c2': 40},
    winnerId: winnerId ?? 'c1',
  );
}

void main() {
  const service = ElectionCsvService();

  group('exportResultsCsv', () {
    test('ヘッダ行が期待通り', () {
      final csv = service.exportResultsCsv([_election()]);
      expect(csv.split('\r\n').first, _header);
    });

    test('候補者1名につき1行、得票数と得票率・当選が実測値で出力される', () {
      final csv = service.exportResultsCsv([_election()]);
      final lines = csv.split('\r\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 3);
      expect(
        lines[1],
        'election_1,天照町 町長選挙,天照町,山田太郎,発展の会,60,60.0,当選',
      );
      expect(
        lines[2],
        'election_1,天照町 町長選挙,天照町,佐藤花子,共生の会,40,40.0,',
      );
    });

    test('RFC4180: カンマと引用符を含む値は " 囲み・内側 " は "" になる', () {
      final csv = service.exportResultsCsv([
        _election(
          candidates: [_candidate('c1', 'a,"b"', '改\n新の会')],
          voteCounts: {'c1': 1},
        ),
      ]);
      expect(csv, contains('"a,""b"""'));
      expect(csv, contains('"改\n新の会"'));
    });

    test('空データはヘッダのみ・例外なし', () {
      final csv = service.exportResultsCsv(const []);
      expect(csv, '$_header\r\n');
    });

    test('戻り値に BOM (U+FEFF) を含まない', () {
      final csv = service.exportResultsCsv([_election()]);
      expect(csv.contains('\uFEFF'), isFalse);
      expect(csv.codeUnits.contains(0xFEFF), isFalse);
    });

    test('得票数が無い選挙でも 0 票・0.0% で出力される', () {
      final csv = service.exportResultsCsv([
        _election(voteCounts: const {}, winnerId: null),
      ]);
      expect(csv, contains(',0,0.0,'));
    });
  });

  group('UTF-8 BOM', () {
    test('csvBytes の先頭3バイトが 0xEF 0xBB 0xBF', () {
      final csv = service.exportResultsCsv([_election()]);
      final bytes = csvBytes(csv);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('BOM を除いた本体は utf8.decode で元に戻る', () {
      final csv = service.exportResultsCsv([_election()]);
      final bytes = csvBytes(csv);
      expect(utf8.decode(bytes.sublist(3)), csv);
    });

    test('withUtf8Bom は先頭に1個だけ BOM を付ける', () {
      const body = 'a,b\r\n';
      expect(withUtf8Bom(body), '\uFEFF$body');
      expect(withUtf8Bom(body).codeUnits.where((c) => c == 0xFEFF).length, 1);
    });
  });

  test('ファイル名は election_results_<yyyyMMdd>.csv', () {
    expect(electionCsvFileName(DateTime(2026, 11, 1)), 'election_results_20261101.csv');
    expect(electionCsvFileName(DateTime(2026, 1, 9, 23, 59)), 'election_results_20260109.csv');
  });
}
