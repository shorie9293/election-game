import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';

void main() {
  const service = GameDataBackupService();
  DateTime fixedNow() => DateTime(2026, 10, 6, 22, 0);

  String jsonOf(Map<String, Object?> data) =>
      service.build(data, exportedAt: fixedNow());

  Future<InMemoryGameDataBackupRepository> pumpScreen(
    WidgetTester tester, {
    required Map<String, Object?> initial,
    required String importText,
    Size size = const Size(1080, 2400),
  }) async {
    final repo = InMemoryGameDataBackupRepository(initial);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: GameDataBackupScreen(
          repository: repo,
          service: service,
          now: fixedNow,
          copyToClipboard: (text) async {},
          initialImportText: importText,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(AppKeys.backupRestoreButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.backupRestoreButton));
    await tester.pumpAndSettle();
    return repo;
  }

  testWidgets('復元確認に内訳（件数＋先頭サンプル）が出る', (tester) async {
    await pumpScreen(
      tester,
      initial: {
        'election_archive': '[]',
        'election_game_theme_mode': 'dark',
      },
      importText: jsonOf({
        'election_archive': '[]',
        'election_game_theme_mode': 'light',
        'candidate_rating_c1': '{}',
        'candidate_rating_c2': '{}',
      }),
    );

    // 既存の文言・ボタンは不変
    expect(find.text('データの復元'), findsOneWidget);
    expect(
      find.text('4件のデータを復元します。現在のデータは上書きされます。よろしいですか？'),
      findsOneWidget,
    );
    expect(find.byKey(AppKeys.backupRestoreConfirmButton), findsOneWidget);

    // 内訳と抜粋
    expect(
      find.byKey(AppKeys.backupRestorePreviewSummary),
      findsOneWidget,
    );
    expect(find.text('新規 2件 / 上書き 1件 / 変更なし 1件'), findsOneWidget);
    expect(find.text('新規データの追加と、既存データの上書きが行われます'), findsOneWidget);
    expect(find.byKey(AppKeys.backupRestorePreviewSamples), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(AppKeys.backupRestorePreviewSamples))
          .data,
      contains('election_game_theme_mode'),
    );
  });

  testWidgets('壊れた JSON では従来表示のまま（プレビュー非表示・例外なし）', (tester) async {
    await pumpScreen(
      tester,
      initial: {'election_archive': '[]'},
      importText: '{broken',
    );

    expect(find.byKey(AppKeys.backupErrorLabel), findsOneWidget);
    expect(find.byKey(AppKeys.backupRestorePreviewSummary), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('空バックアップ（0件）でも内訳は出ず例外も出ない', (tester) async {
    await pumpScreen(
      tester,
      initial: {'election_archive': '[]'},
      importText: jsonOf(const {}),
    );

    expect(find.text('0件のデータを復元します。現在のデータは上書きされます。よろしいですか？'),
        findsOneWidget);
    // 0件でも「復元対象のデータはありません」を内訳として出す（throwしない）
    expect(find.byKey(AppKeys.backupRestorePreviewSummary), findsOneWidget);
    expect(find.text('新規 0件 / 上書き 0件 / 変更なし 0件'), findsOneWidget);
    expect(find.byKey(AppKeys.backupRestorePreviewSamples), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('狭幅 360x640 でも溢れない', (tester) async {
    final many = <String, Object?>{};
    for (var i = 1; i <= 8; i++) {
      many['candidate_rating_c$i'] = 'new$i';
    }
    await pumpScreen(
      tester,
      initial: {
        for (var i = 1; i <= 8; i++) 'candidate_rating_c$i': 'old$i',
      },
      importText: jsonOf(many),
      size: const Size(360, 640),
    );

    expect(find.byKey(AppKeys.backupRestorePreviewSamples), findsOneWidget);
    expect(find.textContaining('ほか 3件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('復元確認すると従来どおり書き戻される', (tester) async {
    final repo = await pumpScreen(
      tester,
      initial: {'election_archive': '[]'},
      importText: jsonOf({
        'election_archive': '["e1"]',
        'candidate_rating_c1': '{}',
      }),
    );

    await tester.tap(find.byKey(AppKeys.backupRestoreConfirmButton));
    await tester.pumpAndSettle();

    expect(await repo.collect(), {
      'election_archive': '["e1"]',
      'candidate_rating_c1': '{}',
    });
    expect(find.text('復元しました'), findsOneWidget);
  });
}
