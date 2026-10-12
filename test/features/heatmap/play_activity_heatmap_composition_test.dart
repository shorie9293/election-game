import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';
import 'package:election_game/features/heatmap/presentation/play_activity_heatmap_screen.dart';

/// 親探針：眷属が個別に撃たない「画面→サービス→表示」の合成不変条件と
/// スケーリング境界を撃つ。実バグの検出と健全性の確証を兼ねる。
void main() {
  // 固定現在時刻: 2026-10-13（火）12:00 ローカル
  final now = DateTime(2026, 10, 13, 12, 0, 0);

  Election electionAt(DateTime local) {
    final utcMillis = local.toUtc().millisecondsSinceEpoch;
    return Election(
      id: 'election_$utcMillis',
      title: 'テスト選挙',
      scale: ElectionScale.town,
      candidates: const [],
    );
  }

  List<Election> sampleElections() {
    return [
      // 2026-10-11: 3回
      electionAt(DateTime(2026, 10, 11, 9, 0)),
      electionAt(DateTime(2026, 10, 11, 12, 0)),
      electionAt(DateTime(2026, 10, 11, 18, 0)),
      // 2026-10-12: 1回
      electionAt(DateTime(2026, 10, 12, 10, 0)),
      // 2026-10-13(now当日): 2回
      electionAt(DateTime(2026, 10, 13, 8, 0)),
      electionAt(DateTime(2026, 10, 13, 11, 0)),
    ];
  }

  Widget buildScreen(List<Election> elections) {
    return MaterialApp(
      home: PlayActivityHeatmapScreen(
        electionsOverride: elections,
        now: now,
      ),
    );
  }

  testWidgets('合成: 画面のサマリー値がサービスの集計値と一致する', (tester) async {
    final elections = sampleElections();
    final hm = PlayActivityHeatmapService.build(elections, now: now);

    // サービスの意味論を先に固定（期待値の独立計算）
    expect(hm.totalElections, 6);
    expect(hm.activeDays, 3);
    expect(hm.currentStreak, 3); // 11,12,13 が連続
    expect(hm.longestStreak, 3);

    await tester.pumpWidget(buildScreen(elections));
    await tester.pump(const Duration(milliseconds: 100));

    // 画面表示がサービス値と一致する（画面が別ソースを読んでいないか撃つ）
    expect(find.text('総選挙回数: ${hm.totalElections}回'), findsOneWidget);
    expect(find.text('活動日数: ${hm.activeDays}日'), findsOneWidget);
    expect(find.text('最長連続: ${hm.longestStreak}日'), findsOneWidget);
    expect(find.text('最多日: 2026-10-11（3回）'), findsOneWidget);

    // 3つの活動日のセルが存在し、Tooltip が回数と一致する
    for (final entry in {
      '2026-10-11': 3,
      '2026-10-12': 1,
      '2026-10-13': 2,
    }.entries) {
      final cell = find.byKey(AppKeys.playHeatmapCell(entry.key));
      expect(cell, findsOneWidget, reason: 'cell ${entry.key}');
      final tooltip = tester.widget<Tooltip>(
        find.ancestor(of: cell, matching: find.byType(Tooltip)).first,
      );
      expect(tooltip.message, '${entry.key}: ${entry.value}回');
    }
  });

  testWidgets('グリッドのセル数は weeks*7 で、日付キーが重複しない', (tester) async {
    await tester.pumpWidget(buildScreen(sampleElections()));
    await tester.pump(const Duration(milliseconds: 100));

    final grid = find.byKey(AppKeys.playHeatmapGrid);
    expect(grid, findsOneWidget);

    final cells = find.descendant(of: grid, matching: find.byType(Tooltip));
    // 既定 weeks=26 → 182 セル
    expect(cells.evaluate().length, 26 * 7);

    // 総セル数 = weeks*7 が Tooltip のメッセージ重複なしで成立すること
    final messages = cells
        .evaluate()
        .map((e) => (e.widget as Tooltip).message)
        .toList();
    expect(messages.toSet().length, messages.length);
  });

  testWidgets('スケーリング境界: 最大5回のとき1回の日は最小レベル（最大に塗られない）', (tester) async {
    // 1日だけ5回、他は1回 → levelOf(1,5) は 1（最大4にしない）
    expect(PlayActivityHeatmapService.levelOf(1, 5), 1);
    expect(PlayActivityHeatmapService.levelOf(5, 5), 4);
    expect(PlayActivityHeatmapService.levelOf(0, 5), 0);

    final elections = <Election>[
      for (var i = 0; i < 5; i++) electionAt(DateTime(2026, 10, 11, 9 + i)),
      electionAt(DateTime(2026, 10, 12, 10)),
    ];
    await tester.pumpWidget(buildScreen(elections));
    await tester.pump(const Duration(milliseconds: 100));

    final maxCell = find.byKey(AppKeys.playHeatmapCell('2026-10-11'));
    final oneCell = find.byKey(AppKeys.playHeatmapCell('2026-10-12'));
    expect(maxCell, findsOneWidget);
    expect(oneCell, findsOneWidget);

    // セルの色が同一でない（1回の日が最大濃淡に塗られていないこと）
    // キーはセルの Container 自体に付くため、byKey から直接 widget を取る。
    final maxColor = (tester.widget<Container>(maxCell).decoration)
        as BoxDecoration;
    final oneColor = (tester.widget<Container>(oneCell).decoration)
        as BoxDecoration;
    expect(oneColor.color, isNot(equals(maxColor.color)));
  });

  testWidgets('負の対照: 空入力ではサマリー/グリッドを出さない', (tester) async {
    await tester.pumpWidget(buildScreen(const []));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(AppKeys.playHeatmapEmpty), findsOneWidget);
    expect(find.byKey(AppKeys.playHeatmapSummary), findsNothing);
    expect(find.byKey(AppKeys.playHeatmapGrid), findsNothing);
    expect(find.byKey(AppKeys.playHeatmapLegend), findsNothing);
  });
}
