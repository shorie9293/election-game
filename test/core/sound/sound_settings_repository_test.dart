import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/core/sound/sound_settings.dart';
import 'package:election_game/core/sound/sound_settings_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundSettingsRepository', () {
    const repository = SoundSettingsRepository();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('未保存時は defaults を返す', () async {
      final settings = await repository.load();
      expect(settings, SoundSettings.defaults);
    });

    test('保存後に load で復元できる', () async {
      const saved = SoundSettings(
        bgmEnabled: false,
        sfxEnabled: false,
        volume: 0.4,
      );
      await repository.save(saved);
      expect(await repository.load(), saved);
    });

    test('既定値を保存後も復元できる', () async {
      await repository.save(SoundSettings.defaults);
      expect(await repository.load(), SoundSettings.defaults);
    });

    test('保存値が3キー個別に書き込まれている', () async {
      await repository.save(
        const SoundSettings(bgmEnabled: false, sfxEnabled: true, volume: 0.2),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SoundSettings.bgmStorageKey), isFalse);
      expect(prefs.getBool(SoundSettings.sfxStorageKey), isTrue);
      expect(prefs.getDouble(SoundSettings.volumeStorageKey), 0.2);
    });

    test('volume が文字列で保存されていても例外なく既定値へフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.volumeStorageKey: 'not-a-number',
      });
      final settings = await repository.load();
      expect(settings.volume, SoundSettings.defaultVolume);
    });

    test('bgm が文字列で保存されていても例外なく既定値へフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.bgmStorageKey: 'unknown-bool',
      });
      final settings = await repository.load();
      expect(settings.bgmEnabled, isTrue);
    });

    test('sfx が文字列で保存されていても例外なく既定値へフォールバックする', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.sfxStorageKey: 'unknown-bool',
      });
      final settings = await repository.load();
      expect(settings.sfxEnabled, isTrue);
    });

    test('volume が範囲外でも clamp されて復元される', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.volumeStorageKey: 99.0,
      });
      final settings = await repository.load();
      expect(settings.volume, 1.0);
    });

    test('bgm のみ部分保存でも例外なく復元できる', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.bgmStorageKey: false,
      });
      final settings = await repository.load();
      expect(settings.bgmEnabled, isFalse);
      expect(settings.sfxEnabled, isTrue);
      expect(settings.volume, SoundSettings.defaultVolume);
    });

    test('volume のみ部分保存でも例外なく復元できる', () async {
      SharedPreferences.setMockInitialValues({
        SoundSettings.volumeStorageKey: 0.1,
      });
      final settings = await repository.load();
      expect(settings.bgmEnabled, isTrue);
      expect(settings.sfxEnabled, isTrue);
      expect(settings.volume, 0.1);
    });
  });
}
