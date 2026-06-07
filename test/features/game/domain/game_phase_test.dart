import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/game/domain/game_phase.dart';

void main() {
  group('GamePhase', () {
    test('7つのフェーズが定義されていること', () {
      expect(GamePhase.values.length, 7);
    });

    test('全フェーズの値が正しいこと', () {
      expect(GamePhase.values[0], GamePhase.citizenCreate);
      expect(GamePhase.values[1], GamePhase.home);
      expect(GamePhase.values[2], GamePhase.electionAnnouncement);
      expect(GamePhase.values[3], GamePhase.debate);
      expect(GamePhase.values[4], GamePhase.vote);
      expect(GamePhase.values[5], GamePhase.result);
      expect(GamePhase.values[6], GamePhase.ending);
    });
  });
}
