import 'dart:async';

import 'package:flutter/services.dart';

/// 効果音の種類（現世は音声アセットを持たないため端末のシステム音で代替する）
abstract class SfxService {
  /// 投票確定音
  void playVote();

  /// 棄権音
  void playAbstain();
}

/// SystemSound による実装（実機では操作音が鳴る）
class SystemSoundSfxService implements SfxService {
  const SystemSoundSfxService();

  @override
  void playVote() {
    unawaited(SystemSound.play(SystemSoundType.click));
  }

  @override
  void playAbstain() {
    unawaited(SystemSound.play(SystemSoundType.click));
  }
}

/// 試練用モック
class MockSfxService implements SfxService {
  int voteCount = 0;
  int abstainCount = 0;

  @override
  void playVote() => voteCount++;

  @override
  void playAbstain() => abstainCount++;
}
