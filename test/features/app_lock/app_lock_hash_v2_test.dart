import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';
import 'package:election_game/core/infrastructure/app_lock_service.dart';
import 'package:election_game/core/infrastructure/lock_attempt_policy.dart';

String legacyHash(String passcode) =>
    sha256.convert(utf8.encode('election-app-lock:$passcode')).toString();

void main() {
  group('v2 ハッシュ形式', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('保存値は v2:<iterations>:<saltHex>:<hashHex>', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);
      await repo.setPasscode('1234');

      final stored = repo.getPasscodeHash()!;
      expect(stored.startsWith('v2:'), isTrue);
      final parts = stored.split(':');
      expect(parts.length, 4);
      expect(parts[1], '$kAppLockHashIterations');
      expect(parts[2].length, kAppLockSaltBytes * 2, reason: '16バイト=32 hex');
      expect(parts[3].length, 64, reason: 'sha256 hex');
      expect(stored.contains('1234'), isFalse, reason: '生パスコードが漏れている');
    });

    test('salt は毎回ランダムで、同一パスコードでも保存値が異なる', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);

      await repo.setPasscode('1234');
      final first = repo.getPasscodeHash()!;
      await repo.setPasscode('1234');
      final second = repo.getPasscodeHash()!;

      expect(first, isNot(second));
      expect(first.split(':')[2], isNot(second.split(':')[2]));
      expect(repo.verifyPasscode('1234'), isTrue);
    });

    test('InMemory も v2 で保存し照合できる', () async {
      final repo = InMemoryAppLockRepository();
      await repo.setPasscode('4321');
      expect(repo.getPasscodeHash()!.startsWith('v2:'), isTrue);
      expect(repo.verifyPasscode('4321'), isTrue);
      expect(repo.verifyPasscode('1234'), isFalse);
    });
  });

  group('旧形式からの無強制移行', () {
    test('旧ハッシュでも一致すれば照合成功し、v2 へ再保存される', () async {
      SharedPreferences.setMockInitialValues({
        'app_lock.passcode_hash': legacyHash('1234'),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);

      expect(repo.getPasscodeHash(), legacyHash('1234'));
      expect(repo.verifyPasscode('1234'), isTrue);

      await Future<void>.delayed(Duration.zero);
      final migrated = repo.getPasscodeHash()!;
      expect(migrated.startsWith('v2:'), isTrue, reason: '移行されていない');
      expect(repo.verifyPasscode('1234'), isTrue, reason: '移行後に照合できない');
    });

    test('不一致なら移行しない（総当たりでの書き換えを避ける）', () async {
      SharedPreferences.setMockInitialValues({
        'app_lock.passcode_hash': legacyHash('1234'),
      });
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);

      expect(repo.verifyPasscode('9999'), isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(repo.getPasscodeHash(), legacyHash('1234'));
    });
  });

  group('失敗回数・ロックアウトの往復', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('failedAttempts / lockedUntil / resetAttempts が永続化される', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);
      final until = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      expect(repo.getFailedAttempts(), 0);
      expect(repo.getLockedUntil(), isNull);
      expect(repo.getRelockGraceSeconds(), 0);

      await repo.setFailedAttempts(3);
      await repo.setLockedUntil(until);
      await repo.setRelockGraceSeconds(60);
      expect(repo.getFailedAttempts(), 3);
      expect(repo.getLockedUntil(), until);
      expect(repo.getRelockGraceSeconds(), 60);

      await repo.resetAttempts();
      expect(repo.getFailedAttempts(), 0);
      expect(repo.getLockedUntil(), isNull);
      expect(repo.getRelockGraceSeconds(), 60, reason: '猶予は reset 対象外');
    });

    test('5回失敗でロックアウトし、6回目は照合せず false', () async {
      final repo = InMemoryAppLockRepository();
      var now = DateTime(2026, 11, 4, 12);
      final service = AppLockService(repo, now: () => now);
      await service.enableWithPasscode('1234');

      for (var i = 1; i <= 5; i++) {
        expect(await service.unlock(passcode: '9999'), isFalse);
        expect(repo.getFailedAttempts(), i);
      }
      expect(repo.getLockedUntil(), now.add(const Duration(seconds: 30)));
      expect(service.isLockedOut, isTrue);
      expect(service.lockoutRemainingSeconds, 30);

      // ロックアウト中は正しいパスコードでも照合しない。
      expect(await service.unlock(passcode: '1234'), isFalse);
      expect(repo.getFailedAttempts(), 5, reason: 'ロックアウト中に加算している');

      // 経過後は解除でき、失敗回数がリセットされる。
      now = now.add(const Duration(seconds: 31));
      expect(service.isLockedOut, isFalse);
      expect(await service.unlock(passcode: '1234'), isTrue);
      expect(repo.getFailedAttempts(), 0);
      expect(repo.getLockedUntil(), isNull);
    });

    test('成功で失敗回数がリセットされる', () async {
      final repo = InMemoryAppLockRepository();
      final service = AppLockService(repo);
      await service.enableWithPasscode('1234');

      await service.unlock(passcode: '0000');
      await service.unlock(passcode: '0001');
      expect(repo.getFailedAttempts(), 2);

      expect(await service.unlock(passcode: '1234'), isTrue);
      expect(repo.getFailedAttempts(), 0);
      expect(repo.getLockedUntil(), isNull);
    });

    test('段階的ロックアウト: 30秒 → 60秒 → 上限15分', () async {
      final repo = InMemoryAppLockRepository();
      var now = DateTime(2026, 11, 4, 12);
      final service = AppLockService(repo, now: () => now);
      await service.enableWithPasscode('1234');

      for (var i = 0; i < 10; i++) {
        now = now.add(const Duration(minutes: 16));
        await service.unlock(passcode: '9999');
      }
      expect(repo.getFailedAttempts(), 10);
      expect(repo.getLockedUntil(), now.add(const Duration(seconds: 60)));

      for (var i = 0; i < 20; i++) {
        now = now.add(const Duration(minutes: 16));
        await service.unlock(passcode: '9999');
      }
      expect(
        repo.getLockedUntil(),
        now.add(LockAttemptPolicy.maxLockout),
      );
    });
  });

  group('猶予設定の検証', () {
    test('負の猶予は ArgumentError', () async {
      final repo = InMemoryAppLockRepository();
      final service = AppLockService(repo);
      expect(
        () => service.setRelockGrace(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('setRelockGrace → relockGrace が反映される', () async {
      final repo = InMemoryAppLockRepository();
      final service = AppLockService(repo);
      await service.setRelockGrace(const Duration(minutes: 5));
      expect(service.relockGrace, const Duration(minutes: 5));
      expect(repo.getRelockGraceSeconds(), 300);
    });
  });
}
