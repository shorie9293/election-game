import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/prediction/data/prediction_repository.dart';
import 'package:election_game/features/prediction/domain/election_prediction.dart';

ElectionPrediction _p({String electionId = 'e1'}) => ElectionPrediction(
      electionId: electionId,
      predictedWinnerId: 'c1',
      predictedShare: 55,
      createdAt: 1234,
    );

void main() {
  group('SharedPreferencesPredictionRepository', () {
    late SharedPreferencesPredictionRepository repo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = const SharedPreferencesPredictionRepository();
    });

    test('save→load 往復', () async {
      final p = _p();
      await repo.save(p);
      final loaded = await repo.load('e1');
      expect(loaded, isNotNull);
      expect(loaded, equals(p));
    });

    test('save は JSON map 形式で保存する', () async {
      await repo.save(_p());
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(SharedPreferencesPredictionRepository.predictionsKey);
      expect(raw, isNotNull);
      expect(raw, contains('"e1"'));
    });

    test('同一electionIdのsaveは上書き', () async {
      await repo.save(_p());
      await repo.save(_p().copyWith(predictedShare: 80));
      final loaded = await repo.load('e1');
      expect(loaded!.predictedShare, 80);
    });

    test('未保存はnull', () async {
      expect(await repo.load('missing'), isNull);
    });

    test('破損文字列でnull', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '{not json',
      });
      expect(await repo.load('e1'), isNull);
    });

    test('型不一致（文字列）でnull', () async {
      SharedPreferences.setMockInitialValues({
        SharedPreferencesPredictionRepository.predictionsKey: '{"e1": "text"}',
      });
      expect(await repo.load('e1'), isNull);
    });

    test('remove後はnull', () async {
      await repo.save(_p());
      await repo.remove('e1');
      expect(await repo.load('e1'), isNull);
    });

    test('removeは他の選挙の予想を壊さない', () async {
      await repo.save(_p(electionId: 'e1'));
      await repo.save(_p(electionId: 'e2'));
      await repo.remove('e1');
      expect(await repo.load('e1'), isNull);
      expect(await repo.load('e2'), isNotNull);
    });

    test('remove: 未保存キーでもエラーにならない', () async {
      await repo.remove('nothing');
      expect(await repo.load('nothing'), isNull);
    });
  });

  group('InMemoryPredictionRepository', () {
    test('save→load 往復', () async {
      final repo = InMemoryPredictionRepository();
      final p = _p();
      await repo.save(p);
      expect(await repo.load('e1'), equals(p));
      expect(repo.store['e1'], equals(p));
    });

    test('remove で store から消える', () async {
      final repo = InMemoryPredictionRepository();
      await repo.save(_p());
      await repo.remove('e1');
      expect(repo.store, isEmpty);
      expect(await repo.load('e1'), isNull);
    });

    test('未保存はnull', () async {
      final repo = InMemoryPredictionRepository();
      expect(await repo.load('e1'), isNull);
    });
  });

  group('NoopPredictionRepository', () {
    test('loadは常にnull', () async {
      const repo = NoopPredictionRepository();
      expect(await repo.load('e1'), isNull);
    });

    test('save/removeはno-opで例外を出さない', () async {
      const repo = NoopPredictionRepository();
      await repo.save(_p());
      await repo.remove('e1');
      expect(await repo.load('e1'), isNull);
    });
  });
}