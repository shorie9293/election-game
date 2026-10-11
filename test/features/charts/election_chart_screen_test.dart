import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/features/charts/presentation/election_chart_screen.dart';

/// 検証用エントリを構築する（winnerShare = winner/total が 0..1 に収まる）。
ElectionArchiveEntry _entry(
  String id, {
  required int winner,
  required int total,
  required int runner,
  DateTime? at,
  String winnerName = '太郎',
}) {
  return ElectionArchiveEntry(
    electionId: id,
    title: '選挙$id',
    scale: ElectionScale.town,
    winnerId: 'w$id',
    winnerName: winnerName,
    winnerVotes: winner,
    totalVotes: total,
    runnerUpVotes: runner,
    occurredAt: at,
  );
}

/// 検証用の生選挙（政党別シェア計算に使う voteCounts 付き）。
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

/// 2選挙の標準フィクスチャ（得票率 60% → 70%）。
List<ElectionArchiveEntry> _entries() => [
      _entry('election_1',
          winner: 60, total: 100, runner: 40, at: DateTime(2026, 1, 1)),
      _entry('election_2',
          winner: 70, total: 100, runner: 30, at: DateTime(2026, 2, 1)),
    ];

/// 与党70/野党30 の生選挙2回分。
List<Election> _rawElections() => [
      _election('election_1', votes: {'c1': 70, 'c2': 30}),
      _election('election_2', votes: {'c1': 50, 'c2': 50}),
    ];

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: child),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('① entries空なら空状態を表示する', (tester) async {
    await _pump(tester, const ElectionChartScreen(entries: []));
    expect(find.byKey(AppKeys.chartEmptyState), findsOneWidget);
    expect(find.text('まだ選挙の記録がありません'), findsOneWidget);
    expect(find.byKey(AppKeys.chartSummaryCard), findsNothing);
  });

  testWidgets('② サマリーに総選挙数が表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.text('総選挙数: 2回'), findsOneWidget);
  });

  testWidgets('③ サマリーに平均当選得票率が正しく表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.text('平均当選得票率: 65.0%'), findsOneWidget);
  });

  testWidgets('④ サマリーに得票率変化ラベルが正しく表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.text('得票率変化: +10.0pt'), findsOneWidget);
  });

  testWidgets('⑤ サマリーに最高・最低の点が表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.textContaining('最高: 第2回 70.0%'), findsOneWidget);
    expect(find.textContaining('最低: 第1回 60.0%'), findsOneWidget);
  });

  testWidgets('⑥ 当選得票率の推移チャートがKeyで存在する', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.byKey(AppKeys.chartShareTrend), findsOneWidget);
  });

  testWidgets('⑦ 推移チャートにLineChartが描画される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(
      find.descendant(
        of: find.byKey(AppKeys.chartShareTrend),
        matching: find.byType(LineChart),
      ),
      findsOneWidget,
    );
  });

  testWidgets('⑧ 推移チャートにX軸ラベル（第N回）が表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.text('第1回'), findsWidgets);
    expect(find.text('第2回'), findsWidgets);
  });

  testWidgets('⑨ rawElections注入時に政党別セクションが表示される', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(entries: _entries(), rawElections: _rawElections()),
    );
    expect(find.byKey(AppKeys.chartPartyTrend), findsOneWidget);
  });

  testWidgets('⑩ 政党別凡例に行Key付きで列挙される', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(entries: _entries(), rawElections: _rawElections()),
    );
    expect(find.byKey(AppKeys.chartPartyRow('与党')), findsOneWidget);
    expect(find.byKey(AppKeys.chartPartyRow('野党')), findsOneWidget);
  });

  testWidgets('⑪ 凡例に最新シェアの百分率ラベルが表示される', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(entries: _entries(), rawElections: _rawElections()),
    );
    expect(find.textContaining('与党 50.0%'), findsOneWidget);
    expect(find.textContaining('野党 50.0%'), findsOneWidget);
  });

  testWidgets('⑫ rawElections無しでは政党別セクションが非表示', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.byKey(AppKeys.chartPartyTrend), findsNothing);
    expect(find.byKey(AppKeys.chartPartyRow('与党')), findsNothing);
  });

  testWidgets('⑬ 比較チップが時系列順に全件並ぶ', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.byKey(AppKeys.chartComparison), findsOneWidget);
    expect(find.byKey(AppKeys.chartPointChip('election_1')), findsOneWidget);
    expect(find.byKey(AppKeys.chartPointChip('election_2')), findsOneWidget);
  });

  testWidgets('⑭ チップの初期選択は直近min(6,N)件（全選択）', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    final chip1 =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_1')));
    final chip2 =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_2')));
    expect(chip1.selected, isTrue);
    expect(chip2.selected, isTrue);
  });

  testWidgets('⑮ 7件以上なら初期選択は直近6件のみ', (tester) async {
    final many = [
      for (var i = 1; i <= 7; i++)
        _entry('election_$i',
            winner: 60, total: 100, runner: 40, at: DateTime(2026, 1, i)),
    ];
    await _pump(tester, ElectionChartScreen(entries: many));
    final first =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_1')));
    final seventh =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_7')));
    expect(first.selected, isFalse);
    expect(seventh.selected, isTrue);
  });

  testWidgets('⑯ 全チップをOFFにすると案内文が表示されBarChartは消える', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_2')));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.chartCompareHint), findsOneWidget);
    expect(find.text('比較する選挙を選んでください'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);
  });

  testWidgets('⑰ 1件以上選択するとBarChartが表示される', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_1')));
    await tester.pumpAndSettle();
    expect(find.byKey(AppKeys.chartCompareHint), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('⑱ チップのON/OFFトグルで選択状態が正しく切替わる', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    // 初期は全選択 → election_1 をOFF、election_2 を一度OFFして再度ON。
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.chartPointChip('election_2')));
    await tester.pumpAndSettle();
    final chip1 =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_1')));
    final chip2 =
        tester.widget<FilterChip>(find.byKey(AppKeys.chartPointChip('election_2')));
    expect(chip1.selected, isFalse);
    expect(chip2.selected, isTrue);
    // 選択1件 → hint無し・BarChart有り（points順は選択順に依存しない）。
    expect(find.byKey(AppKeys.chartCompareHint), findsNothing);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('⑲ 構築時にArgumentErrorを投げない', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(entries: _entries(), rawElections: _rawElections()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('⑳ 空でない場合AppBarに画面Keyが付く', (tester) async {
    await _pump(tester, ElectionChartScreen(entries: _entries()));
    expect(find.byKey(AppKeys.chartScreen), findsOneWidget);
    expect(find.text('選挙グラフ分析'), findsOneWidget);
  });

  testWidgets('㉑ repository読込成功時に政党別セクションが出る', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(
        entries: _entries(),
        repository: _FakeRepository(_rawElections()),
      ),
    );
    expect(find.byKey(AppKeys.chartPartyTrend), findsOneWidget);
  });

  testWidgets('㉒ repository読込失敗時もentriesだけで描画できる', (tester) async {
    await _pump(
      tester,
      ElectionChartScreen(
        entries: _entries(),
        repository: _ThrowingRepository(),
      ),
    );
    expect(find.byKey(AppKeys.chartSummaryCard), findsOneWidget);
    expect(find.byKey(AppKeys.chartPartyTrend), findsNothing);
  });
}

class _FakeRepository implements ElectionArchiveRepository {
  final List<Election> elections;

  _FakeRepository(this.elections);

  @override
  Future<List<Election>> load() async => elections;

  @override
  Future<void> save(List<Election> elections) async {}

  @override
  Future<void> add(Election election) async {}
}

class _ThrowingRepository implements ElectionArchiveRepository {
  @override
  Future<List<Election>> load() async => throw StateError('load failed');

  @override
  Future<void> save(List<Election> elections) async {}

  @override
  Future<void> add(Election election) async {}
}
