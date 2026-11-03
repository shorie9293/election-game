import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/lock_reload_policy.dart';

void main() {
  final t0 = DateTime(2026, 11, 4, 12, 0, 0);

  group('LockReloadPolicy.shouldRelock', () {
    test('背景化時刻が null なら再施錠する', () {
      expect(
        LockReloadPolicy.shouldRelock(null, t0, const Duration(minutes: 5)),
        isTrue,
      );
    });

    test('猶予 0 なら即時に再施錠する', () {
      expect(
        LockReloadPolicy.shouldRelock(t0, t0, Duration.zero),
        isTrue,
      );
    });

    test('猶予内なら再施錠しない', () {
      expect(
        LockReloadPolicy.shouldRelock(
          t0,
          t0.add(const Duration(seconds: 29)),
          const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('猶予ちょうどで再施錠する', () {
      expect(
        LockReloadPolicy.shouldRelock(
          t0,
          t0.add(const Duration(seconds: 30)),
          const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('猶予超過で再施錠する', () {
      expect(
        LockReloadPolicy.shouldRelock(
          t0,
          t0.add(const Duration(minutes: 6)),
          const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('時計巻き戻しは安全側（再施錠）に倒す', () {
      expect(
        LockReloadPolicy.shouldRelock(
          t0,
          t0.subtract(const Duration(seconds: 1)),
          const Duration(minutes: 5),
        ),
        isTrue,
      );
    });

    test('負の猶予は即時扱い', () {
      expect(
        LockReloadPolicy.shouldRelock(
          t0,
          t0,
          const Duration(seconds: -1),
        ),
        isTrue,
      );
    });
  });

  group('LockReloadPolicy.graceLabel', () {
    test('選択肢のラベル', () {
      expect(LockReloadPolicy.graceLabel(0), '即時');
      expect(LockReloadPolicy.graceLabel(30), '30秒');
      expect(LockReloadPolicy.graceLabel(60), '1分');
      expect(LockReloadPolicy.graceLabel(300), '5分');
    });

    test('選択肢外は秒数表記', () {
      expect(LockReloadPolicy.graceLabel(45), '45秒');
    });

    test('選択肢は既定が先頭（即時）', () {
      expect(LockReloadPolicy.graceOptionsSeconds.first, 0);
      expect(LockReloadPolicy.graceOptionsSeconds, [0, 30, 60, 300]);
    });
  });
}
