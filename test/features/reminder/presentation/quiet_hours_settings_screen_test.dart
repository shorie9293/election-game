import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';
import 'package:election_game/features/reminder/presentation/quiet_hours_settings_screen.dart';

/// 深夜（静穏時間内）の固定時刻。TZ=UTC / 十分過去。
final DateTime _lateNight = DateTime.utc(2021, 3, 1, 23, 30);

Future<void> pumpQuietHours(
  WidgetTester tester, {
  InMemoryQuietHoursRepository? repository,
  DateTime? now,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: QuietHoursSettingsScreen(
        repository: repository ?? InMemoryQuietHoursRepository(),
        now: () => now ?? _lateNight,
      ),
    ),
  );
  // 不確定アニメーションを避け、明示的な pump でロードを完了させる。
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('静穏時間設定画面', () {
    testWidgets('既定: トグルOFF・時刻入力は非表示・抑止なしの説明', (tester) async {
      await pumpQuietHours(tester);

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(AppKeys.quietHoursEnabledSwitch),
      );
      expect(toggle.value, isFalse);
      expect(find.byKey(AppKeys.quietHoursStartHourDropdown), findsNothing);
      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '静穏時間は無効です');
    });

    testWidgets('有効化すると時刻入力が現れ、繰延の説明が出る', (tester) async {
      await pumpQuietHours(tester);

      await tester.tap(find.byKey(AppKeys.quietHoursEnabledSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(AppKeys.quietHoursStartHourDropdown), findsOneWidget);
      expect(find.byKey(AppKeys.quietHoursEndMinuteDropdown), findsOneWidget);
      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '22:00〜07:00 の通知は翌朝 07:00 に繰り延べます');
      final status = tester.widget<Text>(find.byKey(AppKeys.quietHoursStatus));
      expect(status.data, 'ただいま静穏時間内です');
    });

    testWidgets('policy を skip にすると説明が「通知は行いません」へ変わる', (tester) async {
      final repository = InMemoryQuietHoursRepository(
        QuietHoursSettings(enabled: true),
      );
      await pumpQuietHours(tester, repository: repository);

      await tester.tap(
        find.byKey(AppKeys.quietHoursPolicyRadio(QuietHoursPolicy.skip.storageKey)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '22:00〜07:00 の通知は行いません');
    });

    testWidgets('開始==終了では「抑止されません」と表示し、静穏時間内表示を出さない',
        (tester) async {
      final repository = InMemoryQuietHoursRepository(
        QuietHoursSettings(enabled: true, startHour: 23, endHour: 23),
      );
      await pumpQuietHours(tester, repository: repository);

      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '開始と終了が同じため通知は抑止されません');
      expect(find.byKey(AppKeys.quietHoursStatus), findsNothing);
    });

    testWidgets('開始時刻の変更と保存がリポジトリへ反映され、再読込でも保持される',
        (tester) async {
      final repository = InMemoryQuietHoursRepository();
      await pumpQuietHours(tester, repository: repository);

      await tester.tap(find.byKey(AppKeys.quietHoursEnabledSwitch));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.byKey(AppKeys.quietHoursStartHourDropdown));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('21時').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(AppKeys.quietHoursSaveButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final saved = await repository.load();
      expect(saved.enabled, isTrue);
      expect(saved.startHour, 21);
      expect(repository.saveCount, 1);
      expect(find.text('静穏時間を保存しました'), findsOneWidget);

      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '21:00〜07:00 の通知は翌朝 07:00 に繰り延べます');
    });

    testWidgets('保存済み設定が別インスタンスの画面で復元される', (tester) async {
      final repository = InMemoryQuietHoursRepository(
        QuietHoursSettings(
          enabled: true,
          startHour: 1,
          startMinute: 30,
          endHour: 5,
          endMinute: 15,
          policy: QuietHoursPolicy.skip,
        ),
      );
      await pumpQuietHours(tester, repository: repository, now: DateTime.utc(2021, 3, 1, 12));

      final toggle = tester.widget<SwitchListTile>(
        find.byKey(AppKeys.quietHoursEnabledSwitch),
      );
      expect(toggle.value, isTrue);
      final preview = tester.widget<Text>(find.byKey(AppKeys.quietHoursPreview));
      expect(preview.data, '01:30〜05:15 の通知は行いません');
      expect(find.byKey(AppKeys.quietHoursStatus), findsOneWidget);
      final status = tester.widget<Text>(find.byKey(AppKeys.quietHoursStatus));
      expect(status.data, 'ただいま静穏時間外です');
    });
  });
}
