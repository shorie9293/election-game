import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';

void main() {
  group('AutoBackupStore.read（InMemory）', () {
    test('write した内容をそのまま読み戻せる', () async {
      final store = InMemoryAutoBackupStore(
        clock: () => DateTime(2026, 10, 29, 7, 12),
      );
      await store.write('auto_backup_20261029.json', '{"a":1}');

      expect(await store.read('auto_backup_20261029.json'), '{"a":1}');
    });

    test('存在しないファイルは null', () async {
      final store = InMemoryAutoBackupStore();
      expect(await store.read('auto_backup_20261029.json'), isNull);
    });

    test('delete 後は null', () async {
      final store = InMemoryAutoBackupStore();
      await store.write('auto_backup_20261029.json', '{}');
      await store.delete('auto_backup_20261029.json');
      expect(await store.read('auto_backup_20261029.json'), isNull);
    });
  });

  group('AutoBackupStore.read（File）', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('auto_backup_read_test');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('write した内容をそのまま読み戻せる', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      await store.write('auto_backup_20261029.json', '{"ok":true}');

      expect(await store.read('auto_backup_20261029.json'), '{"ok":true}');
    });

    test('存在しないファイルは null（例外を投げない）', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      expect(await store.read('auto_backup_20261029.json'), isNull);
    });
  });
}
