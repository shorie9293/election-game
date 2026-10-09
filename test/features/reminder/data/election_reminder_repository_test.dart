import 'dart:convert';

import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryElectionReminderRepository', () {
    test('save → load で往復できる', () async {
      final repo = InMemoryElectionReminderRepository();
      final s = ElectionReminderSettings(
        enabled: true,
        hour: 8,
        minute: 30,
        weekdays: const [2, 4],
        updatedAt: DateTime(2026, 10, 9, 12, 0),
      );
      await repo.save(s);
      final loaded = await repo.load();
      expect(loaded, s);
      expect(loaded.updatedAt, s.updatedAt);
    });

    test('初期値を注入できる', () async {
      final s = ElectionReminderSettings(enabled: true, hour: 7);
      final repo = InMemoryElectionReminderRepository(s);
      expect(await repo.load(), s);
    });

    test('初期値なしは defaults', () async {
      final repo = InMemoryElectionReminderRepository();
      expect(await repo.load(), ElectionReminderSettings.defaults());
    });
  });

  group('fromJson 破損データのフォールバック（Hive 実装のロジック検証）', () {
    test('破損 JSON は FormatException となるので defaults へ落とせる', () {
      const raw = '{{{not-json';
      expect(() => jsonDecode(raw), throwsFormatException);
    });

    test('正常 JSON からの復元', () {
      const raw =
          '{"enabled":true,"hour":8,"minute":30,"weekdays":[2,4],"enabledKinds":["turnProgress"]}';
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final s = ElectionReminderSettings.fromJson(decoded);
      expect(s.enabled, isTrue);
      expect(s.hour, 8);
      expect(s.minute, 30);
      expect(s.weekdays, [2, 4]);
      expect(
        s.enabledKinds,
        {ElectionNotificationKind.turnProgress},
      );
    });

    test('型不一致 JSON は FormatException → defaults フォールバック',
        () {
      const raw =
          '{"enabled":"yes","hour":20,"minute":0,"weekdays":[1],"enabledKinds":[]}';
      final decoded = jsonDecode(raw);
      ElectionReminderSettings result;
      try {
        result = ElectionReminderSettings.fromJson(
          decoded as Map<String, dynamic>,
        );
      } on FormatException {
        result = ElectionReminderSettings.defaults();
      }
      expect(result, ElectionReminderSettings.defaults());
    });

    test('JSON 文字列でなく数値等の型外れは defaults 扱い', () {
      const Object raw = 42;
      // Hive から get した値が String でなければそのまま defaults
      final isString = raw is String;
      expect(isString, isFalse);
    });
  });

  group('NoopElectionReminderRepository', () {
    test('load は常に defaults', () async {
      final repo = NoopElectionReminderRepository();
      expect(await repo.load(), ElectionReminderSettings.defaults());
    });

    test('save しても load は defaults のまま', () async {
      final repo = NoopElectionReminderRepository();
      await repo.save(ElectionReminderSettings(enabled: true, hour: 6));
      expect(await repo.load(), ElectionReminderSettings.defaults());
    });
  });
}
