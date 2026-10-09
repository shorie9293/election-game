import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/infrastructure/election_reminder_scheduler.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';

/// 呼び出しを記録するフェイクスケジューラ。
class FakeElectionReminderScheduler implements ElectionReminderScheduler {
  final List<String> calls = [];
  ElectionReminderSettings? lastApplied;

  @override
  Future<void> apply(ElectionReminderSettings s) async {
    calls.add('apply');
    lastApplied = s;
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
  }

  @override
  Future<void> sendTestNotification() async {
    calls.add('sendTestNotification');
  }
}

final DateTime _fixedNow = DateTime(2026, 10, 9, 9, 0);

Future<void> pumpScreen(
  WidgetTester tester, {
  InMemoryElectionReminderRepository? repository,
  FakeElectionReminderScheduler? scheduler,
}) async {
  // 全要素（保存ボタン等）が1画面に収まるよう縦長の大画面を想定する。
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ElectionReminderSettingsScreen(
        repository: repository ?? InMemoryElectionReminderRepository(),
        scheduler: scheduler ?? FakeElectionReminderScheduler(),
        now: () => _fixedNow,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('選挙リマインダー設定画面', () {
    testWidgets('既定ロード: スイッチ OFF・状態ラベルは「通知は無効です」', (tester) async {
      await pumpScreen(tester);

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(AppKeys.reminderEnabledSwitch),
      );
      expect(switchTile.value, isFalse);
      final label = tester.widget<Text>(
        find.byKey(AppKeys.reminderStatusLabel),
      );
      expect(label.data, '通知は無効です');
    });

    testWidgets('マスターSwitchの切替で状態ラベルが変わる', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.reminderEnabledSwitch));
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(
        find.byKey(AppKeys.reminderStatusLabel),
      );
      // 既定は毎日・20:00
      expect(label.data, '毎日 20:00');
    });

    testWidgets('時刻Dropdownの変更で timeLabel が更新される', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(AppKeys.reminderHourDropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.reminderMinuteDropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15').last);
      await tester.pumpAndSettle();

      expect(find.text('08:15'), findsOneWidget);
    });

    testWidgets('曜日チップのタップで選択が変わり、保存で repository に反映される', (tester) async {
      final repository = InMemoryElectionReminderRepository();
      await pumpScreen(tester, repository: repository);

      // 既定は月〜日全選択。土（6）をタップして解除する。
      await tester.tap(find.byKey(AppKeys.reminderWeekdayChip(6)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      final saved = await repository.load();
      expect(saved.weekdays, [1, 2, 3, 4, 5, 7]);
      expect(find.text('保存しました'), findsOneWidget);
    });

    testWidgets('保存ボタンで repository.save と scheduler.apply が呼ばれる', (tester) async {
      final repository = InMemoryElectionReminderRepository();
      final scheduler = FakeElectionReminderScheduler();
      await pumpScreen(tester, repository: repository, scheduler: scheduler);

      await tester.tap(find.byKey(AppKeys.reminderEnabledSwitch));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      expect(scheduler.calls, contains('apply'));
      expect(scheduler.lastApplied?.enabled, isTrue);
      final persisted = await repository.load();
      expect(persisted.enabled, isTrue);
    });

    testWidgets('テスト通知ボタンで scheduler.sendTestNotification が呼ばれる',
        (tester) async {
      final scheduler = FakeElectionReminderScheduler();
      await pumpScreen(tester, scheduler: scheduler);

      await tester.tap(find.byKey(AppKeys.reminderTestButton));
      await tester.pumpAndSettle();

      expect(scheduler.calls, contains('sendTestNotification'));
    });

    testWidgets('通知種類Switchのトグルが保存で反映される', (tester) async {
      final repository = InMemoryElectionReminderRepository();
      await pumpScreen(tester, repository: repository);

      await tester.tap(
        find.byKey(AppKeys.reminderKindSwitch('electionDay')),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      final saved = await repository.load();
      expect(
        saved.isKindEnabled(ElectionNotificationKind.electionDay),
        isFalse,
      );
      expect(
        saved.isKindEnabled(ElectionNotificationKind.turnProgress),
        isTrue,
      );
    });
  });
}
