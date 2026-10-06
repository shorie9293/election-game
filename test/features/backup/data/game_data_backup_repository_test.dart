import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/backup/data/game_data_backup_repository.dart';

void main() {
  group('InMemoryGameDataBackupRepository', () {
    test('collect は管理対象キーだけを返し管理外キーを除外する', () async {
      final repo = InMemoryGameDataBackupRepository({
        'election_archive': 'a',
        'candidate_rating_x1': 'rating',
        'unmanaged_key': 'skip',
      });
      final collected = await repo.collect();
      expect(collected.keys, {'election_archive', 'candidate_rating_x1'});
    });

    test('restore は data を書き込む', () async {
      final repo = InMemoryGameDataBackupRepository();
      await repo.restore({
        'election_quiz_best_correct': 5,
        'election_game_text_scale': 'large',
      });
      expect(repo.store['election_quiz_best_correct'], 5);
      expect(repo.store['election_game_text_scale'], 'large');
    });

    test('restore の clearExisting は既存管理キーを消してから書き込む（管理外は保持）', () async {
      final repo = InMemoryGameDataBackupRepository({
        'election_archive': 'old',
        'unmanaged_keep': 'kept',
      });
      await repo.restore({'election_archive': 'new'}, clearExisting: true);
      // 仕様: clearExisting は管理対象キーのみクリアする（SharedPreferences 実装と同一意味論）
      expect(repo.store['election_archive'], 'new');
      expect(repo.store['unmanaged_keep'], 'kept');
    });

    test('clear は管理キーのみ消し管理外キーを残す', () async {
      final repo = InMemoryGameDataBackupRepository({
        'election_archive': 'a',
        'candidate_rating_x': 'r',
        'my_private_key': 'keep',
      });
      await repo.clear();
      expect(repo.store.containsKey('election_archive'), isFalse);
      expect(repo.store.containsKey('candidate_rating_x'), isFalse);
      expect(repo.store['my_private_key'], 'keep');
    });
  });

  group('SharedPreferencesGameDataBackupRepository', () {
    test('collect は管理キーのみ実値を収集する', () async {
      SharedPreferences.setMockInitialValues({
        'election_archive': 'a',
        'election_quiz_best_correct': 3,
        'election_game_sound_volume': 0.8,
        'candidate_rating_u1': '司会',
        'random_key': 'ignore',
      });
      const repo = SharedPreferencesGameDataBackupRepository();
      final collected = await repo.collect();
      expect(collected['election_archive'], 'a');
      expect(collected['election_quiz_best_correct'], 3);
      expect(collected['election_game_sound_volume'], 0.8);
      expect(collected['candidate_rating_u1'], '司会');
      expect(collected.containsKey('random_key'), isFalse);
    });

    test('restore は型に応じて正しく書き込む', () async {
      SharedPreferences.setMockInitialValues({});
      const repo = SharedPreferencesGameDataBackupRepository();
      await repo.restore({
        'election_quiz_best_correct': 9,
        'election_game_sound_sfx_enabled': true,
        'election_game_theme_mode': 'light',
        'candidate_rating_u2': ['相撲取り'],
      });
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('election_quiz_best_correct'), 9);
      expect(prefs.getBool('election_game_sound_sfx_enabled'), true);
      expect(prefs.getString('election_game_theme_mode'), 'light');
      expect(prefs.getStringList('candidate_rating_u2'), ['相撲取り']);
    });

    test('restore の clearExisting は既存管理キーを消してから書き込む（管理外は保持）', () async {
      SharedPreferences.setMockInitialValues({
        'election_archive': 'old',
        'candidate_rating_old': 'old',
        'user_note': 'keep',
      });
      const repo = SharedPreferencesGameDataBackupRepository();
      await repo.restore({'election_archive': 'new'}, clearExisting: true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('election_archive'), 'new');
      expect(prefs.containsKey('candidate_rating_old'), isFalse);
      // 管理外キーは clearExisting でも巻き込んで破壊しない
      expect(prefs.getString('user_note'), 'keep');
    });

    test('clear は管理キーのみ消す', () async {
      SharedPreferences.setMockInitialValues({
        'election_archive': 'a',
        'election_quiz_attempts': 4,
        'user_note': 'keep',
      });
      const repo = SharedPreferencesGameDataBackupRepository();
      await repo.clear();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('election_archive'), isFalse);
      expect(prefs.containsKey('election_quiz_attempts'), isFalse);
      expect(prefs.getString('user_note'), 'keep');
    });
  });

  group('NoopGameDataBackupRepository', () {
    test('collect は空Mapを返し restore/clear は no-op', () async {
      const repo = NoopGameDataBackupRepository();
      expect(await repo.collect(), isEmpty);
      await repo.restore({'election_archive': 'x'});
      await repo.clear();
      expect(await repo.collect(), isEmpty);
    });
  });
}
