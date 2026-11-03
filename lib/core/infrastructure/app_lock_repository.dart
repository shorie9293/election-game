import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ロック方式。
enum AppLockMethod { none, passcode, biometric }

/// パスコードハッシュの反復回数（v2 形式）。
const int kAppLockHashIterations = 1200;

/// v2 ハッシュのソルト長（バイト）。
const int kAppLockSaltBytes = 16;

/// アプリロック設定の永続化 abstraction（試練で差し替え可能に）。
abstract class AppLockRepository {
  bool isEnabled();
  Future<void> setEnabled(bool enabled);
  AppLockMethod getMethod();
  Future<void> setMethod(AppLockMethod method);
  String? getPasscodeHash();
  Future<void> setPasscode(String passcode);
  Future<void> clearPasscode();
  bool verifyPasscode(String passcode);

  /// 復帰時に再施錠するまでの猶予（秒）。
  int getRelockGraceSeconds();
  Future<void> setRelockGraceSeconds(int seconds);

  /// 連続失敗回数。
  int getFailedAttempts();
  Future<void> setFailedAttempts(int attempts);

  /// ロックアウト解除時刻。
  DateTime? getLockedUntil();
  Future<void> setLockedUntil(DateTime? until);

  /// 失敗回数とロックアウトを初期化する。
  Future<void> resetAttempts();
}

/// 実装: SharedPreferences による永続化。
class SharedPreferencesAppLockRepository implements AppLockRepository {
  static const _kEnabled = 'app_lock.enabled';
  static const _kMethod = 'app_lock.method';
  static const _kHash = 'app_lock.passcode_hash';
  static const _kGrace = 'app_lock.relock_grace_seconds';
  static const _kFailed = 'app_lock.failed_attempts';
  static const _kLockedUntil = 'app_lock.locked_until_ms';

  final SharedPreferences _prefs;
  SharedPreferencesAppLockRepository(this._prefs);

  @override
  bool isEnabled() => _prefs.getBool(_kEnabled) ?? false;

  @override
  Future<void> setEnabled(bool enabled) => _prefs.setBool(_kEnabled, enabled);

  @override
  AppLockMethod getMethod() {
    final name = _prefs.getString(_kMethod);
    return AppLockMethod.values
        .firstWhere((m) => m.name == name, orElse: () => AppLockMethod.none);
  }

  @override
  Future<void> setMethod(AppLockMethod method) =>
      _prefs.setString(_kMethod, method.name);

  @override
  String? getPasscodeHash() => _prefs.getString(_kHash);

  @override
  Future<void> setPasscode(String passcode) async {
    await _prefs.setString(_kHash, _v2HashOf(passcode));
  }

  @override
  bool verifyPasscode(String passcode) {
    final stored = getPasscodeHash();
    if (stored == null) return false;
    final ok = _verifyStoredHash(stored, passcode);
    if (ok && !_isV2(stored)) {
      // 旧形式からの無強制移行（投げっぱなし・再設定強要なし）。
      unawaited(setPasscode(passcode));
    }
    return ok;
  }

  @override
  Future<void> clearPasscode() => _prefs.remove(_kHash);

  @override
  int getRelockGraceSeconds() => _prefs.getInt(_kGrace) ?? 0;

  @override
  Future<void> setRelockGraceSeconds(int seconds) =>
      _prefs.setInt(_kGrace, seconds < 0 ? 0 : seconds);

  @override
  int getFailedAttempts() => _prefs.getInt(_kFailed) ?? 0;

  @override
  Future<void> setFailedAttempts(int attempts) =>
      _prefs.setInt(_kFailed, attempts < 0 ? 0 : attempts);

