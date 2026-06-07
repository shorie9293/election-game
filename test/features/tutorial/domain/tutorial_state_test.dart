import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';
import 'package:election_game/features/tutorial/domain/tutorial_state.dart';

void main() {
  group('TutorialState', () {
    group('initial()', () {
      test('デフォルト値が正しい', () {
        final state = TutorialState.initial();

        expect(state.isActive, false);
        expect(state.hasCompleted, false);
        expect(state.currentStep, isNull);
        expect(state.isSkipped, false);
      });
    });

    group('copyWith', () {
      test('isActiveを変更できる', () {
        final state = TutorialState.initial();
        final modified = state.copyWith(isActive: true);

        expect(modified.isActive, true);
        expect(modified.hasCompleted, false);
        expect(modified.isSkipped, false);
      });

      test('hasCompletedを変更できる', () {
        final state = TutorialState.initial();
        final modified = state.copyWith(hasCompleted: true);

        expect(modified.hasCompleted, true);
        expect(modified.isActive, false);
      });

      test('currentStepを変更できる', () {
        final state = TutorialState.initial();
        final modified = state.copyWith(currentStep: TutorialStep.home);

        expect(modified.currentStep, TutorialStep.home);
      });

      test('isSkippedを変更できる', () {
        final state = TutorialState.initial();
        final modified = state.copyWith(isSkipped: true);

        expect(modified.isSkipped, true);
      });

      test('複数フィールドを同時変更できる', () {
        final state = TutorialState.initial();
        final modified = state.copyWith(
          isActive: true,
          hasCompleted: false,
          currentStep: TutorialStep.debate,
          isSkipped: false,
        );

        expect(modified.isActive, true);
        expect(modified.hasCompleted, false);
        expect(modified.currentStep, TutorialStep.debate);
        expect(modified.isSkipped, false);
      });
    });

    group('toJson / fromJson', () {
      test('initialをシリアライズ・デシリアライズできる', () {
        final state = TutorialState.initial();
        final json = state.toJson();
        final restored = TutorialState.fromJson(json);

        expect(restored, state);
      });

      test('アクティブ状態をシリアライズ・デシリアライズできる', () {
        final state = TutorialState(
          isActive: true,
          hasCompleted: false,
          currentStep: TutorialStep.vote,
          isSkipped: false,
        );
        final json = state.toJson();
        final restored = TutorialState.fromJson(json);

        expect(restored, state);
        expect(restored.isActive, true);
        expect(restored.currentStep, TutorialStep.vote);
      });

      test('完了状態をシリアライズ・デシリアライズできる', () {
        final state = TutorialState(
          isActive: false,
          hasCompleted: true,
          currentStep: null,
          isSkipped: false,
        );
        final json = state.toJson();
        final restored = TutorialState.fromJson(json);

        expect(restored, state);
        expect(restored.hasCompleted, true);
      });

      test('スキップ状態をシリアライズ・デシリアライズできる', () {
        final state = TutorialState(
          isActive: false,
          hasCompleted: false,
          currentStep: null,
          isSkipped: true,
        );
        final json = state.toJson();
        final restored = TutorialState.fromJson(json);

        expect(restored, state);
        expect(restored.isSkipped, true);
      });

      test('JSONのキーが正しい', () {
        final state = TutorialState(
          isActive: true,
          hasCompleted: false,
          currentStep: TutorialStep.citizenCreate,
          isSkipped: false,
        );
        final json = state.toJson();

        expect(json['is_active'], true);
        expect(json['has_completed'], false);
        expect(json['current_step'], 'citizenCreate');
        expect(json['is_skipped'], false);
      });
    });

    group('Equatable', () {
      test('同じ値のインスタンスは等しい', () {
        final a = TutorialState.initial();
        final b = TutorialState.initial();

        expect(a, equals(b));
      });

      test('異なるisActiveは等しくない', () {
        final a = TutorialState.initial();
        final b = TutorialState.initial().copyWith(isActive: true);

        expect(a, isNot(equals(b)));
      });

      test('異なるcurrentStepは等しくない', () {
        final a = TutorialState.initial();
        final b = TutorialState.initial().copyWith(currentStep: TutorialStep.home);

        expect(a, isNot(equals(b)));
      });

      test('propsが正しい', () {
        const state = TutorialState(
          isActive: true,
          hasCompleted: false,
          currentStep: TutorialStep.debate,
          isSkipped: false,
        );

        expect(state.props, [
          true,
          false,
          TutorialStep.debate,
          false,
        ]);
      });
    });
  });
}
