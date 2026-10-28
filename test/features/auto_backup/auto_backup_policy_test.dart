import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/auto_backup/domain/auto_backup_policy.dart';

void main() {
  const policy = AutoBackupPolicy();
  final now = DateTime(2026, 8, 20, 9, 30);

  group('AutoBackupPolicy.shouldRun', () {
    test('前回実行が無ければ実行する', () {
      expect(policy.shouldRun(lastAt: null, now: now), isTrue);
    });

    test('前回からちょうど24時間で実行する（境界）', () {
      expect(
        policy.shouldRun(lastAt: now.subtract(const Duration(hours: 24)), now: now),
        isTrue,
      );
    });

    test('24時間未満なら実行しない', () {
      expect(
        policy.shouldRun(
          lastAt: now.subtract(const Duration(hours: 23, minutes: 59)),
          now: now,
        ),
        isFalse,
      );
    });

    test('前回が未来時刻なら実行する（時計巻き戻し）', () {
      expect(
        policy.shouldRun(lastAt: now.add(const Duration(days: 1)), now: now),
        isTrue,
      );
    });

    test('同一時刻の再起動では実行しない（同日冪等）', () {
      expect(policy.shouldRun(lastAt: now, now: now), isFalse);
    });
  });

  group('AutoBackupPolicy.fileNameFor', () {
    test('ローカル暦のゼロ埋めファイル名を返す', () {
      expect(
        AutoBackupPolicy.fileNameFor(DateTime(2026, 1, 5, 23, 59)),
        'auto_backup_20260105.json',
      );
    });
  });

  group('AutoBackupPolicy.isAutoBackupFile', () {
    test('接頭辞と接尾辞が一致すれば自動バックアップ', () {
      expect(AutoBackupPolicy.isAutoBackupFile('auto_backup_20260105.json'), isTrue);
    });

    test('手動ファイル・別拡張子は自動バックアップでない', () {
      expect(AutoBackupPolicy.isAutoBackupFile('manual_backup.json'), isFalse);
      expect(AutoBackupPolicy.isAutoBackupFile('auto_backup_20260105.txt'), isFalse);
      expect(AutoBackupPolicy.isAutoBackupFile('auto_backup_.json'), isFalse);
    });
  });

  group('AutoBackupPolicy.latestCreatedAt', () {
    test('自動ファイルの最大作成時刻を返し、手動は無視する', () {
      final entries = [
        AutoBackupEntry(
          fileName: 'auto_backup_20260818.json',
          createdAt: DateTime(2026, 8, 18),
        ),
        AutoBackupEntry(
          fileName: 'auto_backup_20260819.json',
          createdAt: DateTime(2026, 8, 19),
        ),
        AutoBackupEntry(
          fileName: 'manual_backup.json',
          createdAt: DateTime(2026, 8, 25),
        ),
      ];
      expect(policy.latestCreatedAt(entries), DateTime(2026, 8, 19));
    });

    test('自動ファイルが無ければ null', () {
      expect(policy.latestCreatedAt(const []), isNull);
    });
  });

  group('AutoBackupPolicy.prune', () {
    test('createdAt降順でkeep件だけ残す', () {
      final entries = [
        for (var day = 15; day <= 20; day++)
          AutoBackupEntry(
            fileName: 'auto_backup_202608$day.json',
            createdAt: DateTime(2026, 8, day),
          ),
      ];
      final kept = policy.prune(entries);
      expect(kept.map((e) => e.fileName), [
        'auto_backup_20260820.json',
        'auto_backup_20260819.json',
        'auto_backup_20260818.json',
      ]);
    });

    test('createdAtが同値ならfileName降順で優先する', () {
      final same = DateTime(2026, 8, 20);
      final kept = policy.prune([
        AutoBackupEntry(fileName: 'auto_backup_20260101.json', createdAt: same),
        AutoBackupEntry(fileName: 'auto_backup_20260103.json', createdAt: same),
        AutoBackupEntry(fileName: 'auto_backup_20260102.json', createdAt: same),
      ]);
      expect(kept.map((e) => e.fileName), [
        'auto_backup_20260103.json',
        'auto_backup_20260102.json',
        'auto_backup_20260101.json',
      ]);
    });

    test('手動ファイルは返さない（削除対象にしない）', () {
      final kept = policy.prune([
        AutoBackupEntry(
          fileName: 'manual_backup.json',
          createdAt: DateTime(2026, 8, 25),
        ),
        AutoBackupEntry(
          fileName: 'auto_backup_20260819.json',
          createdAt: DateTime(2026, 8, 19),
        ),
      ]);
      expect(kept, hasLength(1));
      expect(kept.single.fileName, 'auto_backup_20260819.json');
    });

    test('keepが件数以上なら全件残す／keep=0なら空', () {
      final entries = [
        AutoBackupEntry(
          fileName: 'auto_backup_20260819.json',
          createdAt: DateTime(2026, 8, 19),
        ),
      ];
      expect(policy.prune(entries), hasLength(1));
      expect(const AutoBackupPolicy(keep: 0).prune(entries), isEmpty);
    });

    test('既定の保持世代は3', () {
      expect(AutoBackupPolicy.defaultKeep, 3);
      expect(policy.keep, 3);
      expect(policy.interval, const Duration(hours: 24));
    });
  });
}
