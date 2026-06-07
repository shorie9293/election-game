import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/election_scale.dart';

void main() {
  group('ElectionScale', () {
    test('村を作成できる', () {
      const scale = ElectionScale.village;
      expect(scale.displayName, '天照村');
      expect(scale.title, '村長選挙');
      expect(scale.electionsNeeded, 3);
      expect(scale.npcCount, 5);
      expect(scale.politicalComplexity, 'simple');
    });

    test('町を作成できる', () {
      const scale = ElectionScale.town;
      expect(scale.displayName, '天照町');
      expect(scale.title, '町長選挙');
      expect(scale.electionsNeeded, 3);
      expect(scale.npcCount, 8);
      expect(scale.politicalComplexity, 'moderate');
    });

    test('市を作成できる', () {
      const scale = ElectionScale.city;
      expect(scale.displayName, '天照市');
      expect(scale.title, '市長選挙');
      expect(scale.electionsNeeded, 3);
      expect(scale.npcCount, 12);
      expect(scale.politicalComplexity, 'complex');
    });

    test('valuesに3つのスケールが含まれる', () {
      expect(ElectionScale.values.length, 3);
      expect(ElectionScale.values, contains(ElectionScale.village));
      expect(ElectionScale.values, contains(ElectionScale.town));
      expect(ElectionScale.values, contains(ElectionScale.city));
    });

    test('toJson/fromJsonでシリアライズできる', () {
      const scale = ElectionScale.city;
      final json = scale.toJson();
      final restored = ElectionScale.fromJson(json);
      expect(restored, scale);
    });

    test('advanceToで次の段階に進める', () {
      expect(ElectionScale.village.advanceTo, ElectionScale.town);
      expect(ElectionScale.town.advanceTo, ElectionScale.city);
      expect(ElectionScale.city.advanceTo, isNull);
    });

    test('initialで村が返る', () {
      expect(ElectionScale.initial(), ElectionScale.village);
    });

    test('fromJsonに無効な値が渡された場合、村が返る', () {
      final restored = ElectionScale.fromJson({'displayName': 'invalid'});
      expect(restored, ElectionScale.village);
    });
  });
}
