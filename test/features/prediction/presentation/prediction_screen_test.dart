import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';
import 'package:election_game/features/prediction/presentation/prediction_screen.dart';

List<Candidate> _candidates() => const [
      Candidate(
        id: 'c_alpha',
        name: 'α太郎',
        portraitKey: 'p_alpha',
        faction: '発展の会',
        personality: '経済重視',
        policies: [],
      ),
      Candidate(
        id: 'c_beta',
        name: 'β花子',
        portraitKey: 'p_beta',
        faction: '共生の会',
        personality: '福祉重視',
        policies: [],
      ),
    ];

Election _completedElection() => Election(
      id: 'election_1',
      title: 'テスト選挙',
      scale: ElectionScale.town,
      candidates: _candidates(),
      voteCounts: const {'c_alpha': 70, 'c_beta': 30},
      winnerId: 'c_alpha',
    );

Future<void> _pump(WidgetTester tester, PredictionScreen screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  // initState の repository.load() を待つ
  await tester.pumpAndSettle();
}

void main() {
  final candidates = _candidates();

  testWidgets('候補者名が表示される', (tester) async {
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        repository: InMemoryPredictionRepository(),
      ),
    );

    expect(find.text('α太郎'), findsOneWidget);
    expect(find.text('β花子'), findsOneWidget);
    expect(find.byKey(AppKeys.predictionTitle), findsOneWidget);
  });

  testWidgets('未選択で保存すると SnackBar が出て store は空のまま', (tester) async {
    final repo = InMemoryPredictionRepository();
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        repository: repo,
      ),
    );

    await tester.tap(find.byKey(AppKeys.predictionSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('当選者を選んでください'), findsOneWidget);
    expect(repo.store, isEmpty);
  });

  testWidgets('候補者選択・スライダー調整・保存が正しく行われる', (tester) async {
    final repo = InMemoryPredictionRepository();
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        repository: repo,
      ),
    );

    await tester.tap(find.byKey(AppKeys.predictionCandidateOption('c_beta')));
    await tester.pumpAndSettle();

    // スライダー: 予想得票率を 40 に設定（min=1, max=100, divisions=99）
    // Material Slider のトラックは両端にサム半径(24)ぶんの余白があるため補正する。
    const wantShare = 40;
    const thumbRadius = 24.0;
    final track = tester.getRect(find.byKey(AppKeys.predictionShareSlider));
    final fraction = (wantShare - 1) / 99;
    final effectiveWidth = track.width - thumbRadius * 2;
    await tester.tapAt(
      Offset(
        track.left + thumbRadius + fraction * effectiveWidth,
        track.center.dy,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('予想得票率: $wantShare%'), findsOneWidget);

    await tester.tap(find.byKey(AppKeys.predictionSaveButton));
    await tester.pumpAndSettle();

    expect(find.text('予想を保存しました'), findsOneWidget);
    final saved = repo.store['election_1'];
    expect(saved, isNotNull);
    expect(saved!.predictedWinnerId, 'c_beta');
    expect(saved.predictedShare, wantShare);
  });

  testWidgets('完了済み選挙と保存済み予想で答え合わせが表示される', (tester) async {
    final prediction = ElectionPrediction(
      electionId: 'election_1',
      predictedWinnerId: 'c_alpha',
      predictedShare: 65,
      createdAt: 0,
    );
    final repo = InMemoryPredictionRepository({'election_1': prediction});
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        completedElection: _completedElection(),
        repository: repo,
      ),
    );

    expect(find.byKey(AppKeys.predictionOutcomeCard), findsOneWidget);
    // 的中: winner=c_alpha, share=70 → error=5, score=50+45=95 → 完璧
    final card = find.byKey(AppKeys.predictionOutcomeCard);
    expect(
      find.descendant(
        of: card,
        matching: find.byKey(AppKeys.predictionWinnerHitBadge),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('的中！'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('得票率の誤差: 5pt'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('スコア: 95 / 100'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('完璧'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text('当選者: α太郎'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('completedElection が null なら答え合わせカードは出ない', (tester) async {
    final prediction = ElectionPrediction(
      electionId: 'election_1',
      predictedWinnerId: 'c_alpha',
      predictedShare: 50,
      createdAt: 0,
    );
    final repo = InMemoryPredictionRepository({'election_1': prediction});
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        repository: repo,
      ),
    );

    expect(find.byKey(AppKeys.predictionOutcomeCard), findsNothing);
  });

  testWidgets('外れの予想では「外れ」バッジが表示される', (tester) async {
    final prediction = ElectionPrediction(
      electionId: 'election_1',
      predictedWinnerId: 'c_beta',
      predictedShare: 20,
      createdAt: 0,
    );
    final repo = InMemoryPredictionRepository({'election_1': prediction});
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: candidates,
        completedElection: _completedElection(),
        repository: repo,
      ),
    );

    final card = find.byKey(AppKeys.predictionOutcomeCard);
    // バッジ（winnerHit）は「外れ」、accuracyLabel も「外れ」（score=0）
    final badgeText =
        tester.widget<Text>(find.byKey(AppKeys.predictionWinnerHitBadge));
    expect(badgeText.data, '外れ');
    expect(
      find.descendant(
        of: card,
        matching: find.byKey(AppKeys.predictionAccuracyLabel),
      ),
      findsOneWidget,
    );
    // winner=c_alpha share=70 → error=|20-70|=50, score=0+0 → 外れ
    expect(
      find.descendant(of: card, matching: find.text('得票率の誤差: 50pt')),
      findsOneWidget,
    );
  });
}
