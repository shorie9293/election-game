import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/election_reminder_repository.dart';
import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:election_game/features/reminder/domain/election_reminder_schedule_service.dart';
import 'package:election_game/features/reminder/infrastructure/election_reminder_scheduler.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';

/// 親探針（合成の不変条件）。
///
/// 眷属は個別機能（スイッチ・保存・テスト通知）を撃つが、
/// 「画面→リポジトリ→再表示」の合成や「保存内容とスケジューラへ渡る内容の一致」
/// といった不変条件は撃たない。ここで親が独自に撃つ。
class _RecordingScheduler implements ElectionReminderScheduler {
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

Future<void> _pump(
  WidgetTester tester,
  InMemoryElectionReminderRepository repository,
  _RecordingScheduler scheduler,
) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: ElectionReminderSettingsScreen(
        repository: repository,
        scheduler: scheduler,
        now: () => _fixedNow,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('親探針: 通知設定の合成の不変条件', () {
    testWidgets('保存→別インスタンスの画面で復元される（画面→リポジトリ→再表示）',
        (tester) async {
      final repository = InMemoryElectionReminderRepository();
      final scheduler = _RecordingScheduler();

      await _pump(tester, repository, scheduler);
      await tester.tap(find.byKey(AppKeys.reminderEnabledSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      // 別インスタンスの画面（同一リポジトリ）で再表示する。
      await _pump(tester, repository, _RecordingScheduler());

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(AppKeys.reminderEnabledSwitch),
      );
      expect(switchTile.value, isTrue,
          reason: '保存された enabled=true が再表示で復元されること');
      final label = tester.widget<Text>(find.byKey(AppKeys.reminderStatusLabel));
      expect(label.data, '毎日 20:00');
    });

    testWidgets('scheduler へ渡る設定は repository に保存された設定と一致する',
        (tester) async {
      final repository = InMemoryElectionReminderRepository();
      final scheduler = _RecordingScheduler();

      await _pump(tester, repository, scheduler);
      await tester.tap(find.byKey(AppKeys.reminderEnabledSwitch));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.reminderHourDropdown));
      await tester.pumpAndSettle();
      await tester.tap(find.text('8').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      final persisted = await repository.load();
      expect(scheduler.lastApplied, isNotNull);
      expect(scheduler.lastApplied, equals(persisted),
          reason: '永続化された設定とスケジューラへ渡る設定は同一でなければならない');
      expect(persisted.hour, 8);
    });

    testWidgets('通知種類を全解除して保存しても空集合が保持される（不変条件）',
        (tester) async {
      final repository = InMemoryElectionReminderRepository();
      final scheduler = _RecordingScheduler();

      await _pump(tester, repository, scheduler);
      for (final kind in ElectionNotificationKind.values) {
        await tester.tap(find.byKey(AppKeys.reminderKindSwitch(kind.name)));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      final saved = await repository.load();
      expect(saved.enabledKinds, isEmpty,
          reason: '全解除が空集合として保持されること（既定へ勝手に戻らない）');
    });

    testWidgets('曜日を全解除して保存しても空リストが保持される', (tester) async {
      final repository = InMemoryElectionReminderRepository();
      final scheduler = _RecordingScheduler();

      await _pump(tester, repository, scheduler);
      for (var w = 1; w <= 7; w++) {
        await tester.tap(find.byKey(AppKeys.reminderWeekdayChip(w)));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(AppKeys.reminderSaveButton));
      await tester.pumpAndSettle();

      final saved = await repository.load();
      expect(saved.weekdays, isEmpty);
      // 曜日なしのときは次回発火が無い（純粋サービスとの合成）。
      const service = ElectionReminderScheduleService();
      expect(service.nextOccurrence(saved, _fixedNow), isNull);
    });
  });
}
