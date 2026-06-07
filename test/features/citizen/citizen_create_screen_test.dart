import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:election_game/features/citizen/presentation/citizen_create_screen.dart';

void main() {
  group('CitizenCreateScreen', () {
    testWidgets('キャラメイク画面が表示される', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitizenCreateScreen(),
        ),
      );

      expect(find.text('市民登録'), findsOneWidget);
      expect(find.byKey(const Key('citizen_name_input')), findsOneWidget);
      expect(find.byKey(const Key('citizen_job_selector')), findsOneWidget);
    });

    testWidgets('名前を入力して職業を選択できる', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CitizenCreateScreen(),
        ),
      );

      // 名前入力
      await tester.enterText(
        find.byKey(const Key('citizen_name_input')),
        'テスト市民',
      );

      // 職業選択（デフォルトで最初の職業が選択されているはず）
      expect(find.text('テスト市民'), findsOneWidget);
    });

    testWidgets('確定ボタンを押すとコールバックが呼ばれる', (tester) async {
      String? createdName;
      await tester.pumpWidget(
        MaterialApp(
          home: CitizenCreateScreen(
            onCitizenCreated: (citizen) {
              createdName = citizen.name;
            },
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('citizen_name_input')),
        '山田太郎',
      );
      await tester.tap(find.byKey(const Key('citizen_create_button')));
      await tester.pumpAndSettle();

      expect(createdName, '山田太郎');
    });
  });
}
