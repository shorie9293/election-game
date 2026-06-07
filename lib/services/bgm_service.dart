import 'package:election_game/domain/models/election_scale.dart';

///
/// 各スケール（村・町・市）に対応するBGMトラック。
enum BgmTrack {
  /// 村スケール用：穏やかな日常BGM
  village('bgm/village.mp3', '穏やかな村'),

  /// 町スケール用：活気ある町BGM
  town('bgm/town.mp3', '活気ある町'),

  /// 市スケール用：壮大な市BGM
  city('bgm/city.mp3', '壮大な市');

  final String assetPath;
  final String displayName;

  const BgmTrack(this.assetPath, this.displayName);

  /// 選挙スケールから対応するBGMトラックを返す。
  static BgmTrack fromScale(ElectionScale scale) {
    switch (scale) {
      case ElectionScale.village:
        return BgmTrack.village;
      case ElectionScale.town:
        return BgmTrack.town;
      case ElectionScale.city:
        return BgmTrack.city;
    }
  }
}

/// BGM再生サービス インターフェース。
abstract class BgmService {
  bool get isPlaying;
  BgmTrack? get currentTrack;
  double get volume;
  bool get disposed;

  void play(BgmTrack track);
  void stop();
  void setVolume(double volume);
  void dispose();
}

/// BGM再生のモック実装（テスト用）。
class MockBgmService implements BgmService {
  @override
  bool isPlaying = false;

  @override
  BgmTrack? currentTrack;

  @override
  double volume = 1.0;

  @override
  bool disposed = false;

  int playCount = 0;
  int stopCount = 0;

  @override
  void play(BgmTrack track) {
    if (disposed) return;
    currentTrack = track;
    isPlaying = true;
    playCount++;
  }

  @override
  void stop() {
    if (disposed) return;
    isPlaying = false;
    currentTrack = null;
    stopCount++;
  }

  @override
  void setVolume(double volume) {
    this.volume = volume.clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    stop();
    disposed = true;
  }
}
