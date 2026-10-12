import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';
import 'package:election_game/features/heatmap/presentation/play_activity_heatmap_screen.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // 固定現在時刻: 2026-10-13（火）12:00 ローカル
  final now = DateTime(2026, 10, 13, 12, 0, 0);

  Widget buildScreen({List<Election>? elections}) {
    return MaterialApp(
      home: PlayActivityHeatmapScreen(
        electionsOverride: elections,
        now: now,
      ),
    );
  }

  testWidgets('空入力で playHeatmapEmpty が表示される', (tester) async {
    await tester.pumpWidget(buildScreen(elections: const []));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(AppKeys.playHeatmapEmpty), findsOneWidget);
    expect(find.byKey(AppKeys.playHeatmapSummary), findsNothing);
  });

  testWidgets('非空で Summary/Grid/Legend が表示される', (tester) async {
    final millis = now.millisecondsSinceEpoch;
    final elections = [
      Election(
        id: 'election_$millis',
        title: 'テスト選挙',
        scale: ElectionScale.town,
        candidates: const [],
      ),
    ];
    await tester.pumpWidget(buildScreen(elections: elections));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(AppKeys.playHeatmapEmpty), findsNothing);
    expect(find.byKey(AppKeys.playHeatmapSummary), findsOneWidget);
    expect(find.byKey(AppKeys.playHeatmapGrid), findsOneWidget);
    expect(find.byKey(AppKeys.playHeatmapLegend), findsOneWidget);
  });

  testWidgets('特定日の回数がセルに反映される（3回→ level > 0 のセル）', (tester) async {
    // now 当日を3回（同日3選挙）
    final millis = now.millisecondsSinceEpoch;
    final elections = List.generate(3, (i) {
      return Election(
        id: 'election_${millis + i}',
        title: 'テスト選挙$i',
        scale: ElectionScale.town,
        candidates: const [],
      );
    });
    await tester.pumpWidget(buildScreen(elections: elections));
    await tester.pump(const Duration(milliseconds: 100));

    final dateKey = PlayActivityHeatmapService.dateKey(now);
    final cell = find.byKey(AppKeys.playHeatmapCell(dateKey));
    expect(cell, findsOneWidget);

    // levelOf(3, 3) == 4（最大濃淡）なので、そのセルに Tooltip 付き
    // 'YYYY-MM-DD: 3回' が付く。
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: cell, matching: find.byType(Tooltip)).first,
    );
    expect(tooltip.message, '$dateKey: 3回');

    // サマリーにも回数が反映される
    expect(find.text('総選挙回数: 3回'), findsOneWidget);
    expect(find.text('最多日: $dateKey（3回）'), findsOneWidget);
  });

  testWidgets('homePlayHeatmapButton が存在し tooltip を持つ', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final citizen = Citizen(
      name: 'テスト太郎',
      job: Job.farmer,
      concerns: [Concern.agriculture],
      lifeParams: {
        'lifeCost': 50,
        'healthcare': 50,
        'education': 50,
        'employment': 50,
        'environment': 70,
        'safety': 50,
      },
    );
    final society = SocietyState(
      happiness: 65.0,
      mood: 0.4,
      electionCount: 2,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          citizen: citizen,
          societyState: society,
          remainingTurns: 5,
        ),
      ),
    );

    final button = find.byKey(AppKeys.homePlayHeatmapButton);
    expect(button, findsOneWidget);

    final iconButton = tester.widget<IconButton>(button);
    expect(iconButton.tooltip, '選挙プレイの歩み');

    // タップで PlayActivityHeatmapScreen へ遷移（repository 読込中でも
    // 型は即座に構築される）
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PlayActivityHeatmapScreen), findsOneWidget);
  });
}
