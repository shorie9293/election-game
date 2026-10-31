import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/load_state.dart';
import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/election_scale.dart';
import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';
import 'package:election_game/features/prediction/presentation/prediction_screen.dart';

const _errorViewKey = ValueKey('load_error_view');
const _retryButtonKey = ValueKey('load_retry_button');
const _emptyViewKey = ValueKey('load_empty_view');

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

ElectionPrediction _prediction() => ElectionPrediction(
      electionId: 'election_1',
      predictedWinnerId: 'c_alpha',
      predictedShare: 65,
      createdAt: 0,
    );

Election _completedElection() => Election(
      id: 'election_1',
      title: 'テスト選挙',
      scale: ElectionScale.town,
      candidates: _candidates(),
      voteCounts: const {'c_alpha': 70, 'c_beta': 30},
      winnerId: 'c_alpha',
    );

/// tryLoad の結果を順番に返し、呼び出し回数を数えるリポジトリ。
class _ScriptedRepository extends PredictionRepository {
  final List<LoadResult<ElectionPrediction?>> results;
  int calls = 0;

  _ScriptedRepository(this.results);

  @override
  Future<LoadResult<ElectionPrediction?>> tryLoad(String electionId) async {
    final index = calls < results.length ? calls : results.length - 1;
    calls++;
    return results[index];
  }

  @override
  Future<ElectionPrediction?> load(String electionId) async =>
      (await tryLoad(electionId)).valueOrNull;

  @override
  Future<void> save(ElectionPrediction prediction) async {}

  @override
  Future<void> remove(String electionId) async {}
}

Future<void> _pump(WidgetTester tester, PredictionScreen screen) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: screen));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('読み込み失敗では ErrorState が出て EmptyState は出ない', (tester) async {
    final repo = _ScriptedRepository([
      LoadResult<ElectionPrediction?>.failure('予想の読み込みに失敗しました'),
    ]);
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
      ),
    );

    expect(find.byKey(_errorViewKey), findsOneWidget);
    expect(find.byKey(_emptyViewKey), findsNothing);
    expect(find.text('予想の読み込みに失敗しました'), findsOneWidget);
    expect(find.byKey(_retryButtonKey), findsOneWidget);
  });

  testWidgets('0件では EmptyState が出て ErrorState は出ない', (tester) async {
    final repo = _ScriptedRepository([
      LoadResult<ElectionPrediction?>.success(null),
    ]);
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
      ),
    );

    expect(find.byKey(_emptyViewKey), findsOneWidget);
    expect(find.byKey(_errorViewKey), findsNothing);
    expect(find.byKey(_retryButtonKey), findsNothing);
    // 既存の空状態文言は不変
    expect(find.text('答え合わせはまだありません'), findsOneWidget);
  });

  testWidgets('再試行タップでロードが2回目実行され、成功で ErrorState が消える', (tester) async {
    final repo = _ScriptedRepository([
      LoadResult<ElectionPrediction?>.failure('予想の読み込みに失敗しました'),
      LoadResult<ElectionPrediction?>.success(_prediction()),
    ]);
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
        completedElection: _completedElection(),
      ),
    );

    expect(repo.calls, 1);
    expect(find.byKey(_errorViewKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(_retryButtonKey));
    await tester.tap(find.byKey(_retryButtonKey));
    await tester.pumpAndSettle();

    expect(repo.calls, 2);
    expect(find.byKey(_errorViewKey), findsNothing);
    expect(find.byKey(AppKeys.predictionOutcomeCard), findsOneWidget);
  });

  testWidgets('再試行不能な失敗では再試行ボタンを出さない', (tester) async {
    final repo = _ScriptedRepository([
      LoadResult<ElectionPrediction?>.failure('復元できません', retryable: false),
    ]);
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
      ),
    );

    expect(find.byKey(_errorViewKey), findsOneWidget);
    expect(find.byKey(_retryButtonKey), findsNothing);
  });

  testWidgets('成功時は ErrorState も EmptyState も出ず答え合わせカードが出る', (tester) async {
    final repo = _ScriptedRepository([
      LoadResult<ElectionPrediction?>.success(_prediction()),
    ]);
    await _pump(
      tester,
      PredictionScreen(
        electionId: 'election_1',
        electionTitle: 'テスト選挙',
        candidates: _candidates(),
        repository: repo,
        completedElection: _completedElection(),
      ),
    );

    expect(find.byKey(AppKeys.predictionOutcomeCard), findsOneWidget);
    expect(find.byKey(_errorViewKey), findsNothing);
    expect(find.byKey(_emptyViewKey), findsNothing);
  });
}
