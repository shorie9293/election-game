import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';
import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';
import 'package:election_game/features/crossapp/data/election_reward_event_exporter.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

/// クイズ採点確定経路から報酬イベントが書き出されることの試練。
void main() {
  late Directory tempDir;
  late String filePath;

  final questions = <QuizQuestion>[
    QuizQuestion(
      id: 'system_1',
      category: QuizCategory.system,
      question: '衆議院議員の任期は何年か？',
      choices: const ['2年', '3年', '4年', '6年'],
      correctIndex: 2,
      explanation: '衆議院議員の任期は4年です。',
    ),
    QuizQuestion(
      id: 'policy_1',
      category: QuizCategory.policy,
      question: '奨学金の拡充は、どの政策分野か？',
      choices: const ['教育政策', '農業政策', '治安政策', '雇用政策'],
      correctIndex: 0,
      explanation: '奨学金・少人数学級などは教育政策の代表例です。',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('quiz_wiring');
    filePath = '${tempDir.path}/election_reward_events.jsonl';
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  List<Map<String, dynamic>> readEvents() {
    final file = File(filePath);
    if (!file.existsSync()) return const [];
    return file
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .map((line) => jsonDecode(line) as Map<String, dynamic>)
        .toList();
  }

  /// 実ファイルI/Oは fake async の外で走るため、pump と runAsync を交互に回して
  /// 書き出しの完了を待つ（pump が継続を流し、runAsync が実I/Oを進める）。
  Future<List<Map<String, dynamic>>> waitForEvents(
    WidgetTester tester, {
    int expected = 1,
  }) async {
    for (var i = 0; i < 100; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      final current = readEvents();
      if (current.length >= expected) return current;
    }
    return readEvents();
  }

  Future<void> settleIo(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
  }

  /// 2問を [choices] のインデックス列で回答し、結果画面まで進める。
  Future<void> playQuiz(WidgetTester tester, List<int> choices) async {
    for (var i = 0; i < choices.length; i++) {
      await tester.tap(find.byKey(AppKeys.quizChoice(choices[i])));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(AppKeys.quizNextButton));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(AppKeys.quizResultView), findsOneWidget);
  }

  testWidgets('採点確定で quiz_completed が1行だけ書き出される', (tester) async {
    final exporter = FileElectionRewardEventExporter(
      filePath: filePath,
      userId: 'abcd1234',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          questions: questions,
          repository: const QuizRepository(),
          mistakeRepository: const SharedPreferencesQuizMistakeRepository(),
          rewardEventExporter: exporter,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1問目正解（index 2）・2問目不正解（index 3）
    await playQuiz(tester, [2, 3]);

    final events = await waitForEvents(tester);
    expect(events, hasLength(1));

    final event = events.single;
    expect(event['event_type'], 'quiz_completed');
    expect(event['user_id'], 'abcd1234');
    expect(event['event_id'], isA<String>());
    expect(DateTime.parse(event['timestamp'] as String).isUtc, isTrue);
    expect(event['metadata'], {
      'correct_count': 1,
      'total': 2,
      'passed': false,
    });
  });

  testWidgets('連携コードから先頭8文字が user_id に反映される', (tester) async {
    final exporter = FileElectionRewardEventExporter(filePath: filePath);

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          questions: questions,
          repository: const QuizRepository(),
          mistakeRepository: const SharedPreferencesQuizMistakeRepository(),
          rewardEventExporter: exporter,
          linkCodeRepository: InMemoryCrossAppLinkCodeRepository(
            'mnop4567-1234-5678-90ab-cdef12345678',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await playQuiz(tester, [2, 0]);

    final events = await waitForEvents(tester);
    expect(events, hasLength(1));
    expect(events.single['user_id'], 'mnop4567');
    expect(
        (events.single['metadata'] as Map<String, dynamic>)['passed'], isTrue);
  });

  testWidgets('未連携なら書き出さない', (tester) async {
    final exporter = FileElectionRewardEventExporter(filePath: filePath);

    await tester.pumpWidget(
      MaterialApp(
        home: QuizScreen(
          questions: questions,
          repository: const QuizRepository(),
          mistakeRepository: const SharedPreferencesQuizMistakeRepository(),
          rewardEventExporter: exporter,
          linkCodeRepository: InMemoryCrossAppLinkCodeRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await playQuiz(tester, [2, 0]);

    await settleIo(tester);
    expect(File(filePath).existsSync(), isFalse);
  });
}
