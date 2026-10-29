import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/lifecycle/domain/day_rollover_detector.dart';

/// 日付跨ぎ検出器の試練。
///
/// 判定はローカル暦（年/月/日）で行う。UTC を混ぜると JST の深夜帯で
/// 1日ずれるため、固定値はすべてローカル [DateTime] で組む。
void main() {
  group('DayRolloverDetector', () {
    test('同日なら sameDay を返し lastSeen を更新する', () {
      final detector = DayRolloverDetector(
        lastSeen: DateTime(2026, 10, 13, 8, 0),
      );

      final result = detector.check(DateTime(2026, 10, 13, 23, 59));

      expect(result, DayRolloverResult.sameDay);
      expect(detector.lastSeen, DateTime(2026, 10, 13, 23, 59));
    });

    test('翌日なら rolledOver を返し lastSeen を now へ進める', () {
      final detector = DayRolloverDetector(
        lastSeen: DateTime(2026, 10, 13, 23, 30),
      );

      final result = detector.check(DateTime(2026, 10, 14, 0, 5));

      expect(result, DayRolloverResult.rolledOver);
      expect(detector.lastSeen, DateTime(2026, 10, 14, 0, 5));
    });

    test('日付が巻き戻ったら clockWentBack を返し lastSeen を据え置く（例外なし）', () {
      final detector = DayRolloverDetector(
        lastSeen: DateTime(2026, 10, 13, 12, 0),
      );

      final result = detector.check(DateTime(2026, 10, 12, 12, 0));

      expect(result, DayRolloverResult.clockWentBack);
      expect(detector.lastSeen, DateTime(2026, 10, 13, 12, 0));
    });

    test('跨ぎ後さらに同日なら同じ rolledOver は再発火せず sameDay になる', () {
      final detector = DayRolloverDetector(
        lastSeen: DateTime(2026, 10, 13, 23, 0),
      );

      expect(
        detector.check(DateTime(2026, 10, 14, 0, 1)),
        DayRolloverResult.rolledOver,
      );
      expect(
        detector.check(DateTime(2026, 10, 14, 9, 0)),
        DayRolloverResult.sameDay,
      );
      expect(detector.lastSeen, DateTime(2026, 10, 14, 9, 0));
    });

    test('月を跨ぐ跨ぎも rolledOver になる', () {
      final detector = DayRolloverDetector(
        lastSeen: DateTime(2026, 10, 31, 22, 0),
      );

      expect(
        detector.check(DateTime(2026, 11, 1, 7, 0)),
        DayRolloverResult.rolledOver,
      );
      expect(detector.lastSeen, DateTime(2026, 11, 1, 7, 0));
    });
  });
}
