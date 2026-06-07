import 'package:audioplayers/audioplayers.dart';
import 'package:election_game/services/bgm_service.dart';

/// BGM再生の実装実装（audioplayers を使用）。
class AudioPlayersBgmService implements BgmService {
  final AudioPlayer _player = AudioPlayer();
  BgmTrack? _currentTrack;
  double _volume = 1.0;
  bool _disposed = false;

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  BgmTrack? get currentTrack => _currentTrack;

  @override
  double get volume => _volume;

  @override
  bool get disposed => _disposed;

  @override
  void play(BgmTrack track) {
    if (_disposed) return;
    _stop();
    _currentTrack = track;
    _player.setVolume(_volume); // Apply current volume
    _player.play(AssetSource(track.assetPath));
  }

  void _stop() {
    _player.stop();
    _currentTrack = null;
  }

  @override
  void stop() {
    if (_disposed) return;
    _stop();
  }

  @override
  void setVolume(double volume) {
    if (_disposed) return;
    _volume = volume.clamp(0.0, 1.0);
    _player.setVolume(_volume);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _stop();
    _player.dispose();
    _disposed = true;
  }
}