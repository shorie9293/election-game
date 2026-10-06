import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/backup/domain/game_data_backup.dart';

void main() {
  group('GameDataBackupService.build', () {
    test('正しい schema_version / app_id / exported_at を持つJSONを生成する', () {
      const service = GameDataBackupService();
      final at = DateTime(2026, 10, 6, 12, 34, 56);
      final json = service.build(
        {'election_archive': 'data'},
        exportedAt: at,
      );
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      expect(decoded['schema_version'], kBackupSchemaVersion);
      expect(decoded['app_id'], kBackupAppId);
      expect(decoded['exported_at'], at.toIso8601String());
      expect((decoded['data'] as Map)['election_archive'], 'data');
    });

    test('exportedAt 省略時は現在時刻近傍を使う', () {
      const service = GameDataBackupService();
      final before = DateTime.now();
      final json = service.build({});
      final after = DateTime.now();
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final at = DateTime.parse(decoded['exported_at'] as String);
      expect(
        at.isAfter(before.subtract(const Duration(seconds: 1))) && at.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });

  group('GameDataBackupService.parse', () {
    const service = GameDataBackupService();

    test('build の往復で値を保持する（多型値 bool/int/double/String/List<String>）', () {
      final data = <String, Object?>{
        'election_quiz_best_correct': 7,
        'election_game_sound_volume': 0.5,
        'election_game_theme_mode': 'dark',
        'election_game_sound_bgm_enabled': true,
        'candidate_rating_a1': ['俳優', '政治家'],
      };
      final raw = service.build(data, exportedAt: DateTime(2026, 1, 2, 3, 4));
      final result = service.parse(raw);
      expect(result.isSuccess, isTrue);
      final backup = result.backup!;
      expect(backup.schemaVersion, kBackupSchemaVersion);
      expect(backup.appId, kBackupAppId);
      expect(backup.exportedAt, DateTime(2026, 1, 2, 3, 4));
      expect(backup.data['election_quiz_best_correct'], 7);
      expect(backup.data['election_game_sound_volume'], 0.5);
      expect(backup.data['election_game_theme_mode'], 'dark');
      expect(backup.data['election_game_sound_bgm_enabled'], true);
      expect(backup.data['candidate_rating_a1'], ['俳優', '政治家']);
    });

    test('空文字列は「バックアップデータが空です」', () {
      final result = service.parse('   ');
      expect(result.hasError, isTrue);
      expect(result.error, 'バックアップデータが空です');
    });

    test('JSON不正は「バックアップデータを読み取れません（JSON形式が不正です）」', () {
      final result = service.parse('{not json');
      expect(result.error, 'バックアップデータを読み取れません（JSON形式が不正です）');
    });

    test('非Mapトップレベルは「バックアップデータの形式が不正です」', () {
      final result = service.parse('[1,2,3]');
      expect(result.error, 'バックアップデータの形式が不正です');
    });

    test('version型不正は「バックアップ形式のバージョンが不正です」', () {
      final result = service.parse(
        jsonEncode({'schema_version': '1', 'app_id': kBackupAppId, 'data': {}}),
      );
      expect(result.error, 'バックアップ形式のバージョンが不正です');
    });

    test('未対応versionは「未対応のバックアップ形式です」', () {
      final result = service.parse(jsonEncode({
        'schema_version': kBackupSchemaVersion + 1,
        'app_id': kBackupAppId,
        'data': {},
        'exported_at': DateTime.now().toIso8601String(),
      }));
      expect(result.error, '未対応のバックアップ形式です');
    });

    test('app_id不一致は「このアプリのバックアップではありません」', () {
      final result = service.parse(jsonEncode({
        'schema_version': kBackupSchemaVersion,
        'app_id': 'other_app',
        'data': {},
        'exported_at': DateTime.now().toIso8601String(),
      }));
      expect(result.error, 'このアプリのバックアップではありません');
    });

    test('data不正は「バックアップデータの中身が不正です」', () {
      final result = service.parse(jsonEncode({
        'schema_version': kBackupSchemaVersion,
        'app_id': kBackupAppId,
        'data': 'not-a-map',
        'exported_at': DateTime.now().toIso8601String(),
      }));
      expect(result.error, 'バックアップデータの中身が不正です');
    });

    test('exported_at不正は「バックアップの作成日時が不正です」', () {
      final result = service.parse(jsonEncode({
        'schema_version': kBackupSchemaVersion,
        'app_id': kBackupAppId,
        'data': {},
        'exported_at': 'not-a-date',
      }));
      expect(result.error, 'バックアップの作成日時が不正です');
    });
  });

  group('BackupKeySpec', () {
    test('exact キーの matches は完全一致のみ', () {
      const spec = BackupKeySpec.exact(
          'election_archive', BackupCategory.archive, '選挙アーカイブ');
      expect(spec.matches('election_archive'), isTrue);
      expect(spec.matches('election_archive_x'), isFalse);
    });

    test('prefix キーの matches は前方一致', () {
      const spec =
          BackupKeySpec.prefix('candidate_rating_', BackupCategory.rating, '候補者評価');
      expect(spec.matches('candidate_rating_a1'), isTrue);
      expect(spec.matches('candidate_rating_'), isTrue);
      expect(spec.matches('x_candidate_rating_'), isFalse);
    });

    test('categoryFor は候補者評価prefixを rating に判定する', () {
      expect(BackupKeySpec.categoryFor('candidate_rating_abc'),
          BackupCategory.rating);
    });

    test('未知名は other / labelFor はキー自身', () {
      expect(BackupKeySpec.categoryFor('unknown_key'), BackupCategory.other);
      expect(BackupKeySpec.labelFor('unknown_key'), 'unknown_key');
    });

    test('all は12件（固定）', () {
      expect(BackupKeySpec.all.length, 12);
    });
  });

  group('BackupEntry / GameDataBackup', () {
    test('toJson / fromJson の往復', () {
      const entry = BackupEntry('election_archive', 'x');
      final restored = BackupEntry.fromJson(entry.toJson());
      expect(restored, entry);
    });

    test('BackupEntry の等価性（List値の要素比較を含む）', () {
      const a = BackupEntry('k', ['a', 'b']);
      const b = BackupEntry('k', ['a', 'b']);
      const c = BackupEntry('k', ['a', 'c']);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });

    test('categoryCounts は全 enum キーを持ち合計が entryCount に一致', () {
      final backup = GameDataBackup(
        schemaVersion: kBackupSchemaVersion,
        appId: kBackupAppId,
        exportedAt: DateTime(2026),
        data: {
          'election_archive': 'a',
          'election_quiz_attempts': 2,
          'candidate_rating_x': 'y',
          'unknown_key': 'z',
        },
      );
      final counts = backup.categoryCounts;
      for (final c in BackupCategory.values) {
        expect(counts.containsKey(c), isTrue);
      }
      final total = counts.values.fold<int>(0, (a, b) => a + b);
      expect(total, backup.entryCount);
      expect(counts[BackupCategory.other], 1);
    });

    test('exportedAtLabel は yyyy-MM-dd HH:mm 書式', () {
      final backup = GameDataBackup(
        schemaVersion: 1,
        appId: kBackupAppId,
        exportedAt: DateTime(2026, 3, 4, 7, 8),
        data: {},
      );
      expect(backup.exportedAtLabel, '2026-03-04 07:08');
    });

    test('GameDataBackup の toJson / fromJson 往復', () {
      final backup = GameDataBackup(
        schemaVersion: 1,
        appId: kBackupAppId,
        exportedAt: DateTime(2026, 2, 2, 2, 2),
        data: {'election_archive': 'a', 'n': null},
      );
      final restored = GameDataBackup.fromJson(backup.toJson());
      expect(restored.schemaVersion, backup.schemaVersion);
      expect(restored.appId, backup.appId);
      expect(restored.exportedAt, backup.exportedAt);
      expect(restored.data, backup.data);
    });
  });
}
