import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/data/auto_backup_store.dart';

void main() {
  group('InMemoryAutoBackupStore', () {
    test('write/list/delete が往復する', () async {
      final store = InMemoryAutoBackupStore(
        clock: () => DateTime(2026, 8, 20),
      );
      await store.write('auto_backup_20260820.json', '{"a":1}');

      final listed = await store.list();
      expect(listed, hasLength(1));
      expect(listed.single.fileName, 'auto_backup_20260820.json');
      expect(listed.single.createdAt, DateTime(2026, 8, 20));
      expect(store.contents['auto_backup_20260820.json'], '{"a":1}');

      await store.delete('auto_backup_20260820.json');
      expect(await store.list(), isEmpty);
    });

    test('存在しないファイルの削除は失敗しない', () async {
      final store = InMemoryAutoBackupStore();
      await store.delete('auto_backup_20260101.json');
      expect(store.contents, isEmpty);
    });
  });

  group('FileAutoBackupStore', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('auto_backup_store_test');
    });

    tearDown(() async {
      if (await root.exists()) {
        await root.delete(recursive: true);
      }
    });

    test('documents/auto_backups 配下へ書き出し、一覧できる', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      await store.write('auto_backup_20260820.json', '{"ok":true}');

      final file =
          File('${root.path}/auto_backups/auto_backup_20260820.json');
      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), '{"ok":true}');

      final listed = await store.list();
      expect(listed.map((e) => e.fileName), ['auto_backup_20260820.json']);
      expect(
        listed.single.createdAt.difference(DateTime.now()).inMinutes.abs(),
        lessThanOrEqualTo(5),
      );
    });

    test('自動バックアップ以外のファイルは一覧に含めない', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      await store.write('auto_backup_20260820.json', '{}');
      final dir = Directory('${root.path}/auto_backups');
      await File('${dir.path}/manual_backup.json').writeAsString('{}');
      await File('${dir.path}/notes.txt').writeAsString('memo');

      final listed = await store.list();
      expect(listed.map((e) => e.fileName), ['auto_backup_20260820.json']);
    });

    test('delete は対象ファイルのみ消す', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      await store.write('auto_backup_20260819.json', '{}');
      await store.write('auto_backup_20260820.json', '{}');

      await store.delete('auto_backup_20260819.json');

      final listed = await store.list();
      expect(listed.map((e) => e.fileName), ['auto_backup_20260820.json']);
    });

    test('ディレクトリ未作成でも一覧は空を返す', () async {
      final store = FileAutoBackupStore(directoryResolver: () async => root);
      expect(await store.list(), isEmpty);
    });
  });
}
