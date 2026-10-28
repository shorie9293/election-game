import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/data/auto_backup_bootstrap.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_service.dart';

class _ThrowingListStore implements AutoBackupStore {
  @override
  Future<List<AutoBackupEntry>> list() async => throw StateError('list失敗');

  @override
  Future<void> write(String fileName, String contents) async {}

  @override
  Future<void> delete(String fileName) async {}
}

void main() {
  final now = DateTime(2026, 8, 20, 9, 30);

  group('AutoBackupService.run', () {
    test('初回起動でバックアップを書き出す', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      final service = AutoBackupService(store: store, clock: () => now);

      final result = await service.run(() async => '{"data":"x"}');

      expect(result.ran, isTrue);
      expect(result.error, isNull);
      expect(result.fileName, 'auto_backup_20260820.json');
      expect(store.contents['auto_backup_20260820.json'], '{"data":"x"}');
    });

    test('24時間以内の再起動では何もしない（同日冪等）', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      await store.write('auto_backup_20260820.json', '{}');
      store.createdAt['auto_backup_20260820.json'] =
          now.subtract(const Duration(hours: 1));
      final service = AutoBackupService(store: store, clock: () => now);

      var built = 0;
      final result = await service.run(() async {
        built++;
        return '{}';
      });

      expect(result.ran, isFalse);
      expect(built, 0);
      expect(store.contents, hasLength(1));
    });

    test('4世代目で最古の自動バックアップを削除する（3世代ローテーション）', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      for (var day = 17; day <= 19; day++) {
        await store.write('auto_backup_202608$day.json', '{}');
        store.createdAt['auto_backup_202608$day.json'] = DateTime(2026, 8, day);
      }
      final service = AutoBackupService(store: store, clock: () => now);

      final result = await service.run(() async => '{}');

      expect(result.ran, isTrue);
      expect(result.pruned, 1);
      expect(store.contents.keys.toSet(), {
        'auto_backup_20260818.json',
        'auto_backup_20260819.json',
        'auto_backup_20260820.json',
      });
    });

    test('buildJsonの例外を握り、ファイルを書かない', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      final service = AutoBackupService(store: store, clock: () => now);

      final result = await service.run(() async => throw StateError('収集失敗'));

      expect(result.ran, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('収集失敗'));
      expect(store.contents, isEmpty);
    });

    test('store.listの例外も握ってerrorに載せる', () async {
      final service = AutoBackupService(
        store: _ThrowingListStore(),
        clock: () => now,
      );

      final result = await service.run(() async => '{}');

      expect(result.ran, isFalse);
      expect(result.hasError, isTrue);
      expect(result.error, contains('list失敗'));
    });
  });

  group('scheduleAutoBackup', () {
    test('投げっぱなしでバックアップを起動し、例外を外へ出さない', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      final done = Completer<void>();

      scheduleAutoBackup(
        store: store,
        clock: () => now,
        buildJson: () async {
          if (!done.isCompleted) done.complete();
          return '{"boot":true}';
        },
      );

      await done.future.timeout(const Duration(seconds: 5));
      for (var i = 0; i < 100 && store.contents.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(store.contents['auto_backup_20260820.json'], '{"boot":true}');
    });

    test('buildJsonが失敗しても呼び出し元へ例外を投げない', () async {
      final store = InMemoryAutoBackupStore(clock: () => now);
      final attempted = Completer<void>();

      expect(
        () => scheduleAutoBackup(
          store: store,
          clock: () => now,
          buildJson: () async {
            if (!attempted.isCompleted) attempted.complete();
            throw StateError('起動時失敗');
          },
        ),
        returnsNormally,
      );
      await attempted.future.timeout(const Duration(seconds: 5));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(store.contents, isEmpty);
    });
  });
}
