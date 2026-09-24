/// 音設定（BGM / 効果音 / 音量）
class SoundSettings {
  const SoundSettings({
    this.bgmEnabled = true,
    this.sfxEnabled = true,
    this.volume = defaultVolume,
  });

  static const double defaultVolume = 0.7;

  /// BGM 再生の可否
  final bool bgmEnabled;

  /// 効果音再生の可否
  final bool sfxEnabled;

  /// 音量（0.0..1.0）
  final double volume;

  /// 既定の音設定
  static const SoundSettings defaults = SoundSettings();

  /// 音量の刻み値（UI で段階選択する用）
  static const List<double> volumeSteps = <double>[0.0, 0.2, 0.4, 0.6, 0.8, 1.0];

  /// volume を 0.0..1.0 に正規化する。
  /// null / NaN / Infinity は既定値へフォールバック、それ以外は clamp。
  static double normalizeVolume(double? value) {
    if (value == null || value.isNaN || value.isInfinite) {
      return defaultVolume;
    }
    return value.clamp(0.0, 1.0).toDouble();
  }

  /// BGM と効果音が両方オフか
  bool get isSilent => !bgmEnabled && !sfxEnabled;

  /// 音量の表示ラベル（例: '70%'）
  String get volumeLabel => '${(volume * 100).round()}%';

  /// 設定画面の要約ラベル
  String get summaryLabel {
    if (isSilent) return '消音（すべてオフ）';
    return 'BGM ${bgmEnabled ? 'オン' : 'オフ'} / '
        '効果音 ${sfxEnabled ? 'オン' : 'オフ'} / '
        '音量 $volumeLabel';
  }

  /// SharedPreferences 保存キー: BGM 可否
  static const String bgmStorageKey = 'election_game_sound_bgm_enabled';

  /// SharedPreferences 保存キー: 効果音可否
  static const String sfxStorageKey = 'election_game_sound_sfx_enabled';

  /// SharedPreferences 保存キー: 音量
  static const String volumeStorageKey = 'election_game_sound_volume';

  /// 保存値から復元する。null / 不正値は既定値へフォールバック。
  static SoundSettings fromStorage({
    bool? bgmEnabled,
    bool? sfxEnabled,
    double? volume,
  }) {
    return SoundSettings(
      bgmEnabled: bgmEnabled ?? defaults.bgmEnabled,
      sfxEnabled: sfxEnabled ?? defaults.sfxEnabled,
      volume: normalizeVolume(volume),
    );
  }

  /// 部分更新したコピーを返す
  SoundSettings copyWith({
    bool? bgmEnabled,
    bool? sfxEnabled,
    double? volume,
  }) {
    return SoundSettings(
      bgmEnabled: bgmEnabled ?? this.bgmEnabled,
      sfxEnabled: sfxEnabled ?? this.sfxEnabled,
      volume: volume ?? this.volume,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SoundSettings &&
        other.bgmEnabled == bgmEnabled &&
        other.sfxEnabled == sfxEnabled &&
        other.volume == volume;
  }

  @override
  int get hashCode => Object.hash(bgmEnabled, sfxEnabled, volume);

  @override
  String toString() =>
      'SoundSettings(bgm: $bgmEnabled, sfx: $sfxEnabled, volume: $volume)';
}
