import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';

void main() {
  DateTime fixedNow() => DateTime(2026, 10, 6, 22, 0);
  const service = GameDataBackupService();

  Future<({GameDataBackupScreen screen, InMemoryGameDataBackupRepository repo,
      List<String> captured})> pumpScreen(
    WidgetTester tester, {
    Map<String, Object?>? initial,
    String? initialImportText,
  }) {
    final captured = <String>[];
    final repo = InMemoryGameDataBackupRepository(initial);
    final screen = GameDataBackupScreen(
      repository: repo,
      service: service,
      now: fixedNow,
      copyToClipboard: (text) async => captured.add(text),
      initialImportText: initialImportText,
    );
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester
        .pumpWidget(MaterialApp(home: screen))
        .then((_) => tester.pumpAndSettle())
        .then((_) => (screen: screen, repo: repo, captured: captured));
  }

  testWidgets('初期表示: 現在のデータ件数とカテゴリ行が表示される', (tester) async {
    await pumpScreen(tester, initial: {
      'election_archive': '[]',
      'candidate_rating_c1': '{}',
    });

    expect(find.byKey(AppKeys.backupEntryCountLabel), findsOneWidget);
    expect(find.text('現在のデータ: 2件'), findsOneWidget);
    expect(
      find.byKey(AppKeys.backupCategoryRow(BackupCategory.archive.name)),
      findsOneWidget,
    );
    expect(
      find.byKey(AppKeys.backupCategoryRow(BackupCategory.other.name)),
      findsOneWidget,
    );
    // エクスポート前はエクスポート出力・エラーは非表示
    expect(find.byKey(AppKeys.backupExportOutput), findsNothing);
    expect(find.byKey(AppKeys.backupErrorLabel), findsNothing);
    // コピーボタンはまだ無効
    final copyBefore = tester.widget<ElevatedButton>(
      find.byKey(AppKeys.backupCopyButton),
    );
    expect(copyBefore.onPressed, isNull);
  });

  testWidgets('エクスポート: 出力JSONに app_id と schema_version が含まれる', (tester) async {
    await pumpScreen(tester, initial: {
      'election_archive': '[]',
      'candidate_rating_c1': '{}',
    });

    await tester.tap(find.byKey(AppKeys.backupExportButton));
    await tester.pumpAndSettle();

    final output = tester.widget<SelectableText>(
      find.byKey(AppKeys.backupExportOutput),
    ).data!;
    final decoded = jsonDecode(output) as Map<String, dynamic>;
    expect(decoded['app_id'], 'election_game');
    expect(decoded['schema_version'], 1);
    expect(decoded['exported_at'], isNotNull);
    expect((decoded['data'] as Map<String, dynamic>).length, 2);
  });

  testWidgets('コピー: captured が出力と一致し status が表示される', (tester) async {
    final ctx = await pumpScreen(tester, initial: {
      'election_archive': '[]',
    });

    await tester.tap(find.byKey(AppKeys.backupExportButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.backupCopyButton));
    await tester.pumpAndSettle();

    final output = tester.widget<SelectableText>(
      find.byKey(AppKeys.backupExportOutput),
    ).data!;
    expect(ctx.captured, [output]);
    expect(find.byKey(AppKeys.backupStatusLabel), findsOneWidget);
    expect(find.text('コピーしました'), findsOneWidget);
  });

  testWidgets('不正JSONで復元すると backupErrorLabel が表示される', (tester) async {
    final ctx = await pumpScreen(tester, initial: {
      'election_archive': '[]',
    });

    await tester.enterText(
      find.byKey(AppKeys.backupImportField),
      '{ not valid json',
    );
    await tester.tap(find.byKey(AppKeys.backupRestoreButton));
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.backupErrorLabel), findsOneWidget);
    expect(find.byKey(AppKeys.backupStatusLabel), findsNothing);
    // 復元は実行されない
    expect(ctx.repo.store.length, 1);
  });

  testWidgets('正しいJSONで復元: 確認ダイアログ→確認で store が置き換わる', (tester) async {
    final ctx = await pumpScreen(tester, initial: {
      'election_archive': '[]',
      'old_setting_key': 'value',
    });

    final fresh = service.build({
      'election_quiz_best_correct': 5,
      'election_archive': '[1]',
    });
    await tester.enterText(
      find.byKey(AppKeys.backupImportField),
      fresh,
    );
    await tester.tap(find.byKey(AppKeys.backupRestoreButton));
    await tester.pumpAndSettle();

    // 確認ダイアログが表示される
    expect(find.byKey(AppKeys.backupRestoreConfirmButton), findsOneWidget);
    expect(find.text('復元する'), findsOneWidget);
    expect(find.text('やめる'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.backupRestoreConfirmButton));
    await tester.pumpAndSettle();

    // clearExisting: true なので既存の管理キーが置き換わる（管理外は保持）
    expect(
      ctx.repo.store.keys,
      containsAll(['election_quiz_best_correct', 'election_archive']),
    );
    expect(ctx.repo.store['old_setting_key'], 'value',
        reason: '管理外キーを復元が巻き込んで破壊した');
    expect(ctx.repo.store['election_quiz_best_correct'], 5);
    expect(ctx.repo.store['election_archive'], '[1]');
    expect(find.byKey(AppKeys.backupStatusLabel), findsOneWidget);
    expect(find.text('復元しました'), findsOneWidget);
    // 画面の件数表示も更新される
    expect(find.text('現在のデータ: 2件'), findsOneWidget);
  });

  testWidgets('確認ダイアログで「やめる」を押すと復元されない', (tester) async {
    final ctx = await pumpScreen(tester, initial: {
      'election_archive': '[]',
    });

    final fresh = service.build({'quiz_score': 5});
    await tester.enterText(
      find.byKey(AppKeys.backupImportField),
      fresh,
    );
    await tester.tap(find.byKey(AppKeys.backupRestoreButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('やめる'));
    await tester.pumpAndSettle();

    expect(ctx.repo.store.length, 1);
    expect(find.byKey(AppKeys.backupStatusLabel), findsNothing);
  });
}