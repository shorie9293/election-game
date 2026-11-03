import 'app_lock_repository.dart';
import 'lock_attempt_policy.dart';

/// アプリロックの状態と検証を担う純粋ロジック。
class AppLockService {
  final AppLockRepository _repository;
  final DateTime Function() _now;

  AppLockService(
    this._repository, {
    DateTime Function() now = DateTime.now,
  }) : _now = now;

  bool get isLocked => _repository.isEnabled();

  /// 復帰時に再施錠するまでの猶予。
  Duration get relockGrace =>
      Duration(seconds: _repository.getRelockGraceSeconds());

  /// 猶予を保存する（負値は ArgumentError）。
  Future<void> setRelockGrace(Duration grace) {
    if (grace.isNegative) {
      throw ArgumentError.value(grace, 'grace', '負の猶予は指定できない');
    }
    return _repository.setRelockGraceSeconds(grace.inSeconds);
  }

  /// 現在ロックアウト中か。
  bool get isLockedOut =>
      LockAttemptPolicy.isLockedOut(_repository.getLockedUntil(), _now());

  /// ロックアウト残り秒数（0 ならロックアウトなし）。
  int get lockoutRemainingSeconds =>
      LockAttemptPolicy.remainingSeconds(_repository.getLockedUntil(), _now());

  /// ロックを解除する。パスコード方式なら照合、生体認証方式なら
  /// 委譲結果で判定。ロックアウト中は照合せず false。
  Future<bool> unlock({
    String? passcode,
    bool biometricSucceeded = false,
  }) async {
    if (!_repository.isEnabled()) return true;
    if (isLockedOut) return false;

    final bool ok;
    switch (_repository.getMethod()) {
      case AppLockMethod.none:
        ok = true;
      case AppLockMethod.passcode:
        ok = passcode != null && _repository.verifyPasscode(passcode);
      case AppLockMethod.biometric:
        ok = biometricSucceeded;
    }

    if (ok) {
      await _repository.resetAttempts();
      return true;
    }
    await _recordFailure();
    return false;
  }

  Future<void> _recordFailure() async {
    final attempts = _repository.getFailedAttempts() + 1;
    await _repository.setFailedAttempts(attempts);
    final lockout = LockAttemptPolicy.lockoutFor(attempts);
    if (lockout <= Duration.zero) {
      await _repository.setLockedUntil(null);
      return;
    }
    await _repository.setLockedUntil(_now().add(lockout));
  }

  /// パスコード方式でロックを有効化する（4桁の数字以外は ArgumentError）。
  Future<void> enableWithPasscode(String passcode) async {
    if (passcode.length != 4) {
      throw ArgumentError.value(passcode, 'passcode', '4桁の数字を指定せよ');
    }
    if (int.tryParse(passcode) == null) {
      throw ArgumentError.value(passcode, 'passcode', '数字のみ');
    }
    await _repository.setPasscode(passcode);
    await _repository.setMethod(AppLockMethod.passcode);
    await _repository.setEnabled(true);
    await _repository.resetAttempts();
  }

  Future<void> disable() async {
    await _repository.setEnabled(false);
    await _repository.clearPasscode();
    await _repository.setMethod(AppLockMethod.none);
    await _repository.resetAttempts();
  }
}
