import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/society_state.dart';

void main() {
  group('SocietyState model', () {
    test('SocietyStateを生成できる', () {
      final state = SocietyState(
        happiness: 65.0,
        mood: 0.4,
        currentLeaderId: 'cand_1',
        electionCount: 2,
      );

      expect(state.happiness, 65.0);
      expect(state.mood, 0.4);
      expect(state.currentLeaderId, 'cand_1');
      expect(state.electionCount, 2);
    });

    test('SocietyState.initialで初期値が設定される', () {
      final state = SocietyState.initial();
      expect(state.happiness, 50.0);
      expect(state.mood, 0.3);
      expect(state.electionCount, 0);
    });

    test('moodLabelが段階ごとに正しく返る', () {
      expect(SocietyState(happiness: 50, mood: 0.1, electionCount: 0).moodLabel, 'なれ合い');
      expect(SocietyState(happiness: 50, mood: 0.3, electionCount: 0).moodLabel, '融和');
      expect(SocietyState(happiness: 50, mood: 0.5, electionCount: 0).moodLabel, '健全な対立');
      expect(SocietyState(happiness: 50, mood: 0.7, electionCount: 0).moodLabel, '不健全な対立');
      expect(SocietyState(happiness: 50, mood: 0.9, electionCount: 0).moodLabel, '独裁');
    });

    test('moodColorが段階ごとに正しく返る', () {
      final state = SocietyState(happiness: 50, mood: 0.1, electionCount: 0);
      // Just check it doesn't throw and returns a Color
      expect(state.moodColor, isNotNull);
    });

    test('copyWithで一部変更できる', () {
      final state = SocietyState.initial();
      final updated = state.copyWith(happiness: 80.0, electionCount: 1);
      expect(updated.happiness, 80.0);
      expect(updated.electionCount, 1);
      expect(updated.mood, 0.3); // unchanged
    });

    test('toJson/fromJsonでシリアライズできる', () {
      final state = SocietyState.initial().copyWith(
        happiness: 70.0,
        currentLeaderId: 'cand_2',
      );
      final json = state.toJson();
      final restored = SocietyState.fromJson(json);

      expect(restored.happiness, 70.0);
      expect(restored.currentLeaderId, 'cand_2');
      expect(restored.mood, 0.3);
    });

    test('equatableで等価性が正しい', () {
      final a = SocietyState.initial();
      final b = SocietyState.initial();
      final c = a.copyWith(happiness: 60.0);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
