import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/services/election_archive_service.dart';
import 'package:election_game/features/charts/presentation/election_chart_screen.dart';

/// 親探針（合成の不変条件）— 眷属の試練は個別操作しか撃たないため、
/// 「入力→ソート→画面→チャート」を貫く不変条件を親が独自に撃つ。

ElectionArchiveEntry _entry(
  String id, {
  required int winner,
  required int total,
  DateTime? at,
}) {
  return ElectionArchiveEntry(
    electionId: id,
    title: '選挙$id',
    scale: ElectionScale.town,
    winnerId: 'w$id',
    winnerName: '太郎$id',
    winnerVotes: winner,
    totalVotes: total,
    runnerUpVotes: total - winner,
    occurredAt: at,
  );
}

Election _election(String id, {required Map<String, int> votes}) {
  return Election(
    id: id,
    title: '生$id',
    scale: ElectionScale.town,
    candidates: const [
      Candidate(
        id: 'c1',
        name: '与党候補',
        portraitKey: 'p1',
        faction: '与党',
        personality: '穏健',
        policies: [],
      ),
      Candidate(
        id: 'c2',
        name: '野党候補',
        portraitKey: 'p2',
        faction: '野党',
        personality: '激昂',
        policies: [],
      ),
    ],
    voteCounts: votes,
    winnerId: 'c1',
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(MaterialApp(home: child));
  await tester.pumpAndSettle();
}

LineChart _shareChart(WidgetTester tester) => tester.widget<LineChart>(
      find.descendant(
        of: find.byKey(AppKeys.chartShareTrend),
        matching: find.byType(LineChart),
      ),
    );

void main() {
  testWidgets('探針1: 入力が時刻逆順でもチャートは時系列順に貫通する', (tester) async {
    // 第1回(40%)が最古・第3回(80%)が最新。入力を逆順で与える。
    final entries = [
      _entry('election_3', winner: 80, total: 100, at: DateTime(2026, 3, 1)),
      _entry('election_1', winner: 40, total: 100, at: DateTime(2026, 1, 1)),
      _entry('election_2', winner: 60, total: 100, at: DateTime(2026, 2, 1)),
    ];
    await _pump(tester, ElectionChartScreen(entries: entries));

    final spots = _shareChart(tester).data.lineBarsData.first.spots;
    expect(spots.length, 3);
    // X は 1,2,3 の昇順
    expect(spots.map((s) => s.x).toList(), [1, 2, 3]);
    // Y は時系列順の得票率（最古40 → 60 → 最新80）
    expect(spots.map((s) => s.y).toList(), [40, 60, 80]);
    // ラベルも第1回が最古に対応
    expect(find.text('第1回'), findsWidgets);
    expect(find.textContaining('最高: 第3回 80.0%'), findsOneWidget);
  });

  testWidgets('探針2: 比較バーの本数は選択件数と一致する', (tester) async {
    final entries = [
      _entry('election_1', winner: 40, total: 100, at: DateTime(2026, 1, 1)),
      _entry('election_2', winner: 60, total: 100, at: DateTime(2026, 2, 1)),
      _entry('election_3', winner: 80, total: 100, at: DateTime(2026, 3, 1)),
    ];
    await _pump(tester, ElectionChartScreen(entries: entries));

    // 初期は全件選択（3件以下）→ バー3本
    var chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.length, 3);

    // 1件解除 → 2本
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_2')));
    await tester.pumpAndSettle();
    chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.length, 2);

    // 全解除 → バー無し＆案内文
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_3')));
    await tester.pumpAndSettle();
    expect(find.byType(BarChart), findsNothing);
    expect(find.byKey(AppKeys.chartCompareHint), findsOneWidget);

    // 再選択 → 1本（状態と表示の往復整合）
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_1')));
    await tester.pumpAndSettle();
    chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.barGroups.length, 1);
    expect(chart.data.barGroups.first.barRods.first.toY, 40);
  });

  testWidgets('探針3: 政党別チャートは各選挙でシェア合計が100%（100%積み上げの整合）',
      (tester) async {
    // 実運用と同じ合成: 生選挙 → ElectionArchiveService.build → entries
    final elections = [
      _election('election_1000', votes: {'c1': 70, 'c2': 30}),
      _election('election_2000', votes: {'c1': 50, 'c2': 50}),
    ];
    final entries = ElectionArchiveService.build(elections);
    await _pump(
      tester,
      ElectionChartScreen(entries: entries, rawElections: elections),
    );

    final party = tester.widget<LineChart>(
      find.descendant(
        of: find.byKey(AppKeys.chartPartyTrend),
        matching: find.byType(LineChart),
      ),
    );
    final lines = party.data.lineBarsData;
    expect(lines.length, 2); // 与党・野党
    for (var j = 0; j < 2; j++) {
      final sum = lines.fold<double>(
        0,
        (acc, l) => acc + l.spots[j].y, // y は % 表示
      );
      expect(sum, closeTo(100, 1e-9));
    }
    // 選挙順（id のミリ秒昇順）と points 順が一致している
    expect(_shareChart(tester).data.lineBarsData.first.spots.first.y, 70);
  });

  testWidgets('探針4: 空→データへの widget 差し替えで State が陳腐化しない', (tester) async {
    await _pump(tester, const ElectionChartScreen(entries: []));
    expect(find.byKey(AppKeys.chartEmptyState), findsOneWidget);

    // 同一位置の State を再利用させたまま実データへ差し替える
    await tester.pumpWidget(
      MaterialApp(
        home: ElectionChartScreen(
          entries: [
            _entry('election_1', winner: 30, total: 100, at: DateTime(2026, 1, 1)),
            _entry('election_2', winner: 90, total: 100, at: DateTime(2026, 2, 1)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(AppKeys.chartEmptyState), findsNothing);
    expect(find.text('総選挙数: 2回'), findsOneWidget);
    expect(find.textContaining('最高: 第2回 90.0%'), findsOneWidget);
    // 初期選択も新しいデータで張り直される
    final chip = tester.widget<FilterChip>(
      find.byKey(AppKeys.chartPointChip('election_2')),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('探針5: どのチャートも描画値が 0〜100% の範囲を出ない', (tester) async {
    // 極端値（0%, 100%）を含む
    final entries = [
      _entry('election_1', winner: 0, total: 100, at: DateTime(2026, 1, 1)),
      _entry('election_2', winner: 100, total: 100, at: DateTime(2026, 2, 1)),
      _entry('election_x', winner: 5, total: 0, at: null), // 0除算ガード
    ];
    final elections = [
      _election('election_1000', votes: {'c1': 100, 'c2': 0}),
      _election('election_2000', votes: {}),
    ];
    await _pump(
      tester,
      ElectionChartScreen(entries: entries, rawElections: elections),
    );

    for (final s in _shareChart(tester).data.lineBarsData.first.spots) {
      expect(s.y, inInclusiveRange(0, 100));
    }
    for (final group in tester.widget<BarChart>(find.byType(BarChart)).data.barGroups) {
      for (final rod in group.barRods) {
        expect(rod.toY, inInclusiveRange(0, 100));
      }
    }
    expect(tester.takeException(), isNull);
  });
}
