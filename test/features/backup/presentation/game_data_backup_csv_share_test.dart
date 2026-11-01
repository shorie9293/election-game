import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/data/election_csv_sharer.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';

class _FakeSharer implements ElectionCsvSharer {
  String? csv;
  String? fileName;
  int calls = 0;

  @override
  Future<void> share({required String csv, required String fileName}) async {
    calls++;
    this.csv = csv;
    this.fileName = fileName;
  }
}

Election _sampleElection() {
  return const Election(
    id: 'election_1',
    title: '天照町 町長選挙',
    scale: ElectionScale.town,
    candidates: [
      Candidate(
        id: 'c1',
        name: '山田太郎',
        portraitKey: 'p1',
        faction: '発展の会',
        personality: 'test',
        policies: [],
      ),
    ],
    voteCounts: {'c1': 10},
    winnerId: 'c1',
  );
}

void main() {
  const service = GameDataBackupService();

  Future<void> pumpScreen(
    WidgetTester tester, {
    ElectionCsvSharer? sharer,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: GameDataBackupScreen(
          repository: InMemoryGameDataBackupRepository({'election_archive': '[]'}),
          service: service,
          now: () => DateTime(2026, 11, 1, 9),
          copyToClipboard: (_) async {},
          archiveRepository:
              InMemoryElectionArchiveRepository([_sampleElection()]),
          csvSharer: sharer,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sharer 未注入なら CSV共有ボタンは表示されない', (tester) async {
    await pumpScreen(tester);
    expect(find.byKey(AppKeys.backupShareCsvButton), findsNothing);
    // 既存ボタンは温存
    expect(find.byKey(AppKeys.backupExportButton), findsOneWidget);
    expect(find.byKey(AppKeys.backupCopyButton), findsOneWidget);
  });

  testWidgets('CSV共有: タップで fileName が .csv 終端・csv に BOM 無し', (tester) async {
    final fake = _FakeSharer();
    await pumpScreen(tester, sharer: fake);

    await tester.tap(find.byKey(AppKeys.backupShareCsvButton));
    await tester.pumpAndSettle();

    expect(fake.calls, 1);
    expect(fake.fileName, 'election_results_20261101.csv');
    expect(fake.fileName!.endsWith('.csv'), isTrue);
    expect(fake.csv, isNotNull);
    expect(fake.csv!.contains('\uFEFF'), isFalse);
    expect(fake.csv, contains('山田太郎'));
    expect(fake.csv, contains('発展の会'));
    expect(find.byKey(AppKeys.backupStatusLabel), findsOneWidget);
  });
}
