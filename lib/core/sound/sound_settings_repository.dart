import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/sound/sound_settings.dart';

/// 音設定のリポジトリ
///
/// SharedPreferences に BGM / 効果音 / 音量の 3 キーを個別に保存・復元する。
/// 型不正や範囲外の保存値があっても例外を投げず既定値へフォールバックする。
class SoundSettingsRepository {
  const SoundSettingsRepository();

  /// 保存された音設定を読み込む。未保存/不正値は既定値へフォールバック。
  Future<SoundSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      return SoundSettings.fromStorage(
        bgmEnabled: prefs.getBool(SoundSettings.bgmStorageKey),
        sfxEnabled: prefs.getBool(SoundSettings.sfxStorageKey),
        volume: prefs.getDouble(SoundSettings.volumeStorageKey),
      );
    } on TypeError {
      return SoundSettings.defaults;
    }
  }

  /// 音設定を保存する（3 キー個別）。
  Future<void> save(SoundSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SoundSettings.bgmStorageKey, settings.bgmEnabled);
    await prefs.setBool(SoundSettings.sfxStorageKey, settings.sfxEnabled);
    await prefs.setDouble(SoundSettings.volumeStorageKey, settings.volume);
  }
}
