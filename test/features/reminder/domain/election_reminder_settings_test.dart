import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ElectionNotificationKind', () {
    test('label が日本語で定義されている', () {
      expect(ElectionNotificationKind.turnProgress.label, 'ターン進行');
      expect(ElectionNotificationKind.electionDay.label, '選挙期日');
      expect(ElectionNotificationKind.lifeParamWarning.label, '生活パラメータ警告');
    });

    test('description が空でない', () {
      for (final kind in ElectionNotificationKind.values) {
        expect(kind.description, isNotEmpty);
      }
    });
  });

  group('ElectionReminderSettings コンストラクタ検証', () {
    test('hour が範囲外なら ArgumentError', () {
      expect(() => ElectionReminderSettings(hour: -1), throwsArgumentError);
      expect(() => ElectionReminderSettings(hour: 24), throwsArgumentError);
    });

    test('minute が範囲外なら ArgumentError', () {
      expect(() => ElectionReminderSettings(minute: -1), throwsArgumentError);
      expect(() => ElectionReminderSettings(minute: 60), throwsArgumentError);
    });

    test('weekdays が 1-7 の範囲外なら ArgumentError', () {
      expect(
        () => ElectionReminderSettings(weekdays: const [0]),
        throwsArgumentError,
      );
      expect(
        () => ElectionReminderSettings(weekdays: const [8]),
        throwsArgumentError,
      );
    });

    test('正常値で生成できる', () {
      final s = ElectionReminderSettings(
        enabled: true,
        hour: 20,
        minute: 30,
        weekdays: const [1, 3],
      );
      expect(s.enabled, isTrue);
      expect(s.hour, 20);
      expect(s.minute, 30);
      expect(s.weekdays, [1, 3]);
    });
  });

  group('weekdays 正規化', () {
    test('昇順ユニークに正規化される', () {
      final s = ElectionReminderSettings(weekdays: const [7, 1, 3, 1, 5]);
      expect(s.weekdays, [1, 3, 5, 7]);
    });

    test('書き換え不可（unmodifiable）', () {
      final s = ElectionReminderSettings.defaults();
      expect(() => s.weekdays.add(9), throwsUnsupportedError);
    });
  });

  group('defaults', () {
    test('無効・20:00・全7日・全種類有効・updatedAt null', () {
      final s = ElectionReminderSettings.defaults();
      expect(s.enabled, isFalse);
      expect(s.hour, 20);
      expect(s.minute, 0);
      expect(s.weekdays, [1, 2, 3, 4, 5, 6, 7]);
      expect(s.enabledKinds, ElectionNotificationKind.values.toSet());
      expect(s.updatedAt, isNull);
      expect(s.isDaily, isTrue);
    });
  });

  group('isDaily', () {
    test('7件なら true', () {
      expect(
        ElectionReminderSettings(
          weekdays: [1, 2, 3, 4, 5, 6, 7],
        ).isDaily,
        isTrue,
      );
    });

    test('7件未満なら false', () {
      expect(ElectionReminderSettings(weekdays: [1]).isDaily, isFalse);
    });
  });

  group('copyWith', () {
    test('指定フィールドのみ変更', () {
      final base = ElectionReminderSettings.defaults();
      final copied = base.copyWith(enabled: true, hour: 21);
      expect(copied.enabled, isTrue);
      expect(copied.hour, 21);
      expect(copied.minute, 0);
      expect(copied.weekdays, base.weekdays);
      expect(identical(copied, base), isFalse);
    });

    test('enabledKinds も変更できる', () {
      final copied = ElectionReminderSettings.defaults().copyWith(
        enabledKinds: {ElectionNotificationKind.electionDay},
      );
      expect(
        copied.enabledKinds,
        {ElectionNotificationKind.electionDay},
      );
    });

    test('updatedAt も変更できる', () {
      final t = DateTime(2026, 10, 8, 12);
      final copied = ElectionReminderSettings.defaults().copyWith(
        updatedAt: t,
      );
      expect(copied.updatedAt, t);
    });
  });

  group('JSON 往復', () {
    test('toJson → fromJson で復元できる', () {
      final s = ElectionReminderSettings(
        enabled: true,
        hour: 7,
        minute: 15,
        weekdays: const [2, 4, 6],
        enabledKinds: {
          ElectionNotificationKind.turnProgress,
          ElectionNotificationKind.electionDay,
        },
        updatedAt: DateTime(2026, 10, 8, 9, 0),
      );
      final restored = ElectionReminderSettings.fromJson(s.toJson());
      expect(restored, s);
      expect(restored.updatedAt, s.updatedAt);
      expect(
        restored.enabledKinds,
        {
          ElectionNotificationKind.turnProgress,
          ElectionNotificationKind.electionDay,
        },
      );
    });

    test('updatedAt null の往復', () {
      final s = ElectionReminderSettings.defaults();
      final restored = ElectionReminderSettings.fromJson(s.toJson());
      expect(restored, s);
      expect(restored.updatedAt, isNull);
    });
  });

  group('fromJson FormatException', () {
    Map<String, dynamic> validJson() => {
          'enabled': true,
          'hour': 20,
          'minute': 0,
          'weekdays': [1],
          'enabledKinds': ['turnProgress'],
        };

    test('欠落キー', () {
      expect(
        () => ElectionReminderSettings.fromJson({'enabled': true}),
        throwsFormatException,
      );
    });

    test('型不一致 enabled', () {
      expect(
        () => ElectionReminderSettings.fromJson({
          ...validJson(),
          'enabled': 'yes',
        }),
        throwsFormatException,
      );
    });

    test('型不一致 hour', () {
      expect(
        () => ElectionReminderSettings.fromJson({
          ...validJson(),
          'hour': '20',
        }),
        throwsFormatException,
      );
    });

    test('weekdays の要素型不一致', () {
      expect(
        () => ElectionReminderSettings.fromJson({
          ...validJson(),
          'weekdays': ['1'],
        }),
        throwsFormatException,
      );
    });

    test('範囲外の値は FormatException へ変換', () {
      expect(
        () => ElectionReminderSettings.fromJson({
          ...validJson(),
          'hour': 25,
        }),
        throwsFormatException,
      );
    });

    test('不明な enabledKinds 要素', () {
      expect(
        () => ElectionReminderSettings.fromJson({
          ...validJson(),
          'enabledKinds': ['unknown'],
        }),
        throwsFormatException,
      );
    });
  });

  group('等価性', () {
    test('同値なら == true・hashCode 同一', () {
      final a = ElectionReminderSettings(weekdays: [1, 2, 3]);
      final b = ElectionReminderSettings(weekdays: [1, 2, 3]);
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('weekdays が異なれば false', () {
      final a = ElectionReminderSettings(weekdays: [1, 2, 3]);
      final b = ElectionReminderSettings(weekdays: [1, 2, 4]);
      expect(a == b, isFalse);
    });

    test('enabledKinds が異なれば false', () {
      final a = ElectionReminderSettings.defaults();
      final b = a.copyWith(
        enabledKinds: {ElectionNotificationKind.turnProgress},
      );
      expect(a == b, isFalse);
    });
  });

  group('isKindEnabled / toggleKind', () {
    test('defaults は全種有効', () {
      final s = ElectionReminderSettings.defaults();
      for (final kind in ElectionNotificationKind.values) {
        expect(s.isKindEnabled(kind), isTrue);
      }
    });

    test('toggleKind で off→on のトグル', () {
      final base = ElectionReminderSettings.defaults();
      final off = base.toggleKind(ElectionNotificationKind.turnProgress);
      expect(off.isKindEnabled(ElectionNotificationKind.turnProgress), isFalse);
      final on = off.toggleKind(ElectionNotificationKind.turnProgress);
      expect(on.isKindEnabled(ElectionNotificationKind.turnProgress), isTrue);
    });

    test('toggleKind は元の設定を変更しない（不変）', () {
      final base = ElectionReminderSettings.defaults();
      base.toggleKind(ElectionNotificationKind.turnProgress);
      expect(base.isKindEnabled(ElectionNotificationKind.turnProgress), isTrue);
    });
  });
}
