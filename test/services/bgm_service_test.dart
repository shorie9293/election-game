import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/services/bgm_service.dart';
import 'package:election_game/domain/models/election_scale.dart';

void main() {
  group('BgmTrack', () {
    test('scale から正しいトラックを返す', () {
      expect(BgmTrack.fromScale(ElectionScale.village), BgmTrack.village);
      expect(BgmTrack.fromScale(ElectionScale.town), BgmTrack.town);
      expect(BgmTrack.fromScale(ElectionScale.city), BgmTrack.city);
    });

    test('全トラックが displayName を持つ', () {
      for (final track in BgmTrack.values) {
        expect(track.displayName, isNotEmpty);
        expect(track.assetPath, isNotEmpty);
        expect(track.assetPath, contains('bgm/'));
      }
    });
  });

  group('MockBgmService', () {
    late MockBgmService service;

    setUp(() {
      service = MockBgmService();
    });

    test('初期状態は停止', () {
      expect(service.isPlaying, false);
      expect(service.currentTrack, isNull);
    });

    test('play で再生状態になる', () {
      service.play(BgmTrack.village);
      expect(service.isPlaying, true);
      expect(service.currentTrack, BgmTrack.village);
    });

    test('play で別のトラックに切り替わる', () {
      service.play(BgmTrack.village);
      service.play(BgmTrack.town);
      expect(service.currentTrack, BgmTrack.town);
      expect(service.playCount, 2);
    });

    test('stop で停止', () {
      service.play(BgmTrack.village);
      service.stop();
      expect(service.isPlaying, false);
      expect(service.currentTrack, isNull);
    });

    test('同じトラックを再playしても再生回数は増える', () {
      service.play(BgmTrack.village);
      service.play(BgmTrack.village);
      expect(service.playCount, 2);
    });

    test('停止後に別のトラックを再生できる', () {
      service.play(BgmTrack.village);
      service.stop();
      service.play(BgmTrack.city);
      expect(service.isPlaying, true);
      expect(service.currentTrack, BgmTrack.city);
    });

    test('setVolume で音量が変更される', () {
      service.setVolume(0.5);
      expect(service.volume, 0.5);
    });

    test('setVolume で 0.0〜1.0 の範囲外はクランプされる', () {
      service.setVolume(-0.5);
      expect(service.volume, 0.0);
      service.setVolume(1.5);
      expect(service.volume, 1.0);
    });

    test('dispose で停止状態になる', () {
      service.play(BgmTrack.village);
      service.dispose();
      expect(service.isPlaying, false);
      expect(service.disposed, true);
    });
  });
}
