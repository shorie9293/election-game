import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';
import 'package:election_game/features/auto_backup/domain/auto_backup_presenter.dart';

AutoBackupEntry _entry(String name, DateTime at) =>
    AutoBackupEntry(fileName: name, createdAt: at);

void main() {
  group('AutoBackupPresenter.formatDate', () {
    test('ローカル暦を yyyy-MM-dd HH:mm でゼロ埋めする', () {
      expect(
        AutoBackupPresenter.formatDate(DateTime(2026, 10, 29, 7, 12)),
        '2026-10-29 07:12',
      );
      expect(
        AutoBackupPresenter.formatDate(DateTime(2026, 1, 2, 0, 5)),
        '2026-01-02 00:05',
      );
    });

    test('UTC の DateTime でも暦のフィールドをそのまま使う（JST赤化しない）', () {
      expect(
        AutoBackupPresenter.formatDate(DateTime(2026, 10, 29, 23, 59)),
        '2026-10-29 23:59',
      );
    });
  });

  group('AutoBackupPresenter.formatSize', () {
    test('1024 未満は B 表記', () {
      expect(AutoBackupPresenter.formatSize(0), '0 B');
      expect(AutoBackupPresenter.formatSize(1), '1 B');
      expect(AutoBackupPresenter.formatSize(512), '512 B');
      expect(AutoBackupPresenter.formatSize(1023), '1023 B');
    });

    test('1024 以上は KB・小数1桁', () {
      expect(AutoBackupPresenter.formatSize(1024), '1.0 KB');
      expect(AutoBackupPresenter.formatSize(12698), '12.4 KB');
    });

    test('1024^2 以上は MB・小数1桁', () {
      expect(AutoBackupPresenter.formatSize(1024 * 1024), '1.0 MB');
      expect(AutoBackupPresenter.formatSize(1258291), '1.2 MB');
    });

    test('負値は 0 B に丸める（例外を投げない）', () {
      expect(AutoBackupPresenter.formatSize(-5), '0 B');
    });
  });

  group('AutoBackupPresenter.canRestore', () {
    test('null・空・空白のみは false', () {
      expect(AutoBackupPresenter.canRestore(null), isFalse);
      expect(AutoBackupPresenter.canRestore(''), isFalse);
      expect(AutoBackupPresenter.canRestore('   '), isFalse);
    });

    test('JSON として不正なら false（例外を投げない）', () {
      expect(AutoBackupPresenter.canRestore('{invalid'), isFalse);
      expect(AutoBackupPresenter.canRestore('not json at all'), isFalse);
      expect(AutoBackupPresenter.canRestore('{"a":'), isFalse);
    });

    test('トップが Map 以外なら false', () {
      expect(AutoBackupPresenter.canRestore('[]'), isFalse);
      expect(AutoBackupPresenter.canRestore('"text"'), isFalse);
      expect(AutoBackupPresenter.canRestore('123'), isFalse);
      expect(AutoBackupPresenter.canRestore('null'), isFalse);
    });

    test('トップが Map なら true', () {
      expect(AutoBackupPresenter.canRestore('{}'), isTrue);
      expect(
        AutoBackupPresenter.canRestore(
          '{"schema_version":1,"app_id":"election_game","data":{}}',
        ),
        isTrue,
      );
    });
  });

  group('AutoBackupPresenter.sortNewestFirst', () {
    test('createdAt 降順・同時刻は fileName 降順', () {
      final sorted = AutoBackupPresenter.sortNewestFirst([
        _entry('auto_backup_20260818.json', DateTime(2026, 8, 18)),
        _entry('auto_backup_20260820.json', DateTime(2026, 8, 20)),
        _entry('auto_backup_20260819.json', DateTime(2026, 8, 19)),
        _entry('auto_backup_20260819b.json', DateTime(2026, 8, 19)),
      ]);

      expect(
        sorted.map((e) => e.fileName).toList(),
        [
          'auto_backup_20260820.json',
          'auto_backup_20260819b.json',
          'auto_backup_20260819.json',
          'auto_backup_20260818.json',
        ],
      );
    });

    test('空リストでも例外を投げない', () {
      expect(AutoBackupPresenter.sortNewestFirst(const []), isEmpty);
    });
  });

  group('AutoBackupPresenter.buildRows', () {
    final newest = _entry('auto_backup_20261029.json', DateTime(2026, 10, 29, 7, 12));
    final older = _entry('auto_backup_20261028.json', DateTime(2026, 10, 28, 7, 12));
    final manual = _entry('manual_backup.json', DateTime(2026, 10, 30, 7, 12));

    test('自動ファイルのみを新しい順に並べ、世代は1始まり', () {
      const presenter = AutoBackupPresenter();
      final rows = presenter.buildRows(
        entries: [older, manual, newest],
        contents: {
          newest.fileName: '{"a":1}',
          older.fileName: '{"b":2}',
          manual.fileName: '{"c":3}',
        },
      );

      expect(rows.map((r) => r.entry.fileName).toList(),
          [newest.fileName, older.fileName]);
      expect(rows.map((r) => r.generation).toList(), [1, 2]);
      expect(rows.first.displayLabel, '2026-10-29 07:12 / 7 B / 第1世代');
      expect(rows.last.displayLabel, '2026-10-28 07:12 / 7 B / 第2世代');
    });

    test('byteSize は UTF-8 のバイト長', () {
      const presenter = AutoBackupPresenter();
      final rows = presenter.buildRows(
        entries: [newest],
        contents: {newest.fileName: '{"選挙":1}'},
      );

      // { " 選 挙 " : 1 } = 1+1+3+3+1+1+1+1 = 12 bytes
      expect(rows.single.byteSize, 12);
      expect(rows.single.sizeLabel, '12 B');
    });

    test('内容が無い（null）なら byteSize 0・restorable false', () {
      const presenter = AutoBackupPresenter();
      final rows = presenter.buildRows(
        entries: [newest],
        contents: {newest.fileName: null},
      );

      expect(rows.single.byteSize, 0);
      expect(rows.single.sizeLabel, '0 B');
      expect(rows.single.restorable, isFalse);
      expect(rows.single.dateLabel, '2026-10-29 07:12');
    });

    test('壊れた JSON は restorable false でも行としては並ぶ', () {
      const presenter = AutoBackupPresenter();
      final rows = presenter.buildRows(
        entries: [newest],
        contents: {newest.fileName: '{broken'},
      );

      expect(rows, hasLength(1));
      expect(rows.single.restorable, isFalse);
      expect(rows.single.byteSize, 7);
    });

    test('contents に無いキーでも例外を投げない', () {
      const presenter = AutoBackupPresenter();
      final rows = presenter.buildRows(entries: [newest], contents: const {});
      expect(rows.single.byteSize, 0);
      expect(rows.single.restorable, isFalse);
    });
  });

  group('AutoBackupPresenter.retentionLabel', () {
    test('keep と件数を日本語で示す', () {
      expect(
        const AutoBackupPresenter().retentionLabel(2),
        '保持 3世代中 2件',
      );
      expect(
        const AutoBackupPresenter(keep: 5).retentionLabel(0),
        '保持 5世代中 0件',
      );
    });
  });
}
