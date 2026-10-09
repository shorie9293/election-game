import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:election_game/domain/services/life_param_trend_service.dart';
import 'package:election_game/features/lifetrend/presentation/life_param_trend_screen.dart';

LifeParamSnapshot _snapshot(String electionId, Map<String, int> values) {
  return LifeParamSnapshot(
    electionId: electionId,
    occurredAt: DateTime.utc(2026, 1, 1).add(const Duration(days: 30)),
    values: values,
  );
}

void main() {
  group('LifeParamTrendScreen', () {
    testWidgets('スナップショットが空のときは空状態を表示する', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeParamTrendScreen(
            key: AppKeys.lifeParamTrendScreen,
            snapshotsOverride: const [],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(AppKeys.lifeParamTrendEmpty), findsOneWidget);
      expect(find.text('生活パラメータの推移'), findsOneWidget);
    });

    testWidgets('利用可能なキーごとにチップが表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeParamTrendScreen(
            key: AppKeys.lifeParamTrendScreen,
            snapshotsOverride: [
              _snapshot('election_20260101_000000000', {
                'lifeCost': 50,
                'healthcare': 60,
              }),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(AppKeys.lifeParamTrendEmpty), findsNothing);
      expect(find.byKey(AppKeys.lifeParamTrendKeyChip('lifeCost')),
          findsOneWidget);
      expect(find.byKey(AppKeys.lifeParamTrendKeyChip('healthcare')),
          findsOneWidget);
    });

    testWidgets('既定シリーズの最新値が表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeParamTrendScreen(
            key: AppKeys.lifeParamTrendScreen,
            snapshotsOverride: [
              _snapshot('election_20260101_000000000', {
                'lifeCost': 50,
                'healthcare': 60,
              }),
              _snapshot('election_20260102_000000000', {
                'lifeCost': 55,
                'healthcare': 62,
              }),
            ],
          ),
        ),
      );
      await tester.pump();

      // 最初のシリーズ（lifeCost）が選択されている
      final latest = LifeParamTrendService.latestValue(
        [
          _snapshot('election_20260101_000000000', {
            'lifeCost': 50,
            'healthcare': 60,
          }),
          _snapshot('election_20260102_000000000', {
            'lifeCost': 55,
            'healthcare': 62,
          }),
        ],
        'lifeCost',
      );
      expect(find.byKey(AppKeys.lifeParamTrendLatest), findsOneWidget);
      expect(find.text('$latest'), findsOneWidget);
    });

    testWidgets('チップを選ぶとそのシリーズの最新値に切り替わる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeParamTrendScreen(
            key: AppKeys.lifeParamTrendScreen,
            snapshotsOverride: [
              _snapshot('election_20260101_000000000', {
                'lifeCost': 50,
                'healthcare': 60,
              }),
              _snapshot('election_20260102_000000000', {
                'lifeCost': 55,
                'healthcare': 72,
              }),
            ],
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(AppKeys.lifeParamTrendKeyChip('healthcare')));
      await tester.pump();

      expect(find.byKey(AppKeys.lifeParamTrendLatest), findsOneWidget);
      expect(find.text('72'), findsOneWidget);
    });

    testWidgets('スナップショット3件でバーが3本表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LifeParamTrendScreen(
            key: AppKeys.lifeParamTrendScreen,
            snapshotsOverride: [
              _snapshot('election_20260101_000000000', {'lifeCost': 50}),
              _snapshot('election_20260102_000000000', {'lifeCost': 55}),
              _snapshot('election_20260103_000000000', {'lifeCost': 60}),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(AppKeys.lifeParamTrendBar('election_20260101_000000000')),
        findsOneWidget,
      );
      expect(
        find.byKey(AppKeys.lifeParamTrendBar('election_20260102_000000000')),
        findsOneWidget,
      );
      expect(
        find.byKey(AppKeys.lifeParamTrendBar('election_20260103_000000000')),
        findsOneWidget,
      );
    });
  });
}