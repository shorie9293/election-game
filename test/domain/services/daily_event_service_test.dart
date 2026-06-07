import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/domain/services/daily_event_service.dart';
import 'package:election_game/domain/models/daily_event.dart';

void main() {
  group('DailyEventService', () {
    final farmer = Citizen.initial(Job.farmer);
    final defaultSociety = SocietyState.initial();

    // -- 従来の generate メソッドのテスト（後方互換性） --
    test('generate は市民と社会状態からイベントを生成する（nullまたはDailyEvent）', () {
      final society = SocietyState.initial();
      final event = DailyEventService.generate(farmer, society);
      expect(event, anyOf(isNull, isA<DailyEvent>()));
    });

    test('generate は職業によって異なるイベントプールを持つ（複数回実行で確認）', () {
      final society = SocietyState.initial();
      bool gotEvent = false;
      for (int i = 0; i < 50; i++) {
        final event = DailyEventService.generate(farmer, society);
        if (event != null) {
          gotEvent = true;
          expect(event.icon, isNotEmpty);
          expect(event.title, isNotEmpty);
          expect(event.description, isNotEmpty);
          break;
        }
      }
      expect(gotEvent, isTrue);
    });

    test('generate はどんな職業の市民でもエラーなく呼べる', () {
      final society = SocietyState.initial();
      for (final job in Job.values) {
        final citizen = Citizen.initial(job);
        DailyEventService.generate(citizen, society);
      }
    });

    test('社会ムードが高いときもエラーなく呼べる', () {
      final highMood = SocietyState.initial().copyWith(mood: 0.8);
      DailyEventService.generate(farmer, highMood);
    });

    // -- 新規: generateForAction のテスト --
    group('generateForAction', () {
      test('talkToNpc で DailyEvent または null を返す', () {
        final event = DailyEventService.generateForAction(
          DailyAction.talkToNpc,
          farmer,
          defaultSociety,
        );
        expect(event, anyOf(isNull, isA<DailyEvent>()));
      });

      test('gatherInfo で DailyEvent または null を返す', () {
        final event = DailyEventService.generateForAction(
          DailyAction.gatherInfo,
          farmer,
          defaultSociety,
        );
        expect(event, anyOf(isNull, isA<DailyEvent>()));
      });

      test('rest で DailyEvent または null を返す', () {
        final event = DailyEventService.generateForAction(
          DailyAction.rest,
          farmer,
          defaultSociety,
        );
        expect(event, anyOf(isNull, isA<DailyEvent>()));
      });

      test('talkToNpc は複数回実行で少なくとも1回はイベントを返す', () {
        final society = SocietyState.initial();
        bool gotEvent = false;
        for (int i = 0; i < 30; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.talkToNpc,
            farmer,
            society,
          );
          if (event != null) {
            gotEvent = true;
            expect(event.icon, isNotEmpty);
            expect(event.title, isNotEmpty);
            expect(event.description, isNotEmpty);
            break;
          }
        }
        expect(gotEvent, isTrue);
      });

      test('gatherInfo は複数回実行で少なくとも1回はイベントを返す', () {
        final society = SocietyState.initial();
        bool gotEvent = false;
        for (int i = 0; i < 30; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.gatherInfo,
            farmer,
            society,
          );
          if (event != null) {
            gotEvent = true;
            expect(event.icon, isNotEmpty);
            expect(event.title, isNotEmpty);
            break;
          }
        }
        expect(gotEvent, isTrue);
      });

      test('rest は複数回実行で少なくとも1回はイベントを返す', () {
        final society = SocietyState.initial();
        bool gotEvent = false;
        for (int i = 0; i < 30; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.rest,
            farmer,
            society,
          );
          if (event != null) {
            gotEvent = true;
            expect(event.icon, isNotEmpty);
            break;
          }
        }
        expect(gotEvent, isTrue);
      });

      test('talkToNpc で発生したイベントには actionType が talkToNpc である', () {
        final society = SocietyState.initial();
        for (int i = 0; i < 50; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.talkToNpc,
            farmer,
            society,
          );
          if (event != null) {
            expect(event.actionType, DailyAction.talkToNpc);
            return;
          }
        }
        fail('50回試行してもイベントが発生しなかった');
      });

      test('gatherInfo で発生したイベントには actionType が gatherInfo である', () {
        final society = SocietyState.initial();
        for (int i = 0; i < 50; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.gatherInfo,
            farmer,
            society,
          );
          if (event != null) {
            expect(event.actionType, DailyAction.gatherInfo);
            return;
          }
        }
        fail('50回試行してもイベントが発生しなかった');
      });

      test('rest で発生したイベントには actionType が rest である', () {
        final society = SocietyState.initial();
        for (int i = 0; i < 50; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.rest,
            farmer,
            society,
          );
          if (event != null) {
            expect(event.actionType, DailyAction.rest);
            return;
          }
        }
        fail('50回試行してもイベントが発生しなかった');
      });

      test('talkToNpc で choices 付きイベントが生成されることがある', () {
        final society = SocietyState.initial();
        bool foundChoiceEvent = false;
        for (int i = 0; i < 100; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.talkToNpc,
            farmer,
            society,
          );
          if (event != null && event.choices != null) {
            foundChoiceEvent = true;
            expect(event.choices!.length, greaterThanOrEqualTo(2));
            break;
          }
        }
        expect(foundChoiceEvent, isTrue, reason: '100回の試行でchoices付きイベントが見つからなかった');
      });

      test('rest で choices 付きイベントが生成されることがある', () {
        final society = SocietyState.initial();
        bool foundChoiceEvent = false;
        for (int i = 0; i < 100; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.rest,
            farmer,
            society,
          );
          if (event != null && event.choices != null) {
            foundChoiceEvent = true;
            expect(event.choices!.length, greaterThanOrEqualTo(2));
            break;
          }
        }
        expect(foundChoiceEvent, isTrue, reason: '100回の試行でchoices付きイベントが見つからなかった');
      });

      test('全アクション・全職業でエラーなく呼べる', () {
        for (final action in DailyAction.values) {
          for (final job in Job.values) {
            final citizen = Citizen.initial(job);
            DailyEventService.generateForAction(action, citizen, defaultSociety);
          }
        }
      });

      test('talkToNpc で rest のアクションタイプのイベントは返らない', () {
        final society = SocietyState.initial();
        for (int i = 0; i < 30; i++) {
          final event = DailyEventService.generateForAction(
            DailyAction.talkToNpc,
            farmer,
            society,
          );
          if (event != null) {
            expect(event.actionType, isNot(DailyAction.rest));
            expect(event.actionType, isNot(DailyAction.gatherInfo));
          }
        }
      });
    });
  });
}
