import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';

ElectionPrediction _prediction({String electionId = 'e1'}) => ElectionPrediction(
      electionId: electionId,
      predictedWinnerId: 'c1',
      predictedShare: 55,
      createdAt: 1234,
    );

/// load が例外を投げるだけの最小実装（既定 tryLoad の検証用）。
class _ThrowingRepository extends PredictionRepository {
  @override
  Future<ElectionPrediction?> load(String electionId) async {
    throw StateError('storage unavailable');
  }

  @override
  Future<void> save(ElectionPrediction prediction) async {}

  @override
  Future<void> remove(String electionId) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesPredictionRepository.tryLoad', () {
    late SharedPreferencesPredictionRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = const SharedPreferencesPredictionRepository();
    });

    test('未保存は failure ではなく success(null)（0件）', () async {
      final result = await repo.tryLoad('missing');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.message, isNull);
    });

    test('保存済みは値を返す', () async {
      await repo.save(_prediction());
      final result = await repo.tryLoad('e1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, _prediction());
    });

    test('JSON全体の破損は failure（null へ潰さない）', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '{not json',
      });
      final result = await repo.tryLoad('e1');
      expect(result.isFailure, isTrue);
      expect(result.message, isNotEmpty);
      expect(result.cause, isNotNull);
      expect(result.retryable, isTrue);
    });

    test('トップレベルが object 以外なら failure', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '[1, 2]',
      });
      final result = await repo.tryLoad('e1');
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('要素の型不一致は failure', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '{"e1": "text"}',
      });
      final result = await repo.tryLoad('e1');
      expect(result.isFailure, isTrue);
    });

    test('要素の復元失敗（必須欠落）は failure', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '{"e1": {}}',
      });
      final result = await repo.tryLoad('e1');
      expect(result.isFailure, isTrue);
    });

    test('別 electionId のみ保存済みなら success(null)', () async {
      await repo.save(_prediction(electionId: 'other'));
      final result = await repo.tryLoad('e1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });

  group('PredictionRepository 既定 tryLoad', () {
    test('load の例外は failure に変換され retryable', () async {
      final result = await _ThrowingRepository().tryLoad('e1');
      expect(result.isFailure, isTrue);
      expect(result.retryable, isTrue);
      expect(result.cause, isA<StateError>());
    });

    test('InMemory は未保存で success(null)', () async {
      final result = await InMemoryPredictionRepository().tryLoad('e1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('Noop は常に success(null)', () async {
      final result = await const NoopPredictionRepository().tryLoad('e1');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });
  });
}
