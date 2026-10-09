import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/features/reminder/presentation/election_reminder_settings_screen.dart';
import 'package:hive/hive.dart';

void main() {
  group('ホームから選挙リマインダー設定画面への導線', () {
    testWidgets('AppBar の導線をタップすると通知設定画面へ遷移する', (tester) async {
      final tempDir =
          Directory.systemTemp.createTempSync('reminder_wiring_hive');
      Hive.init(tempDir.path);
      addTearDown(() {
        try {
          Hive.deleteBoxFromDisk('election_reminder_box');
        } catch (_) {}
        tempDir.deleteSync(recursive: true);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            citizen: Citizen.initial(Job.farmer),
            societyState: SocietyState.initial(),
            remainingTurns: 10,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(AppKeys.homeReminderButton));
      await tester.pump();
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // 同一キーが Widget と Scaffold の両方に付くため 2 件ヒットする。
      expect(
        find.byKey(AppKeys.reminderSettingsScreen),
        findsWidgets,
      );
      expect(
        find.byType(ElectionReminderSettingsScreen),
        findsOneWidget,
      );
    });
  });
}
