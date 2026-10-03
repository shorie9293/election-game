import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';
import 'package:election_game/features/prediction/presentation/prediction_screen.dart';

/// 親探針: 画面→リポジトリ→再表示の合成不変条件を撃つ。
/// 眷属の試練は個別操作（保存後の state、事前注入した予想の表示）のみで、
/// 「保存が永続化層に到達し、別の画面インスタンスで復元されるか」を撃たない。
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
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('P1: 画面Aで保存した予想が、別の画面インスタンス（同一repo）で復元される', (tester) async {
    final repo = InMemoryPredictionRepository();

    // 画面A: 予想して保存
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
      ),
    );
    await tester.tap(find.byKey(AppKeys.predictionCandidateOption('c_alpha')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(AppKeys.predictionSaveButton));
    await tester.pumpAndSettle();
    expect(repo.store.containsKey('election_1'), isTrue);

    // 画面B: 別インスタンス（同じrepo）＋完了済み選挙 → 答え合わせが出る
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        completedElection: _completedElection(),
        repository: repo,
      ),
    );
    expect(find.byKey(AppKeys.predictionOutcomeCard), findsOneWidget);
    // 保存した予想（当選者α太郎・得票率50%）が復元されている
    final winnerRadio = tester.widget<RadioListTile<String>>(
      find.byKey(AppKeys.predictionCandidateOption('c_alpha')),
    );
    expect(winnerRadio.groupValue, 'c_alpha');
    expect(find.text('予想得票率: 50%'), findsOneWidget);
    final badge = tester.widget<Text>(find.byKey(AppKeys.predictionWinnerHitBadge));
    expect(badge.data, '的中！'); // α太郎=当選者, share50 vs actual70 → error20 → score50+30=80
  });

  testWidgets('P2: 別electionIdの予想は答え合わせに流用されない（キー分離）', (tester) async {
    final repo = InMemoryPredictionRepository();
    // election_1 の予想だけ保存
    await repo.save(
      _p(electionId: 'election_1', winnerId: 'c_alpha', share: 60),
    );

    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_2',
        electionTitle: '別の選挙',
        candidates: _candidates(),
        completedElection: _completedElection(),
        repository: repo,
      ),
    );
    expect(find.byKey(AppKeys.predictionOutcomeCard), findsNothing);
  });
}

// NOTE: ElectionPrediction を直接使う
ElectionPrediction _p({
  required String electionId,
  required String winnerId,
  required int share,
}) {
  return ElectionPrediction(
    electionId: electionId,
    predictedWinnerId: winnerId,
    predictedShare: share,
    createdAt: 0,
  );
}
