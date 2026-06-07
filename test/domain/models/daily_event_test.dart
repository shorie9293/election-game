import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/daily_event.dart';

void main() {
  group('DailyAction', () {
    test('3つのアクションが定義されている', () {
      expect(DailyAction.values.length, 3);
      expect(DailyAction.values, contains(DailyAction.talkToNpc));
      expect(DailyAction.values, contains(DailyAction.gatherInfo));
      expect(DailyAction.values, contains(DailyAction.rest));
    });
  });

  group('EventChoice', () {
    test('EventChoiceを生成できる（効果あり）', () {
      const choice = EventChoice(
        label: '話を聞く',
        resultDescription: '本音が聞けた。',
        effects: {'happiness': 2},
      );
      expect(choice.label, '話を聞く');
      expect(choice.resultDescription, '本音が聞けた。');
      expect(choice.effects, {'happiness': 2});
    });

    test('EventChoiceを生成できる（効果なし）', () {
      const choice = EventChoice(
        label: '軽く流す',
        resultDescription: '当たり障りなく答えた。',
      );
      expect(choice.label, '軽く流す');
      expect(choice.resultDescription, '当たり障りなく答えた。');
      expect(choice.effects, isNull);
    });
  });

  group('DailyEvent', () {
    test('シンプルなDailyEventを生成できる', () {
      const event = DailyEvent(
        title: 'ご近所づきあい',
        description: '隣の家から漬物をもらった。',
        icon: '🏠',
      );
      expect(event.title, 'ご近所づきあい');
      expect(event.description, '隣の家から漬物をもらった。');
      expect(event.icon, '🏠');
      expect(event.choices, isNull);
      expect(event.actionType, isNull);
      expect(event.effects, isNull);
    });

    test('effects付きDailyEventを生成できる', () {
      const event = DailyEvent(
        title: '臨時収入',
        description: 'お礼をもらった。',
        icon: '💰',
        effects: {'lifeCost': -5},
      );
      expect(event.effects, {'lifeCost': -5});
    });

    test('choices付きDailyEventを生成できる', () {
      const event = DailyEvent(
        title: '選挙の話',
        description: '町民が話しかけてきた。',
        icon: '🗣️',
        choices: [],
      );
      expect(event.choices, isNotNull);
      expect(event.choices, isEmpty);
    });

    test('2つの選択肢を持つDailyEventを生成できる', () {
      const event = DailyEvent(
        title: '選挙の話',
        description: '町民が話しかけてきた。',
        icon: '🗣️',
        choices: [
          EventChoice(
            label: 'しっかり話を聞く',
            resultDescription: '本音が聞けた。',
            effects: {'happiness': 2},
          ),
          EventChoice(
            label: '軽く流す',
            resultDescription: '当たり障りなく答えた。',
          ),
        ],
      );
      expect(event.choices!.length, 2);
      expect(event.choices![0].label, 'しっかり話を聞く');
      expect(event.choices![1].label, '軽く流す');
    });

    test('actionType付きDailyEventを生成できる', () {
      const event = DailyEvent(
        title: '朝刊チェック',
        description: '新聞を読んだ。',
        icon: '📰',
        actionType: DailyAction.gatherInfo,
      );
      expect(event.actionType, DailyAction.gatherInfo);
    });

    test('3つのactionTypeすべてで生成できる', () {
      for (final action in DailyAction.values) {
        final event = DailyEvent(
          title: 'test',
          description: 'desc',
          icon: '📋',
          actionType: action,
        );
        expect(event.actionType, action);
      }
    });

    test('choicesとeffectsの両方を持つことができる', () {
      const event = DailyEvent(
        title: 'どう過ごす？',
        description: '時間ができた。',
        icon: '🕰️',
        actionType: DailyAction.rest,
        effects: {'healthcare': 3},
        choices: [
          EventChoice(
            label: '温泉に行く',
            resultDescription: 'リフレッシュ。',
            effects: {'healthcare': 5, 'lifeCost': -3},
          ),
          EventChoice(
            label: '家でのんびり',
            resultDescription: 'リラックス。',
            effects: {'healthcare': 2},
          ),
        ],
      );
      expect(event.effects, {'healthcare': 3});
      expect(event.choices!.length, 2);
      expect(event.actionType, DailyAction.rest);
    });
  });
}
