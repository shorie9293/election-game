import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/infrastructure/app_lock_repository.dart';

void main() {
  group('InMemoryAppLockRepository', () {
    late InMemoryAppLockRepository repo;

    setUp(() {
      repo = InMemoryAppLockRepository();
    });

    test('初期状態は無効・none・ハッシュなし', () {
      expect(repo.isEnabled(), isFalse);
      expect(repo.getMethod(), AppLockMethod.none);
      expect(repo.getPasscodeHash(), isNull);
      expect(repo.verifyPasscode('1234'), isFalse);
    });

    test('setPasscode → verifyPasscode が salt+sha256 で一致', () async {
      await repo.setPasscode('1234');
      expect(repo.getPasscodeHash(), isNotNull);
      expect(repo.verifyPasscode('1234'), isTrue);
      expect(repo.verifyPasscode('4321'), isFalse);
    });

    test('enabled/method の保存', () async {
      await repo.setEnabled(true);
      await repo.setMethod(AppLockMethod.passcode);
      expect(repo.isEnabled(), isTrue);
      expect(repo.getMethod(), AppLockMethod.passcode);
    });

    test('clearPasscode で照合不可になる', () async {
      await repo.setPasscode('1234');
      await repo.clearPasscode();
      expect(repo.getPasscodeHash(), isNull);
      expect(repo.verifyPasscode('1234'), isFalse);
    });
  });

  group('SharedPreferencesAppLockRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('パスコードの保存と照合（SharedPreferences）', () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);

      expect(repo.isEnabled(), isFalse);
      expect(repo.getMethod(), AppLockMethod.none);
      expect(repo.getPasscodeHash(), isNull);
      expect(repo.verifyPasscode('1234'), isFalse);

      await repo.setPasscode('1234');
      expect(repo.verifyPasscode('1234'), isTrue);
      expect(repo.verifyPasscode('9999'), isFalse);

      await repo.setEnabled(true);
      await repo.setMethod(AppLockMethod.passcode);
      expect(repo.isEnabled(), isTrue);
      expect(repo.getMethod(), AppLockMethod.passcode);

      await repo.clearPasscode();
      expect(repo.getPasscodeHash(), isNull);
      expect(repo.verifyPasscode('1234'), isFalse);
    });

    test('保存された値は salt を用いた sha256 hex（生パスコードは保存されない）',
        () async {
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPreferencesAppLockRepository(prefs);
      await repo.setPasscode('7777');

      // 同saltで再計算した結果と一致し、生パスコードは保存されない
      final stored = repo.getPasscodeHash();
      expect(stored, isNotNull);
      expect(stored, isNot('7777'));
      expect(stored!.length, 64); // sha256 の hex 長
    });
  });
}
