import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/sound/sound_settings.dart';

void main() {
  group('SoundSettings', () {
    group('既定値', () {
      test('defaults は BGM オン / 効果音 オン / 音量 0.7', () {
        const settings = SoundSettings.defaults;
        expect(settings.bgmEnabled, isTrue);
        expect(settings.sfxEnabled, isTrue);
        expect(settings.volume, 0.7);
      });

      test('コンストラクタは既定値を持つ', () {
        const settings = SoundSettings();
        expect(settings.bgmEnabled, isTrue);
        expect(settings.sfxEnabled, isTrue);
        expect(settings.volume, SoundSettings.defaultVolume);
      });

      test('defaultVolume は 0.7', () {
        expect(SoundSettings.defaultVolume, 0.7);
      });

      test('volumeSteps は 0.0..1.0 を 0.2 刻みで持つ', () {
        expect(
          SoundSettings.volumeSteps,
          <double>[0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        );
      });
    });

    group('copyWith', () {
      test('部分更新できる', () {
        const base = SoundSettings.defaults;
        final updated = base.copyWith(bgmEnabled: false);
        expect(updated.bgmEnabled, isFalse);
        expect(updated.sfxEnabled, isTrue);
        expect(updated.volume, 0.7);
      });

      test('複数フィールドを同時に更新できる', () {
        const base = SoundSettings.defaults;
        final updated = base.copyWith(
          bgmEnabled: false,
          sfxEnabled: false,
          volume: 0.5,
        );
        expect(updated.bgmEnabled, isFalse);
        expect(updated.sfxEnabled, isFalse);
        expect(updated.volume, 0.5);
      });

      test('元のインスタンスは不変', () {
        const base = SoundSettings.defaults;
        base.copyWith(bgmEnabled: false, volume: 1.0);
        expect(base.bgmEnabled, isTrue);
        expect(base.volume, 0.7);
      });
    });

    group('値等価', () {
      test('同じ値のインスタンスは等価', () {
        expect(
          const SoundSettings(bgmEnabled: false, volume: 0.4),
          const SoundSettings(bgmEnabled: false, volume: 0.4),
        );
        expect(
          const SoundSettings(bgmEnabled: false, volume: 0.4).hashCode,
          const SoundSettings(bgmEnabled: false, volume: 0.4).hashCode,
        );
      });

      test('異なる値のインスタンスは非等価', () {
        expect(
          const SoundSettings() == const SoundSettings(bgmEnabled: false),
          isFalse,
        );
        expect(
          const SoundSettings() == const SoundSettings(sfxEnabled: false),
          isFalse,
        );
        expect(
          const SoundSettings() == const SoundSettings(volume: 0.5),
          isFalse,
        );
      });

      test('defaults と fromStorage(null) は等価', () {
        expect(SoundSettings.fromStorage(), SoundSettings.defaults);
      });
    });

    group('normalizeVolume', () {
      test('null は既定値 0.7 を返す', () {
        expect(SoundSettings.normalizeVolume(null), 0.7);
      });

      test('NaN は既定値 0.7 を返す', () {
        expect(SoundSettings.normalizeVolume(double.nan), 0.7);
      });

      test('Infinity は既定値 0.7 を返す', () {
        expect(SoundSettings.normalizeVolume(double.infinity), 0.7);
        expect(SoundSettings.normalizeVolume(double.negativeInfinity), 0.7);
      });

      test('負値は 0.0 に clamp される', () {
        expect(SoundSettings.normalizeVolume(-1.0), 0.0);
        expect(SoundSettings.normalizeVolume(-0.01), 0.0);
      });

      test('1 超は 1.0 に clamp される', () {
        expect(SoundSettings.normalizeVolume(2.0), 1.0);
        expect(SoundSettings.normalizeVolume(1.01), 1.0);
      });

      test('正常値はそのまま返す', () {
        expect(SoundSettings.normalizeVolume(0.0), 0.0);
        expect(SoundSettings.normalizeVolume(1.0), 1.0);
        expect(SoundSettings.normalizeVolume(0.35), 0.35);
      });
    });

    group('isSilent', () {
      test('両方オフのとき true', () {
        expect(
          const SoundSettings(bgmEnabled: false, sfxEnabled: false).isSilent,
          isTrue,
        );
      });

      test('どちらかオンなら false', () {
        expect(
          const SoundSettings(bgmEnabled: false, sfxEnabled: true).isSilent,
          isFalse,
        );
        expect(
          const SoundSettings(bgmEnabled: true, sfxEnabled: false).isSilent,
          isFalse,
        );
      });
    });

    group('volumeLabel', () {
      test('音量を百分率ラベルで返す', () {
        expect(const SoundSettings().volumeLabel, '70%');
        expect(const SoundSettings(volume: 0.0).volumeLabel, '0%');
        expect(const SoundSettings(volume: 1.0).volumeLabel, '100%');
        expect(const SoundSettings(volume: 0.335).volumeLabel, '34%');
      });
    });

    group('summaryLabel', () {
      test('通常状態の要約ラベルを返す', () {
        expect(SoundSettings.defaults.summaryLabel,
            'BGM オン / 効果音 オン / 音量 70%');
        expect(
          const SoundSettings(bgmEnabled: false, sfxEnabled: true, volume: 0.4)
              .summaryLabel,
          'BGM オフ / 効果音 オン / 音量 40%',
        );
      });

      test('消音状態のときは消音ラベルを返す', () {
        expect(
          const SoundSettings(bgmEnabled: false, sfxEnabled: false)
              .summaryLabel,
          '消音（すべてオフ）',
        );
      });
    });

    group('storageKey', () {
      test('保存キーが定義されている', () {
        expect(SoundSettings.bgmStorageKey,
            'election_game_sound_bgm_enabled');
        expect(SoundSettings.sfxStorageKey,
            'election_game_sound_sfx_enabled');
        expect(SoundSettings.volumeStorageKey,
            'election_game_sound_volume');
      });
    });

    group('fromStorage', () {
      test('null は既定値へフォールバックする', () {
        final settings = SoundSettings.fromStorage();
        expect(settings, SoundSettings.defaults);
      });

      test('正常値を復元する', () {
        final settings = SoundSettings.fromStorage(
          bgmEnabled: false,
          sfxEnabled: false,
          volume: 0.3,
        );
        expect(settings.bgmEnabled, isFalse);
        expect(settings.sfxEnabled, isFalse);
        expect(settings.volume, 0.3);
      });

      test('volume の範囲外値は clamp される', () {
        expect(SoundSettings.fromStorage(volume: 5.0).volume, 1.0);
        expect(SoundSettings.fromStorage(volume: -5.0).volume, 0.0);
      });

      test('volume の不正値（NaN/Inf）は既定値へフォールバックする', () {
        expect(SoundSettings.fromStorage(volume: double.nan).volume, 0.7);
        expect(
          SoundSettings.fromStorage(volume: double.infinity).volume,
          0.7,
        );
      });
    });
  });
}
