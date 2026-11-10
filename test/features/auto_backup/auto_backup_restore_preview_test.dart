import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_restorer.dart';
import 'package:election_game/features/auto_backup/presentation/auto_backup_screen.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';

class _FakeRestorer implements AutoBackupRestorer {
  int calls = 0;

  @override
  Future<AutoBackupRestoreResult> restore(String fileName) async {
    calls++;
    return const AutoBackupRestoreResult(ok: true, message: '復元しました');
  }
}

void main() {
  const service = GameDataBackupService();
  const fileName = 'auto_backup_20261029.json';
  DateTime fixedNow() => DateTime(2026, 10, 29, 7, 12);

  String jsonOf(Map<String, Object?> data) =>
      service.build(data, exportedAt: fixedNow());

  Future<({InMemoryAutoBackupStore store, _FakeRestorer restorer})> pumpScreen(
    WidgetTester tester, {
    required Map<String, Object?> existing,
    required String contents,
    Size size = const Size(1080, 2400),
    bool withRepository = true,
  }) async {
    final store = InMemoryAutoBackupStore(clock: fixedNow);
    await store.write(fileName, contents);
    final restorer = _FakeRestorer();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: AutoBackupScreen(
          store: store,
          restorer: restorer,
          backupRepository:
              withRepository ? InMemoryGameDataBackupRepository(existing) : null,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    return (store: store, restorer: restorer);
  }

  testWidgets('世代復元の確認に内訳（件数＋先頭サンプル）が出る', (tester) async {
    final harness = await pumpScreen(
      tester,
      existing: {
        'election_archive': '[]',
        'election_game_theme_mode': 'dark',
      },
      contents: jsonOf({
        'election_archive': '[]',
        'election_game_theme_mode': 'light',
        'candidate_rating_c1': '{}',
      }),
    );

    await tester.tap(find.byKey(AppKeys.autoBackupRestoreButton(fileName)));
    await tester.pumpAndSettle();

    // 既存の文言・ボタンは不変
    expect(find.text('復元の確認'), findsOneWidget);
    expect(
      find.text('2026-10-29 07:12 のバックアップを復元します。'
          '現在のデータは復元前の自動バックアップとして退避されます。'),
      findsOneWidget,
    );
    expect(find.byKey(AppKeys.autoBackupRestoreConfirmButton), findsOneWidget);

    expect(find.byKey(AppKeys.autoBackupRestorePreviewSummary), findsOneWidget);
    expect(find.text('新規 1件 / 上書き 1件 / 変更なし 1件'), findsOneWidget);
    expect(find.text('新規データの追加と、既存データの上書きが行われます'), findsOneWidget);
    expect(find.byKey(AppKeys.autoBackupRestorePreviewSamples), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(AppKeys.autoBackupRestorePreviewSamples))
          .data,
      contains('election_game_theme_mode'),
    );

    // 復元導線は従来どおり動く
    await tester.tap(find.byKey(AppKeys.autoBackupRestoreConfirmButton));
    await tester.pumpAndSettle();
    expect(harness.restorer.calls, 1);
  });

  testWidgets('読み出し元が無い/壊れた内容ならプレビューを出さず例外も出さない', (tester) async {
    await pumpScreen(
      tester,
      existing: {'election_archive': '[]'},
      contents: jsonOf({'election_archive': '[]'}),
      withRepository: false,
    );
    await tester.tap(find.byKey(AppKeys.autoBackupRestoreButton(fileName)));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.autoBackupRestorePreviewSummary), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('壊れたバックアップでは復元ボタン自体が出ない（従来どおり）', (tester) async {
    await pumpScreen(
      tester,
      existing: {'election_archive': '[]'},
      contents: '{broken',
    );

    // restorable == false のため復元導線は出ない（既存挙動の維持）
    expect(find.byKey(AppKeys.autoBackupRestoreButton(fileName)), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('狭幅 360x640 でも溢れない', (tester) async {
    final existing = <String, Object?>{};
    final incoming = <String, Object?>{};
    for (var i = 1; i <= 8; i++) {
      existing['candidate_rating_c$i'] = 'old$i';
      incoming['candidate_rating_c$i'] = 'new$i';
    }
    await pumpScreen(
      tester,
      existing: existing,
      contents: jsonOf(incoming),
      size: const Size(360, 640),
    );

    await tester.tap(find.byKey(AppKeys.autoBackupRestoreButton(fileName)));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.autoBackupRestorePreviewSamples), findsOneWidget);
    expect(find.textContaining('ほか 3件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
