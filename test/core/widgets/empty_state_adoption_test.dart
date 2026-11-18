// 空状態の共通部品（EmptyStateView）普及の試練。
//
// 0件データのとき、各画面が生 Text ではなく EmptyStateView を1つだけ描くこと、
// および旧来の Key・文言（一字も変えない）がそのまま残っていることを検める。
// 行動導線を持たない画面では行動ボタン（Semantics id 'btn_empty_state_action'）
// を差し出さないことも併せて確認する。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/crash/crash_log_repository.dart';
import 'package:election_game/core/crash/crash_log_screen.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/widgets/empty_state.dart';
import 'package:election_game/features/archive/presentation/election_archive_screen.dart';
import 'package:election_game/features/charts/presentation/election_chart_screen.dart';
import 'package:election_game/features/heatmap/presentation/play_activity_heatmap_screen.dart';
import 'package:election_game/features/lifetrend/presentation/life_param_trend_screen.dart';
import 'package:election_game/features/manifesto/presentation/manifesto_tracker_screen.dart';
import 'package:election_game/features/recap/presentation/election_recap_screen.dart';
import 'package:election_game/features/share/presentation/election_share_card_screen.dart';

const String _actionSemanticsId = 'btn_empty_state_action';
const Key _actionButtonKey = ValueKey('empty_state_action_button');

/// 画面を0件データで描き、検証本体 [body] を実行する。
///
/// - 縦長画面でも空状態が遅延描画外へ押し出されないようビューポートを広げる。
/// - bySemanticsIdentifier を使うため semantics を有効化し、必ず破棄する
///   （破棄はテスト本体の中で行う。tearDown では検証に間に合わない）。
Future<void> _pumpScreen(
  WidgetTester tester,
  Widget screen,
  Future<void> Function() body,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final handle = tester.ensureSemantics();
  try {
    await tester.pumpWidget(MaterialApp(home: screen));
    await tester.pumpAndSettle();
    await body();
  } finally {
    handle.dispose();
  }
}

/// 行動導線を持たない画面であることの確認（ボタンを発明していない）。
void _expectNoAction() {
  expect(find.bySemanticsIdentifier(_actionSemanticsId), findsNothing);
  expect(find.byKey(_actionButtonKey), findsNothing);
}

void main() {
  testWidgets('選挙アーカイブ: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      const ElectionArchiveScreen(entries: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.archiveEmptyState), findsOneWidget);
        expect(find.text('まだ選挙の記録がありません'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('選挙の振り返り: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      const ElectionRecapScreen(entries: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.recapEmptyState), findsOneWidget);
        expect(find.text('振り返る選挙がありません'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('公約実現度: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      const ManifestoTrackerScreen(records: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.manifestoEmptyState), findsOneWidget);
        expect(find.text('まだ公約実現度の記録がありません'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('シェアカード: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      const ElectionShareCardScreen(entries: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.shareCardEmpty), findsOneWidget);
        expect(find.text('共有できる選挙結果がありません'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('選挙グラフ分析: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      const ElectionChartScreen(entries: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.chartEmptyState), findsOneWidget);
        expect(find.text('まだ選挙の記録がありません'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('選挙プレイの歩み: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      PlayActivityHeatmapScreen(
        electionsOverride: const [],
        now: DateTime(2026, 10, 13, 12),
      ),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.playHeatmapEmpty), findsOneWidget);
        // 旧来の一文は見出しと説明へ振り分けた（文言は不変）。
        expect(find.text('まだ記録がありません。'), findsOneWidget);
        expect(find.text('選挙を重ねるとここに記録されます。'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('生活パラメータの推移: 0件で EmptyStateView を出す（行動導線なし）',
      (tester) async {
    await _pumpScreen(
      tester,
      const LifeParamTrendScreen(snapshotsOverride: []),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.lifeParamTrendEmpty), findsOneWidget);
        expect(find.text('まだ記録がありません。'), findsOneWidget);
        expect(find.text('選挙を終えると生活パラメータが記録されます。'), findsOneWidget);
        _expectNoAction();
      },
    );
  });

  testWidgets('不具合ログ: 0件で EmptyStateView を出す（行動導線なし）', (tester) async {
    await _pumpScreen(
      tester,
      CrashLogScreen(
        repository: InMemoryCrashLogRepository(),
        now: () => DateTime(2026, 11, 1, 12),
      ),
      () async {
        expect(find.byType(EmptyStateView), findsOneWidget);
        expect(find.byKey(AppKeys.crashLogEmptyState), findsOneWidget);
        expect(find.text('記録された不具合はありません'), findsOneWidget);
        expect(
          find.text('アプリが異常終了したり表示に失敗したりすると、その記録がこの端末内に残ります。'),
          findsOneWidget,
        );
        _expectNoAction();
      },
    );
  });
}
