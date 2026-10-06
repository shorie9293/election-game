import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/backup/presentation/game_data_backup_screen.dart';

/// 親探針（合成の不変条件）:
/// 子の試練は「画面単体」「リポジトリ単体」しか撃たない。
/// ここでは画面Aでエクスポート → 別画面Bで復元 → データが一致する合成を撃つ。
void main() {
  const service = GameDataBackupService();
  final now = DateTime(2026, 10, 6, 22, 30);

  DateTime fixedNow() => now;

  Future<void> pumpScreen(
    WidgetTester tester, {
    required GameDataBackupRepository repository,
    String? importText,
    void Function(String)? onCopy,
    Key? screenKey,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    // 同一widget型を連続pumpするとStateが再利用されinitStateが走らない
    // （探針側の既知pitfall）→ 毎回異なる key を与えて State を新規化する
    await tester.pumpWidget(
      MaterialApp(
        home: GameDataBackupScreen(
          key: screenKey,
          repository: repository,
          now: fixedNow,
          copyToClipboard: (t) async => onCopy?.call(t),
          initialImportText: importText,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('親探針: データ所有権の合成不変条件', () {
    testWidgets('画面Aでエクスポート→画面Bで復元→データが一致する（機種変更の合成）',
        (tester) async {
      final original = <String, Object?>{
        'election_archive': '[{"id":"election_1"}]',
        'candidate_rating_c1': '{"candidateId":"c1","score":4}',
        'election_quiz_best_correct': 7,
        'election_game_tutorial_completed': true,
      };
      final repoA = InMemoryGameDataBackupRepository(original);

      // 画面A: エクスポート → JSON を捕捉
      String? exported;
      await pumpScreen(tester,
          repository: repoA, onCopy: (t) => exported = t, screenKey: const ValueKey('screen-a'));
      await tester.tap(find.byKey(AppKeys.backupExportButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.backupCopyButton));
      await tester.pumpAndSettle();
      expect(exported, isNotNull, reason: 'export→copy で JSON が得られない');

      // 画面B: 空のリポジトリへ JSON を貼り付けて復元
      final repoB = InMemoryGameDataBackupRepository();
      await pumpScreen(tester, repository: repoB, importText: exported, screenKey: const ValueKey('screen-b'));
      await tester.tap(find.byKey(AppKeys.backupRestoreButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.backupRestoreConfirmButton));
      await tester.pumpAndSettle();

      // 合成: 画面Aの実データ = 画面Bの復元後データ（順序に依らず一致）
      expect(repoB.store.keys.toSet(), original.keys.toSet());
      for (final k in original.keys) {
        expect(repoB.store[k], original[k], reason: 'キー $k の値が完全一致しない');
      }
    });

    testWidgets('復元は管理外キーを破壊しない（clearExisting は管理対象のみ）',
        (tester) async {
      // SharedPreferences 実装での意味論を固定する親探針
      SharedPreferences.setMockInitialValues({
        'election_archive': '[]',
        'unmanaged_keep_me': '生存',
      });
      const repo = SharedPreferencesGameDataBackupRepository();
      await repo.restore({'election_quiz_best_correct': 9},
          clearExisting: true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('unmanaged_keep_me'), '生存',
          reason: '復元が管理外キーを巻き込んで破壊した');
      expect(prefs.getInt('election_quiz_best_correct'), 9);
      expect(prefs.getString('election_archive'), isNull,
          reason: 'clearExisting で既存の管理キーが消えていない');
    });

    testWidgets('InMemory と SharedPreferences の clearExisting は同一意味論（管理外を保持）',
        (tester) async {
      final mem = InMemoryGameDataBackupRepository({
        'election_archive': '[]',
        'unmanaged_keep_me': '生存',
      });
      await mem.restore({'election_quiz_best_correct': 9},
          clearExisting: true);
      expect(mem.store['unmanaged_keep_me'], '生存',
          reason: 'InMemory 実装が SharedPreferences 実装と意味論一致しない');
      expect(mem.store.containsKey('election_archive'), isFalse);
      expect(mem.store['election_quiz_best_correct'], 9);
    });

    testWidgets('不正JSONで復元するとリポジトリは一切変化しない（部分適用なし）',
        (tester) async {
      final repo = InMemoryGameDataBackupRepository({
        'election_archive': '[]',
      });
      await pumpScreen(tester, repository: repo, importText: '{壊れた');
      await tester.tap(find.byKey(AppKeys.backupRestoreButton));
      await tester.pumpAndSettle();

      expect(find.byKey(AppKeys.backupErrorLabel), findsOneWidget);
      expect(repo.store['election_archive'], '[]',
          reason: '不正入力でリポジトリが破壊された');
    });

    testWidgets('エクスポートは now() を exportedAt に反映し parse で往復可能',
        (tester) async {
      final repo =
          InMemoryGameDataBackupRepository({'election_archive': '[1]'});
      String? exported;
      await pumpScreen(tester, repository: repo, onCopy: (t) => exported = t);
      await tester.tap(find.byKey(AppKeys.backupExportButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.backupCopyButton));
      await tester.pumpAndSettle();

      final result = service.parse(exported!);
      expect(result.isSuccess, isTrue);
      expect(result.backup!.exportedAt, now);
      expect(result.backup!.data['election_archive'], '[1]');
    });
  });
}
