import 'quiet_hours_service.dart';
import 'quiet_hours_settings.dart';

/// 静穏時間を適用した後の「1曜日分の送出計画」。
///
/// [weekday] は [DateTime.weekday] 準拠（1=月 .. 7=日）。
/// 日跨ぎで繰り延べた場合は曜日が翌日に移る。
class QuietHoursDeliverySlot {
  const QuietHoursDeliverySlot({
    required this.weekday,
    required this.hour,
    required this.minute,
    required this.deferred,
  });

  final int weekday;
  final int hour;
  final int minute;

  /// 静穏時間により繰り延べられたか（false なら元の時刻のまま）。
  final bool deferred;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuietHoursDeliverySlot &&
          other.weekday == weekday &&
          other.hour == hour &&
          other.minute == minute &&
          other.deferred == deferred;

  @override
  int get hashCode => Object.hash(weekday, hour, minute, deferred);

  @override
  String toString() =>
      'QuietHoursDeliverySlot(weekday: $weekday, '
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, '
      'deferred: $deferred)';
}

/// 繰り返し通知の送出計画を立てる純粋ロジック。
///
/// 通知サービスは曜日ごとに「次回発火時刻」を作り、静穏時間ガードへ
/// 問い合わせる。[guard] が null を返した曜日は送出しない（skip）。
abstract final class QuietHoursDeliveryPlanner {
  /// [weekdays] 各曜日の次回発火を静穏時間で調整した計画を返す。
  ///
  /// 送出しない曜日は結果に含まれない。同一の送出曜日に複数が集約された
  /// 場合は先勝ちで1件に畳む（繰り返し登録の衝突回避）。[now] はローカル時刻。
  static List<QuietHoursDeliverySlot> plan({
    required DateTime now,
    required int hour,
    required int minute,
    required List<int> weekdays,
    required QuietHoursSettings settings,
  }) {
    final slots = <QuietHoursDeliverySlot>[];
    for (final weekday in _sortedWeekdays(weekdays)) {
      final scheduled = nextOccurrenceOfWeekday(now, weekday, hour, minute);
      final delivery = QuietHoursService.resolveDelivery(settings, scheduled);
      if (delivery == null) continue;
      slots.add(
        QuietHoursDeliverySlot(
          weekday: delivery.weekday,
          hour: delivery.hour,
          minute: delivery.minute,
          deferred: delivery != scheduled,
        ),
      );
    }
    return _dedupeByWeekday(slots);
  }

  /// ガードへ問い合わせて計画を立てる（通知経路が使う非同期版）。
  ///
  /// [guard] が null なら静穏時間なし＝元の曜日・時刻をそのまま使う。
  static Future<List<QuietHoursDeliverySlot>> planWithGuard({
    required DateTime now,
    required int hour,
    required int minute,
    required List<int> weekdays,
    QuietHoursGuard? guard,
  }) async {
    final slots = <QuietHoursDeliverySlot>[];
    for (final weekday in _sortedWeekdays(weekdays)) {
      final scheduled = nextOccurrenceOfWeekday(now, weekday, hour, minute);
      // guard == null は「静穏時間なし」、adjust の null は「送出しない」。
      // null 合体演算子で畳むと skip が素通しになるため分岐を明示する。
      final delivery = guard == null ? scheduled : await guard.adjust(scheduled);
      if (delivery == null) continue;
      slots.add(
        QuietHoursDeliverySlot(
          weekday: delivery.weekday,
          hour: delivery.hour,
          minute: delivery.minute,
          deferred: delivery != scheduled,
        ),
      );
    }
    return _dedupeByWeekday(slots);
  }

  /// [now] 以降で最初に来る [weekday] の [hour]:[minute]（ローカル時刻）。
  static DateTime nextOccurrenceOfWeekday(
    DateTime now,
    int weekday,
    int hour,
    int minute,
  ) {
    var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    var guardCount = 0;
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = DateTime(
        scheduled.year,
        scheduled.month,
        scheduled.day + 1,
        hour,
        minute,
      );
      guardCount++;
      if (guardCount > 8) {
        throw ArgumentError.value(weekday, 'weekday', '1-7 の範囲で指定せよ');
      }
    }
    return scheduled;
  }

  static List<int> _sortedWeekdays(List<int> weekdays) {
    for (final w in weekdays) {
      if (w < 1 || w > 7) {
        throw ArgumentError.value(w, 'weekdays', '1(月)-7(日) の範囲で指定せよ');
      }
    }
    return List<int>.of(weekdays.toSet().toList())..sort();
  }

  static List<QuietHoursDeliverySlot> _dedupeByWeekday(
    List<QuietHoursDeliverySlot> slots,
  ) {
    final byWeekday = <int, QuietHoursDeliverySlot>{};
    for (final slot in slots) {
      byWeekday.putIfAbsent(slot.weekday, () => slot);
    }
    final merged = byWeekday.values.toList()
      ..sort((a, b) => a.weekday.compareTo(b.weekday));
    return merged;
  }
}
