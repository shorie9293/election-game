import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/data/auto_backup_restorer_impl.dart';
import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/backup/data/game_data_backup_repository.dart';
import 'package:election_game/features/backup/domain/game_data_backup.dart';

const _service = GameDataBackupService();

/// 呼び出し順を記録するストア（read → write(安全) → apply の順序検証用）。
class _RecordingStore implements AutoBackupStore {
  final InMemoryAutoBackupStore inner = InMemoryAutoBackupStore();
  final List<String> log = <String>[];

  @override
  Future<List<AutoBackupEntry>> list() async {
    log.add('list');
    return inner.list();
  }

  @override
  Future<String?> read(String fileName) async {
    log.add('read:$fileName');
    return inner.read(fileName);
  }

  @override
  Future<void> write(String fileName, String contents) async {
    log.add('write:$fileName');
    await inner.write(fileName, contents);
  }

  @override
  Future<void> delete(String fileName) async {
    log.add('delete:$fileName');
    await inner.delete(fileName);
  }
}

String _backupJson({int attempts = 3}) => _service.build(
      {'election_quiz_attempts': attempts},
      exportedAt: DateTime(2026, 10, 28, 7, 12),
    );

void main() {
  final now = DateTime(2026, 10, 30, 9, 5);

  group('StoreAutoBackupRestorer', () {
    test('復元前に現状を安全バックアップへ強制保存してから適用する', () async {
      final store = _RecordingStore();
      final target = 'auto_backup_20261028.json';
      await store.write(target, _backupJson(attempts: 9));
      store.log.clear();

      final applied = <Map<String, Object?>>[];
      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => '{"current":true}',
        applyBackup: (data) async {
          store.log.add('apply');
          applied.add(data);
        },
      );

      final result = await restorer.restore(target);

      expect(result.ok, isTrue);
      expect(result.safetyFileName, 'auto_backup_20261030.json');
      expect(store.log, [
        'read:$target',
        'write:auto_backup_20261030.json',
        'apply',
      ]);
      expect(
        store.inner.contents['auto_backup_20261030.json'],
        '{"current":true}',
      );
      expect(applied.single['election_quiz_attempts'], 9);
    });

    test('安全バックアップの名前はローカル暦の now() で決まる', () async {
      final store = _RecordingStore();
      await store.write('auto_backup_20261028.json', _backupJson());

      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => DateTime(2027, 1, 2, 23, 59),
        buildCurrentJson: () async => '{}',
        applyBackup: (_) async {},
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.safetyFileName, 'auto_backup_20270102.json');
      expect(
        AutoBackupPolicy.isAutoBackupFile(result.safetyFileName!),
        isTrue,
      );
    });

    test('存在しないファイルは ok:false・書き込みも適用もしない', () async {
      final store = _RecordingStore();
      var applied = 0;
      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => '{}',
        applyBackup: (_) async => applied++,
      );

      final result = await restorer.restore('auto_backup_20260101.json');

      expect(result.ok, isFalse);
      expect(result.safetyFileName, isNull);
      expect(result.message, contains('読み'));
      expect(store.log, ['read:auto_backup_20260101.json']);
      expect(applied, 0);
    });

    test('不正 JSON は ok:false・書き込みも適用もしない', () async {
      final store = _RecordingStore();
      await store.write('auto_backup_20261028.json', '{broken');
      store.log.clear();
      var applied = 0;
      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => '{}',
        applyBackup: (_) async => applied++,
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.ok, isFalse);
      expect(result.safetyFileName, isNull);
      expect(store.log, ['read:auto_backup_20261028.json']);
      expect(applied, 0);
    });

    test('形式は JSON だがアプリのバックアップでなければ ok:false', () async {
      final store = _RecordingStore();
      await store.write(
        'auto_backup_20261028.json',
        '{"schema_version":1,"app_id":"other_app","exported_at":"2026-10-28T00:00:00Z","data":{}}',
      );
      store.log.clear();
      var applied = 0;
      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => '{}',
        applyBackup: (_) async => applied++,
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.ok, isFalse);
      expect(result.message, contains('アプリ'));
      expect(applied, 0);
    });

    test('適用時の例外を握って ok:false を返す（安全保存は済んでいる）', () async {
      final store = _RecordingStore();
      await store.write('auto_backup_20261028.json', _backupJson());
      store.log.clear();

      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => '{"current":1}',
        applyBackup: (_) async => throw StateError('書き戻し失敗'),
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.ok, isFalse);
      expect(result.message, contains('書き戻し失敗'));
      // 適用は例外で落ちたが、その前に安全保存は完了している。
      expect(store.log, [
        'read:auto_backup_20261028.json',
        'write:auto_backup_20261030.json',
      ]);
      expect(
        store.inner.contents['auto_backup_20261030.json'],
        '{"current":1}',
      );
    });

    test('buildCurrentJson の例外も握って ok:false', () async {
      final store = _RecordingStore();
      await store.write('auto_backup_20261028.json', _backupJson());

      final restorer = StoreAutoBackupRestorer(
        store: store,
        now: () => now,
        buildCurrentJson: () async => throw StateError('収集失敗'),
        applyBackup: (_) async {},
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.ok, isFalse);
      expect(result.message, contains('収集失敗'));
      expect(store.inner.contents.containsKey('auto_backup_20261030.json'),
          isFalse);
    });

    test('repository 注入時は実際にゲームデータが書き戻される', () async {
      final repository = InMemoryGameDataBackupRepository(
        {'election_quiz_attempts': 1, 'unmanaged_key': 'keep'},
      );
      final store = _RecordingStore();
      await store.write('auto_backup_20261028.json', _backupJson(attempts: 9));

      final restorer = StoreAutoBackupRestorer(
        store: store,
        repository: repository,
        now: () => now,
        buildCurrentJson: () async => '{}',
      );

      final result = await restorer.restore('auto_backup_20261028.json');

      expect(result.ok, isTrue);
      expect(repository.store['election_quiz_attempts'], 9);
      expect(repository.store['unmanaged_key'], 'keep');
      expect(store.inner.contents['auto_backup_20261030.json'], '{}');
    });
  });
}
