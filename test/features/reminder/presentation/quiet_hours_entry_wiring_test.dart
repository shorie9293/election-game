import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';
import 'package:election_game/features/reminder/infrastructure/election_reminder_scheduler.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';
import 'package:election_game/features/reminder/presentation/quiet_hours_settings_screen.dart';

class _FakeScheduler implements ElectionReminderScheduler {
  @override
  Future<void> apply(ElectionReminderSettings s) async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> sendTestNotification() async {}
}

final DateTime _fixedNow = DateTime.utc(2021, 3, 1, 9, 0);

Future<void> _pumpReminderSettings(
  WidgetTester tester, {
  QuietHoursRepository? quietHoursRepository,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ElectionReminderSettingsScreen(
        repository: InMemoryElectionReminderRepository(),
        scheduler: _FakeScheduler(),
        quietHoursRepository: quietHoursRepository,
        now: () => _fixedNow,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('通知設定 → 静穏時間設定の導線', () {
    testWidgets('リポジトリ未注入なら導線を出さない（既存画面を無破壊に保つ）',
        (tester) async {
      await _pumpReminderSettings(tester);

      expect(find.byKey(AppKeys.quietHoursEntry), findsNothing);
      expect(find.text('静穏時間（おやすみモード）'), findsNothing);
    });

    testWidgets('注入時は導線が出て、現在値の要約が表示される', (tester) async {
      final quiet = InMemoryQuietHoursRepository(
        QuietHoursSettings(enabled: true),
      );
      await _pumpReminderSettings(tester, quietHoursRepository: quiet);

      expect(find.byKey(AppKeys.quietHoursEntry), findsOneWidget);
      expect(find.text('22:00〜07:00・翌朝に繰り延べ'), findsOneWidget);
    });

    testWidgets('無効な静穏時間は「無効」と要約される', (tester) async {
      await _pumpReminderSettings(
        tester,
        quietHoursRepository: InMemoryQuietHoursRepository(),
      );

      expect(find.byKey(AppKeys.quietHoursEntry), findsOneWidget);
      expect(find.text('無効'), findsOneWidget);
    });

    testWidgets('導線タップで静穏時間設定画面へ遷移し、戻ると要約が更新される',
        (tester) async {
      final quiet = InMemoryQuietHoursRepository();
      await _pumpReminderSettings(tester, quietHoursRepository: quiet);

      await tester.tap(find.byKey(AppKeys.quietHoursEntry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(QuietHoursSettingsScreen), findsOneWidget);
      expect(find.byKey(AppKeys.quietHoursEnabledSwitch), findsOneWidget);

      // 有効化して保存し、リポジトリ経由で要約へ反映されることを確認する。
      await tester.tap(find.byKey(AppKeys.quietHoursEnabledSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(AppKeys.quietHoursSaveButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect((await quiet.load()).enabled, isTrue);

      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(QuietHoursSettingsScreen), findsNothing);
      expect(find.text('22:00〜07:00・翌朝に繰り延べ'), findsOneWidget,
          reason: '保存した静穏時間設定が通知設定画面の要約へ反映されること');
    });
  });
}
