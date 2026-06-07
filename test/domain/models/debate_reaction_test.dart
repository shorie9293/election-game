import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/debate_reaction.dart';

void main() {
  group('DebateReaction', () {
    test('fromString で正しい enum を復元できる', () {
      expect(DebateReaction.fromString('agree'), DebateReaction.agree);
      expect(DebateReaction.fromString('disagree'), DebateReaction.disagree);
      expect(DebateReaction.fromString('question'), DebateReaction.question);
      expect(DebateReaction.fromString('silent'), DebateReaction.silent);
    });

    test('fromString で不明な文字列の場合は silent を返す', () {
      expect(DebateReaction.fromString('invalid'), DebateReaction.silent);
      expect(DebateReaction.fromString(''), DebateReaction.silent);
    });

    test('全値に label と description が設定されている', () {
      for (final reaction in DebateReaction.values) {
        expect(reaction.label, isNotEmpty);
        expect(reaction.description, isNotEmpty);
      }
    });
  });

  group('DebateReactionRecord', () {
    test('toJson/fromJson で正しく変換できる', () {
      final record = DebateReactionRecord(
        speakerName: '山田太郎',
        reaction: DebateReaction.agree,
        speechIndex: 0,
      );

      final json = record.toJson();
      expect(json['speakerName'], '山田太郎');
      expect(json['reaction'], 'agree');
      expect(json['speechIndex'], 0);

      final restored = DebateReactionRecord.fromJson(json);
      expect(restored.speakerName, record.speakerName);
      expect(restored.reaction, record.reaction);
      expect(restored.speechIndex, record.speechIndex);
    });

    test('異なる反応で複数レコードを作成できる', () {
      final reactions = [
        DebateReactionRecord(
          speakerName: '山田太郎',
          reaction: DebateReaction.agree,
          speechIndex: 0,
        ),
        DebateReactionRecord(
          speakerName: '佐藤花子',
          reaction: DebateReaction.disagree,
          speechIndex: 1,
        ),
        DebateReactionRecord(
          speakerName: '鈴木一郎',
          reaction: DebateReaction.silent,
          speechIndex: 2,
        ),
      ];

      expect(reactions.length, 3);
      expect(reactions[0].reaction, DebateReaction.agree);
      expect(reactions[1].reaction, DebateReaction.disagree);
      expect(reactions[2].reaction, DebateReaction.silent);
    });

    test('question 反応も記録できる', () {
      final record = DebateReactionRecord(
        speakerName: '田中美咲',
        reaction: DebateReaction.question,
        speechIndex: 3,
      );

      expect(record.reaction, DebateReaction.question);
      expect(record.reaction.label, '質問する');
    });
  });
}
