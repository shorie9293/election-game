import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/features/prediction/domain/election_prediction.dart';

void main() {
  group('ElectionPrediction 検証', () {
    test('空electionIdでArgumentError', () {
      expect(
        () => ElectionPrediction(
          electionId: '  ',
          predictedWinnerId: 'c1',
          predictedShare: 50,
          createdAt: 1,
        ),
        throwsArgumentError,
      );
    });

    test('空winnerIdでArgumentError', () {
      expect(
        () => ElectionPrediction(
          electionId: 'e1',
          predictedWinnerId: '',
          predictedShare: 50,
          createdAt: 1,
        ),
        throwsArgumentError,
      );
    });

    test('0%でArgumentError', () {
      expect(
        () => ElectionPrediction(
          electionId: 'e1',
          predictedWinnerId: 'c1',
          predictedShare: 0,
          createdAt: 1,
        ),
        throwsArgumentError,
      );
    });

    test('101%でArgumentError', () {
      expect(
        () => ElectionPrediction(
          electionId: 'e1',
          predictedWinnerId: 'c1',
          predictedShare: 101,
          createdAt: 1,
        ),
        throwsArgumentError,
      );
    });

    test('正常系では生成できる', () {
      final p = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c1',
        predictedShare: 1,
        createdAt: 42,
      );
      expect(p.electionId, 'e1');
      expect(p.predictedShare, 1);
    });
  });

  group('toJson / fromJson', () {
    test('往復変換で同じ値になる', () {
      final p = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c2',
        predictedShare: 55,
        createdAt: 100,
      );
      final restored = ElectionPrediction.fromJson(p.toJson());
      expect(restored, equals(p));
    });

    test('必須キー欠落でFormatException', () {
      expect(
        () => ElectionPrediction.fromJson({
          'predictedWinnerId': 'c1',
          'predictedShare': 50,
          'createdAt': 1,
        }),
        throwsFormatException,
      );
    });

    test('型不一致でFormatException', () {
      expect(
        () => ElectionPrediction.fromJson({
          'electionId': 'e1',
          'predictedWinnerId': 'c1',
          'predictedShare': '50',
          'createdAt': 1,
        }),
        throwsFormatException,
      );
    });
  });

  group('copyWith', () {
    test('指定フィールドのみ変わる', () {
      final p = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c1',
        predictedShare: 50,
        createdAt: 1,
      );
      final updated = p.copyWith(predictedShare: 70, predictedWinnerId: 'c3');
      expect(updated.electionId, 'e1');
      expect(updated.predictedWinnerId, 'c3');
      expect(updated.predictedShare, 70);
      expect(updated.createdAt, 1);
    });

    test('copyWith後も検証が働く', () {
      final p = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c1',
        predictedShare: 50,
        createdAt: 1,
      );
      expect(() => p.copyWith(predictedShare: 0), throwsArgumentError);
    });
  });

  group('Equatable', () {
    test('同じ値のインスタンスは等しい', () {
      final a = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c1',
        predictedShare: 50,
        createdAt: 1,
      );
      final b = ElectionPrediction(
        electionId: 'e1',
        predictedWinnerId: 'c1',
        predictedShare: 50,
        createdAt: 1,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });
}