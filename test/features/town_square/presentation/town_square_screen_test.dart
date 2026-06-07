import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/town_square/presentation/town_square_screen.dart';
import 'package:election_game/domain/models/opposition_citizen.dart';
import 'package:election_game/core/testing/app_keys.dart';

/// Pump with a tall surface so bottom sheet content fits
Future<void> pumpWithTallSurface(
  WidgetTester tester,
  Widget widget,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  await tester.pumpWidget(widget);
}

void main() {
  group('TownSquareScreen', () {
    // ── Basic display tests (no bottom sheet needed) ──

    testWidgets('街の広場画面がNPC一覧とともに表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await tester.pumpWidget(
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      expect(find.text('街の広場'), findsOneWidget);
      expect(find.text('五郎さん'), findsOneWidget);
      expect(find.text('さくら'), findsOneWidget);
      expect(find.text('鉄也'), findsOneWidget);
      expect(find.text('おばあちゃん'), findsOneWidget);
      expect(find.text('若者ケン'), findsOneWidget);
    });

    testWidgets('AppKeysが正しく設定されている', (tester) async {
      final npcs = OppositionCitizen.samples();
      await tester.pumpWidget(
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      expect(find.byKey(AppKeys.townSquareTitle), findsOneWidget);
      expect(find.byKey(AppKeys.townSquareNpcList), findsOneWidget);
    });

    testWidgets('NPCの性格が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await tester.pumpWidget(
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      expect(find.textContaining('頑固だが筋は通す'), findsOneWidget);
      expect(find.textContaining('理知的で開かれている'), findsOneWidget);
    });

    testWidgets('NPCの職業が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await tester.pumpWidget(
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      expect(find.text('農家'), findsOneWidget);
      expect(find.text('教師'), findsOneWidget);
      expect(find.text('商人'), findsOneWidget);
    });

    // ── Bottom sheet tests with tall surface ──

    testWidgets('NPCをタップするとボトムシートが表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.text('おう、若いのも選挙の話か？'), findsOneWidget);
    });

    testWidgets('ボトムシートに社会ムードに応じた台詞が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.1,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('まあ誰がなっても同じだべ'),
        findsOneWidget,
      );
    });

    testWidgets('ボトムシートを閉じボタンで閉じられる', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.text('おう、若いのも選挙の話か？'), findsOneWidget);

      // Find close button via key
      expect(find.byKey(AppKeys.townSquareCloseButton), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.townSquareCloseButton));
      await tester.pumpAndSettle();

      expect(find.text('おう、若いのも選挙の話か？'), findsNothing);
    });

    testWidgets('議論するボタンが表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.text('議論する'), findsOneWidget);
    });

    testWidgets('議論するボタンを押すと選択肢が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.3,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      expect(find.text('あなたの主張を選んでください:'), findsOneWidget);
    });

    testWidgets('議論の選択肢が複数表示される（健全な対立）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      expect(find.text('なるほど、そういう考え方もあるか'), findsOneWidget);
      expect(find.text('いや、俺は違うと思うぞ'), findsOneWidget);
    });

    testWidgets('議論の選択肢を選ぶと返答が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      // Select first option
      await tester.tap(find.text('なるほど、そういう考え方もあるか'));
      await tester.pumpAndSettle();

      // Player's speech bubble should show
      expect(find.text('あなた'), findsOneWidget);
    });

    testWidgets('議論後にさらに議論するボタンが表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('なるほど、そういう考え方もあるか'));
      await tester.pumpAndSettle();

      expect(find.text('さらに議論する'), findsOneWidget);
    });

    testWidgets('NPC情報に支持候補が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.textContaining('支持:'), findsOneWidget);
      expect(find.textContaining('守りの会'), findsWidgets);
    });

    testWidgets('NPC情報に頑固さバーが表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.text('頑固さ:'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('NPC情報に関心事が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.text('農業政策'), findsOneWidget);
      expect(find.text('環境政策'), findsOneWidget);
      expect(find.text('税制'), findsOneWidget);
    });

    testWidgets('社会の空気ラベルが表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.textContaining('健全な対立'), findsOneWidget);
    });

    testWidgets('なれ合いムードでは議論できない', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.1,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      expect(find.textContaining('議論できそうにない'), findsOneWidget);
      expect(find.text('議論する'), findsNothing);
    });

    testWidgets('独裁ムードでも議論選択肢がフォールバック表示される（五郎さん）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.9,
          ),
        ),
      );

      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();

      // mood 0.9 → 独裁, label should show
      expect(find.textContaining('独裁'), findsOneWidget);

      // 五郎さん has no stage 5 debateReplies, but falls back to stage 4
      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      // Stage 4 fallback replies should appear
      expect(find.text('それは違うべ！'), findsOneWidget);
      expect(find.text('話にならんな…'), findsOneWidget);
    });

    testWidgets('融和ムードで議論選択肢が表示される（さくら）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.3,
          ),
        ),
      );

      await tester.tap(find.text('さくら'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      expect(find.text('素敵な視点ですね'), findsOneWidget);
      expect(find.text('私もそう思います'), findsOneWidget);
    });

    testWidgets('不健全な対立ムードで激しい議論が表示される（若者ケン）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.7,
          ),
        ),
      );

      await tester.tap(find.text('若者ケン'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      expect(find.text('は？マジでありえないんだけど！'), findsOneWidget);
      expect(find.text('お前も守りの会の回し者か！'), findsOneWidget);
    });

    testWidgets('複数NPCで議論できる', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      // NPC1: 五郎さん
      await tester.tap(find.text('五郎さん'));
      await tester.pumpAndSettle();
      expect(find.text('議論する'), findsOneWidget);
      await tester.tap(find.byKey(AppKeys.townSquareCloseButton));
      await tester.pumpAndSettle();

      // NPC2: 鉄也
      await tester.tap(find.text('鉄也'));
      await tester.pumpAndSettle();
      expect(find.text('議論する'), findsOneWidget);
    });

    testWidgets('NPC情報に頑固さがパーセント表示される（さくら：低頑固さ）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('さくら'));
      await tester.pumpAndSettle();

      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('NPC情報に頑固さがパーセント表示される（おばあちゃん：高頑固さ）', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('おばあちゃん'));
      await tester.pumpAndSettle();

      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('議論選択肢を選ぶと吹き出しに選択内容が表示される', (tester) async {
      final npcs = OppositionCitizen.samples();
      await pumpWithTallSurface(
        tester,
        MaterialApp(
          home: TownSquareScreen(
            npcs: npcs,
            societyMood: 0.5,
          ),
        ),
      );

      await tester.tap(find.text('さくら'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('議論する'));
      await tester.pumpAndSettle();

      // Select 'なるほど、その考えは新鮮です'
      await tester.tap(find.text('なるほど、その考えは新鮮です'));
      await tester.pumpAndSettle();

      expect(find.text('なるほど、その考えは新鮮です'), findsOneWidget);
    });
  });
}
