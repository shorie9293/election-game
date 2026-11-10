import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/backup/domain/game_data_backup.dart';
import 'package:election_game/features/backup/domain/restore_preview.dart';

void main() {
  const service = GameDataBackupService();

  group('RestorePreview.build の内訳', () {
    test('新規のみなら上書きされない旨を出し、サンプルは無い', () {
      final preview = RestorePreview.build(
        {'election_game_theme_mode': 'dark', 'candidate_rating_c1': '{}'},
        const {},
      );

      expect(preview.created, 2);
      expect(preview.overwritten, 0);
      expect(preview.unchanged, 0);
      expect(preview.summary, '新規 2件 / 上書き 0件 / 変更なし 0件');
      expect(preview.message, contains('既存データは上書きされません'));
      expect(preview.overwriteSampleKeys, isEmpty);
      expect(preview.hiddenOverwriteCount, 0);
      expect(preview.samplesText, isNull);
    });

    test('上書きのみなら上書きされる旨とキーを昇順で出す', () {
      final preview = RestorePreview.build(
        {
          'election_game_theme_mode': 'light',
          'election_archive': '[]',
        },
        {
          'election_game_theme_mode': 'dark',
          'election_archive': '[]',
        },
      );

      expect(preview.created, 0);
      expect(preview.overwritten, 1);
      expect(preview.unchanged, 1);
      expect(preview.summary, '新規 0件 / 上書き 1件 / 変更なし 1件');
      expect(preview.message, contains('既存データが上書きされます'));
      expect(preview.overwriteSampleKeys, ['election_game_theme_mode']);
      expect(preview.samplesText, contains('election_game_theme_mode'));
      expect(preview.samplesText, isNot(contains('ほか')));
    });

    test('全件 unchanged なら「変更はありません」と言い切る', () {
      final preview = RestorePreview.build(
        {'a': 1, 'b': 'x'},
        {'a': 1, 'b': 'x'},
      );

      expect(preview.created, 0);
      expect(preview.overwritten, 0);
      expect(preview.unchanged, 2);
      expect(preview.summary, '新規 0件 / 上書き 0件 / 変更なし 2件');
      expect(preview.message, contains('変更はありません'));
      expect(preview.samplesText, isNull);
    });

    test('混在時は上書きキーの先頭5件＋ほか N件 を出す', () {
      final overwrite = <String, Object?>{
        for (var i = 1; i <= 8; i++) 'candidate_rating_c$i': 'new$i',
      };
      final existing = <String, Object?>{
        for (var i = 1; i <= 8; i++) 'candidate_rating_c$i': 'old$i',
      };
      final preview = RestorePreview.build(
        {...overwrite, 'election_game_sound_volume': 0.5},
        {...existing, 'election_archive': '[]'},
      );

      expect(preview.created, 1);
      expect(preview.overwritten, 8);
      expect(preview.unchanged, 0);
      expect(preview.overwriteSampleKeys.length, 5);
      expect(preview.overwriteSampleKeys.first, 'candidate_rating_c1');
      expect(preview.overwriteSampleKeys.last, 'candidate_rating_c5');
      expect(preview.hiddenOverwriteCount, 3);
      expect(preview.samplesText, contains('ほか 3件'));
    });

    test('JSON由来の List<dynamic> と 端末保存の List<String> を同一視する', () {
      final decoded = service.parse(
        service.build({'election_archive': ['e1', 'e2']}),
      ).backup!;

      final preview = compose(
        backup: decoded,
        existing: {
          'election_archive': <String>['e1', 'e2'],
        },
      );

      expect(preview.overwritten, 0);
      expect(preview.unchanged, 1);
      expect(preview.hasChanges, isFalse);
    });
  });

  group('RestorePreview は壊れた入力で例外を投げない', () {
    test('空同士は0件で「復元対象のデータはありません」', () {
      final preview = RestorePreview.build(const {}, const {});

      expect(preview.total, 0);
      expect(preview.hasChanges, isFalse);
      expect(preview.message, '復元対象のデータはありません');
      expect(preview.samplesText, isNull);
    });

    test('sampleLimit が 0 以下でも例外を投げず抜粋なしになる', () {
      final preview = RestorePreview.build(
        {'a': 1, 'b': 2},
        {'a': 2, 'b': 3},
        sampleLimit: 0,
      );

      expect(preview.overwritten, 2);
      expect(preview.overwriteSampleKeys, isEmpty);
      expect(preview.hiddenOverwriteCount, 2);
      expect(preview.samplesText, isNull);
    });

    test('壊れた JSON・空文字・null は null を返す（例外なし）', () {
      expect(
        composeFromJson('{broken', existing: const {}),
        isNull,
      );
      expect(composeFromJson('', existing: const {}), isNull);
      expect(composeFromJson('   ', existing: const {}), isNull);
      expect(composeFromJson(null, existing: const {}), isNull);
      expect(composeFromJson('[1,2,3]', existing: const {}), isNull);
      expect(
        composeFromJson(
          '{"schema_version":1,"app_id":"other_app","exported_at":"x","data":{}}',
          existing: const {},
        ),
        isNull,
      );
    });

    test('巨大入力（2000キー）でも例外を投げず件数を数える', () {
      final incoming = <String, Object?>{
        for (var i = 0; i < 2000; i++) 'candidate_rating_c$i': 'v$i',
      };
      final existing = <String, Object?>{
        for (var i = 0; i < 2000; i++) 'candidate_rating_c$i': 'v$i',
      };

      final preview = RestorePreview.build(incoming, existing);

      expect(preview.total, 2000);
      expect(preview.unchanged, 2000);
      expect(preview.overwritten, 0);
    });

    test('深すぎる入れ子リストでも例外を投げない', () {
      Object? deep(int n) => n == 0 ? 'leaf' : [deep(n - 1)];

      final preview = RestorePreview.build(
        {'election_archive': deep(200)},
        {'election_archive': deep(200)},
      );

      // 上限段数より深い比較は「上書き」に倒れる（無変更と誤認しない）
      expect(preview.overwritten, 1);
      expect(preview.unchanged, 0);
    });
  });
}