  @override
  DateTime? getLockedUntil() {
    final ms = _prefs.getInt(_kLockedUntil);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  Future<void> setLockedUntil(DateTime? until) {
    if (until == null) return _prefs.remove(_kLockedUntil);
    return _prefs.setInt(_kLockedUntil, until.millisecondsSinceEpoch);
  }

  @override
  Future<void> resetAttempts() async {
    await _prefs.setInt(_kFailed, 0);
    await _prefs.remove(_kLockedUntil);
  }
}

/// 試練用インメモリ実装。
class InMemoryAppLockRepository implements AppLockRepository {
  bool _enabled = false;
  AppLockMethod _method = AppLockMethod.none;
  String? _passcodeHash;
  int _graceSeconds = 0;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  @override
  bool isEnabled() => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async => _enabled = enabled;

  @override
  AppLockMethod getMethod() => _method;

  @override
  Future<void> setMethod(AppLockMethod method) async => _method = method;

  @override
  String? getPasscodeHash() => _passcodeHash;

  @override
  Future<void> setPasscode(String passcode) async {
    _passcodeHash = _v2HashOf(passcode);
  }

  @override
  bool verifyPasscode(String passcode) {
    final stored = _passcodeHash;
    if (stored == null) return false;
    final ok = _verifyStoredHash(stored, passcode);
    if (ok && !_isV2(stored)) {
      _passcodeHash = _v2HashOf(passcode);
    }
    return ok;
  }

  @override
  Future<void> clearPasscode() async => _passcodeHash = null;

  @override
  int getRelockGraceSeconds() => _graceSeconds;

  @override
  Future<void> setRelockGraceSeconds(int seconds) async =>
      _graceSeconds = seconds < 0 ? 0 : seconds;

  @override
  int getFailedAttempts() => _failedAttempts;

  @override
  Future<void> setFailedAttempts(int attempts) async =>
      _failedAttempts = attempts < 0 ? 0 : attempts;

  @override
  DateTime? getLockedUntil() => _lockedUntil;

  @override
  Future<void> setLockedUntil(DateTime? until) async => _lockedUntil = until;

  @override
  Future<void> resetAttempts() async {
    _failedAttempts = 0;
    _lockedUntil = null;
  }
}

// ---------------------------------------------------------------------------
// ハッシュ処理（v2 形式 + 旧形式の互換照合）
// ---------------------------------------------------------------------------

const String _legacySalt = 'election-app-lock:';

/// 旧形式（salt + 単発 sha256）のハッシュ。移行照合のためだけに残す。
String _legacyHashOf(String passcode) {
  return sha256.convert(utf8.encode('$_legacySalt$passcode')).toString();
}

bool _isV2(String stored) => stored.startsWith('v2:');

/// `v2:<iterations>:<saltHex>:<hashHex>` を生成する（ソルトは端末ごとにランダム）。
String _v2HashOf(String passcode) {
  final saltHex = _randomSaltHex();
  final hashHex = _digestHex(saltHex, passcode, kAppLockHashIterations);
  return 'v2:$kAppLockHashIterations:$saltHex:$hashHex';
}

String _randomSaltHex() {
  final random = Random.secure();
  final bytes = List<int>.generate(kAppLockSaltBytes, (_) => random.nextInt(256));
  final buffer = StringBuffer();
  for (final b in bytes) {
    buffer.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// sha256(utf8(saltHex + ':' + passcode)) を iterations-1 回反復する。
String _digestHex(String saltHex, String passcode, int iterations) {
  var digest = sha256.convert(utf8.encode('$saltHex:$passcode'));
  for (var i = 1; i < iterations; i++) {
    digest = sha256.convert(digest.bytes);
  }
  return digest.toString();
}

bool _verifyStoredHash(String stored, String passcode) {
  if (!_isV2(stored)) {
    return _constantTimeEquals(stored, _legacyHashOf(passcode));
  }
  final parts = stored.split(':');
  if (parts.length != 4) return false;
  final iterations = int.tryParse(parts[1]);
  if (iterations == null || iterations < 1 || iterations > 100000) return false;
  final saltHex = parts[2];
  final expected = parts[3];
  if (saltHex.isEmpty || expected.isEmpty) return false;
  final actual = _digestHex(saltHex, passcode, iterations);
  return _constantTimeEquals(expected, actual);
}

/// タイミング攻撃に耐える定数時間文字列比較。
bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}
