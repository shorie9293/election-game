/// パスコード試行制限・ロックアウトの判定を担う純粋ロジック。
class LockAttemptPolicy {
  /// 猶予される失敗回数（この回数まではロックアウトしない）。
  static const int maxFreeAttempts = 5;

  /// 最初のロックアウト時間。
  static const Duration baseLockout = Duration(seconds: 30);

  /// ロックアウトの上限。
  static const Duration maxLockout = Duration(minutes: 15);

  /// 現在ロックアウト中か（lockedUntil が未来なら真）。
  static bool isLockedOut(DateTime? lockedUntil, DateTime now) {
    if (lockedUntil == null) return false;
    return now.isBefore(lockedUntil);
  }

  /// 失敗回数に応じたロックアウト時間。
  ///
  /// < 5 回 → 0、>= 5 回 → base * 2^((n-5)~/5)（上限 15 分）。
  static Duration lockoutFor(int failedAttempts) {
    if (failedAttempts < maxFreeAttempts) return Duration.zero;
    final exponent = (failedAttempts - maxFreeAttempts) ~/ maxFreeAttempts;
    // 上限に達する指数（30s * 2^5 = 960s > 900s）で頭打ちにし桁溢れを防ぐ。
    final cappedExponent = exponent > 5 ? 5 : exponent;
    final seconds = baseLockout.inSeconds * (1 << cappedExponent);
    if (seconds >= maxLockout.inSeconds) return maxLockout;
    return Duration(seconds: seconds);
  }

  /// ロックアウト残り秒数（過去・null は 0、端数は切り上げ）。
  static int remainingSeconds(DateTime? lockedUntil, DateTime now) {
    return remaining(lockedUntil, now).inSeconds;
  }

  /// ロックアウト残り時間（過去・null は 0、端数は切り上げ）。
  static Duration remaining(DateTime? lockedUntil, DateTime now) {
    if (lockedUntil == null) return Duration.zero;
    if (!now.isBefore(lockedUntil)) return Duration.zero;
    final diff = lockedUntil.difference(now);
    return Duration(seconds: (diff.inMilliseconds / 1000).ceil());
  }

  /// ロックアウト中の案内文言。
  static String lockoutLabel(int seconds) =>
      'しばらく待ってから再試行してください（残り$seconds秒）';
}
