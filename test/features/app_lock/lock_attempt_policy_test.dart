import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/lock_attempt_policy.dart';

void main() {
  final t0 = DateTime(2026, 11, 4, 12, 0, 0);

  group('LockAttemptPolicy.lockoutFor', () {
    test('4回以下はロックアウトなし', () {
      for (var n = 0; n < LockAttemptPolicy.maxFreeAttempts; n++) {
        expect(LockAttemptPolicy.lockoutFor(n), Duration.zero, reason: '$n回');
      }
    });

    test('5回で30秒', () {
      expect(
        LockAttemptPolicy.lockoutFor(5),
        const Duration(seconds: 30),
      );
    });

    test('5回ごとに倍々（9回は据え置き・10回で倍）', () {
      expect(LockAttemptPolicy.lockoutFor(9), const Duration(seconds: 30));
      expect(LockAttemptPolicy.lockoutFor(10), const Duration(seconds: 60));
      expect(LockAttemptPolicy.lockoutFor(15), const Duration(seconds: 120));
      expect(LockAttemptPolicy.lockoutFor(20), const Duration(seconds: 240));
    });

    test('上限は15分で頭打ち', () {
      expect(
        LockAttemptPolicy.lockoutFor(30),
        const Duration(minutes: 15),
      );
      expect(
        LockAttemptPolicy.lockoutFor(10000),
        const Duration(minutes: 15),
      );
    });

    test('上限定数', () {
      expect(LockAttemptPolicy.baseLockout, const Duration(seconds: 30));
      expect(LockAttemptPolicy.maxLockout, const Duration(minutes: 15));
      expect(LockAttemptPolicy.maxFreeAttempts, 5);
    });
  });

  group('LockAttemptPolicy.isLockedOut', () {
    test('null は非ロックアウト', () {
      expect(LockAttemptPolicy.isLockedOut(null, t0), isFalse);
    });

    test('未来ならロックアウト中', () {
      expect(
        LockAttemptPolicy.isLockedOut(
          t0.add(const Duration(seconds: 1)),
          t0,
        ),
        isTrue,
      );
    });

    test('同時刻・過去は非ロックアウト', () {
      expect(LockAttemptPolicy.isLockedOut(t0, t0), isFalse);
      expect(
        LockAttemptPolicy.isLockedOut(
          t0.subtract(const Duration(seconds: 1)),
          t0,
        ),
        isFalse,
      );
    });
  });

  group('LockAttemptPolicy.remainingSeconds', () {
    test('残りを切り上げで返す', () {
      expect(
        LockAttemptPolicy.remainingSeconds(
          t0.add(const Duration(seconds: 30)),
          t0,
        ),
        30,
      );
      expect(
        LockAttemptPolicy.remainingSeconds(
          t0.add(const Duration(milliseconds: 500)),
          t0,
        ),
        1,
      );
    });

    test('過去・null は 0', () {
      expect(
        LockAttemptPolicy.remainingSeconds(
          t0.subtract(const Duration(seconds: 5)),
          t0,
        ),
        0,
      );
      expect(LockAttemptPolicy.remainingSeconds(null, t0), 0);
    });
  });

  group('LockAttemptPolicy.lockoutLabel', () {
    test('残り秒数を含む案内文言', () {
      expect(
        LockAttemptPolicy.lockoutLabel(30),
        'しばらく待ってから再試行してください（残り30秒）',
      );
    });
  });
}
