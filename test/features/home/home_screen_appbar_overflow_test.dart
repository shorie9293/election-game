import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/home/domain/app_bar_action_plan.dart';
import 'package:election_game/features/home/presentation/home_screen.dart';
import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/society_state.dart';

/// 実機幅（1080x2340 / dpr 3.0 = 論理 360x780）で HomeScreen を pump し、
/// AppBar の導線が横溢れしないことを撃つ。
///
/// 既存の home_screen_test.dart は既定ビューポート（800x600）ゆえ、
/// 実機でだけ起きる `RenderFlex overflowed` を一度も撃っていない。
void main() {
  Future<void> pumpAt(
    WidgetTester tester, {
    required Size logicalSize,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(
      logicalSize.width * 3.0,
      logicalSize.height * 3.0,
    );
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final citizen = Citizen.initial(Job.farmer).copyWith(name: '農家太郎');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: HomeScreen(
          citizen: citizen,
          societyState: SocietyState.initial(),
          remainingTurns: 10,
        ),
      ),
    );
    await tester.pump();
  }

  group('AppBarActionPlan（純粋層）', () {
    test('不変条件: inline + overflow == actionCount, inline >= 1', () {
      for (var width = 200.0; width <= 1400.0; width += 20) {
        for (var count = 0; count <= 20; count++) {
          final plan = AppBarActionPlan.plan(
            actionCount: count,
            availableWidth: width,
          );
          expect(plan.inlineCount + plan.overflowCount, count,
              reason: 'width=$width count=$count');
          if (count > 0) {
            expect(plan.inlineCount, greaterThanOrEqualTo(1),
                reason: 'width=$width count=$count');
          }
          expect(plan.hasOverflow, plan.overflowCount > 0);
        }
      }
    });

    test('収まる幅では全件直置き（後方互換）', () {
      final plan = AppBarActionPlan.plan(
        actionCount: 16,
        availableWidth: 1400,
      );
      expect(plan.inlineCount, 16);
      expect(plan.overflowCount, 0);
    });

    test('実機幅360dpでは16件は収まらず畳まれる', () {
      final plan = AppBarActionPlan.plan(
        actionCount: 16,
        availableWidth: 360,
      );
      expect(plan.hasOverflow, isTrue);
      expect(plan.inlineCount, lessThan(16));
    });

    test('文字倍率でタイトル予約幅を増やすと直置き枠が減る', () {
      int inlineAt(double reserve) => AppBarActionPlan.plan(
            actionCount: 16,
            availableWidth: 800,
            titleReserve: reserve,
          ).inlineCount;

      expect(inlineAt(96), greaterThan(inlineAt(96 * 2.0)));
    });
  });

  group('HomeScreen AppBar 実機幅', () {
    for (final scale in <double>[1.0, 1.3, 2.0]) {
      testWidgets('360dp / textScaler $scale で横溢れしない', (tester) async {
        await pumpAt(
          tester,
          logicalSize: const Size(360, 780),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('360dp で畳まれた導線が「その他」メニューから到達できる', (tester) async {
      await pumpAt(tester, logicalSize: const Size(360, 780));

      // 直置きされていない導線（アプリについて）をメニューから開く。
      expect(find.byKey(const Key('home_about_button')), findsNothing);
      await tester.tap(find.byKey(const Key('home_more_actions')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home_about_button')), findsOneWidget);
    });

    testWidgets('畳まれていても主要操作（候補者名鑑）は直置きで残る', (tester) async {
      await pumpAt(tester, logicalSize: const Size(360, 780));
      expect(find.byKey(const Key('home_almanac_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('十分広い画面（1400dp）では従来通り全導線を直置きする', (tester) async {
      await pumpAt(tester, logicalSize: const Size(1400, 800));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('home_more_actions')), findsNothing);
      expect(find.byKey(const Key('home_almanac_button')), findsOneWidget);
      expect(find.byKey(const Key('home_about_button')), findsOneWidget);
    });
  });
}
