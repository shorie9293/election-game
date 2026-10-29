import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_restorer.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_sharer.dart';
import 'package:election_game/features/auto_backup/presentation/auto_backup_screen.dart';

class _FakeRestorer implements AutoBackupRestorer {
  int calls = 0;
  String? lastFileName;
  bool throws = false;
  AutoBackupRestoreResult result = const AutoBackupRestoreResult(
    ok: true,
    message: '復元しました',
    safetyFileName: 'auto_backup_20261030.json',
  );

  @override
  Future<AutoBackupRestoreResult> restore(String fileName) async {
    calls++;
    lastFileName = fileName;
    if (throws) throw StateError('復元失敗');
    return result;
  }
}

class _FakeSharer implements AutoBackupSharer {
  int calls = 0;
  String? lastFileName;
  String? lastJson;
  bool throws = false;

  @override
  Future<void> share(String fileName, String json) async {
    calls++;
    lastFileName = fileName;
    lastJson = json;
    if (throws) throw StateError('共有失敗');
  }
}

const _valid = '{"schema_version":1}';
const _broken = '{broken';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Future<InMemoryAutoBackupStore> _storeWith(WidgetTester tester) async {
  final store = InMemoryAutoBackupStore(
    clock: () => DateTime(2026, 10, 29, 7, 12),
  );
  await store.write('auto_backup_20261027.json', _valid);
  store.createdAt['auto_backup_20261027.json'] = DateTime(2026, 10, 27, 7, 12);
  await store.write('auto_backup_20261029.json', _valid);
  store.createdAt['auto_backup_20261029.json'] = DateTime(2026, 10, 29, 7, 12);
  await store.write('auto_backup_20261028.json', _broken);
  store.createdAt['auto_backup_20261028.json'] = DateTime(2026, 10, 28, 7, 12);
  return store;
}

void main() {
  group('AutoBackupScreen', () {
    testWidgets('0件なら空状態を出す', (tester) async {
      await _pump(
        tester,
        AutoBackupScreen(store: InMemoryAutoBackupStore()),
      );

      expect(find.text('バックアップはまだありません'), findsOneWidget);
      expect(find.byKey(AppKeys.autoBackupEmptyLabel), findsOneWidget);
    });

    testWidgets('新しい順に並び、世代番号と日時・サイズが出る', (tester) async {
      final store = await _storeWith(tester);
      await _pump(tester, AutoBackupScreen(store: store));

      final newest = tester.getTopLeft(
        find.byKey(AppKeys.autoBackupRow('auto_backup_20261029.json')),
      );
      final middle = tester.getTopLeft(
        find.byKey(AppKeys.autoBackupRow('auto_backup_20261028.json')),
      );
      final oldest = tester.getTopLeft(
        find.byKey(AppKeys.autoBackupRow('auto_backup_20261027.json')),
      );

      expect(newest.dy, lessThan(middle.dy));
      expect(middle.dy, lessThan(oldest.dy));

      expect(
        find.text('2026-10-29 07:12 / 20 B / 第1世代'),
        findsOneWidget,
      );
      expect(
        find.text('2026-10-27 07:12 / 20 B / 第3世代'),
        findsOneWidget,
      );
    });

    testWidgets('保持世代数のラベルを出す', (tester) async {
      final store = await _storeWith(tester);
      await _pump(tester, AutoBackupScreen(store: store));

      expect(
        find.text('保持 3世代中 3件'),
        findsOneWidget,
      );
    });

    testWidgets('壊れた JSON の行には復元ボタンを出さない', (tester) async {
      final store = await _storeWith(tester);
      final restorer = _FakeRestorer();
      await _pump(
        tester,
        AutoBackupScreen(store: store, restorer: restorer),
      );

      expect(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261028.json')),
        findsNothing,
      );
      expect(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261029.json')),
        findsOneWidget,
      );
    });

    testWidgets('復元は確認ダイアログで OK した時だけ呼ばれる', (tester) async {
      final store = await _storeWith(tester);
      final restorer = _FakeRestorer();
      await _pump(
        tester,
        AutoBackupScreen(store: store, restorer: restorer),
      );

      await tester.tap(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261029.json')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(restorer.calls, 0);

      await tester.tap(find.byKey(AppKeys.autoBackupRestoreConfirmButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(restorer.calls, 1);
      expect(restorer.lastFileName, 'auto_backup_20261029.json');
      expect(find.text('復元しました'), findsOneWidget); // SnackBar
    });

    testWidgets('確認ダイアログをキャンセルすると復元しない', (tester) async {
      final store = await _storeWith(tester);
      final restorer = _FakeRestorer();
      await _pump(
        tester,
        AutoBackupScreen(store: store, restorer: restorer),
      );

      await tester.tap(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261029.json')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(AppKeys.autoBackupRestoreCancelButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AlertDialog), findsNothing);
      expect(restorer.calls, 0);
    });

    testWidgets('復元失敗のメッセージを SnackBar に出し、例外を外へ出さない', (tester) async {
      final store = await _storeWith(tester);
      final restorer = _FakeRestorer()
        ..result = const AutoBackupRestoreResult(
          ok: false,
          message: '復元できませんでした',
        );
      await _pump(
        tester,
        AutoBackupScreen(store: store, restorer: restorer),
      );

      await tester.tap(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261029.json')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(AppKeys.autoBackupRestoreConfirmButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('復元できませんでした'), findsOneWidget);
    });

    testWidgets('共有は sharer 注入時のみ表示され、内容が渡る', (tester) async {
      final store = await _storeWith(tester);
      final sharer = _FakeSharer();
      await _pump(
        tester,
        AutoBackupScreen(store: store, sharer: sharer),
      );

      final button =
          find.byKey(AppKeys.autoBackupShareButton('auto_backup_20261029.json'));
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(sharer.calls, 1);
      expect(sharer.lastFileName, 'auto_backup_20261029.json');
      expect(sharer.lastJson, _valid);
    });

    testWidgets('restorer/sharer 未注入なら復元・共有ボタンを一切出さない', (tester) async {
      final store = await _storeWith(tester);
      await _pump(tester, AutoBackupScreen(store: store));

      expect(find.byIcon(Icons.restore), findsNothing);
      expect(find.byIcon(Icons.share), findsNothing);
      expect(
        find.byKey(AppKeys.autoBackupRestoreButton('auto_backup_20261029.json')),
        findsNothing,
      );
      expect(
        find.byKey(AppKeys.autoBackupShareButton('auto_backup_20261029.json')),
        findsNothing,
      );
    });

    testWidgets('onBackupNow 注入時のみ「今すぐバックアップ」が出て呼ばれる', (tester) async {
      final store = await _storeWith(tester);
      var calls = 0;
      await _pump(
        tester,
        AutoBackupScreen(store: store, onBackupNow: () async => calls++),
      );

      final button = find.byKey(AppKeys.autoBackupBackupNowButton);
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
    });

    testWidgets('onBackupNow の例外を握る', (tester) async {
      final store = await _storeWith(tester);
      await _pump(
        tester,
        AutoBackupScreen(
          store: store,
          onBackupNow: () async => throw StateError('失敗'),
        ),
      );

      await tester.tap(find.byKey(AppKeys.autoBackupBackupNowButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(AutoBackupScreen), findsOneWidget);
    });
  });
}
