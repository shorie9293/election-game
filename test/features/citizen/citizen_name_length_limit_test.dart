import 'dart:convert';

import 'package:election_game/domain/models/citizen.dart';
import 'package:election_game/domain/models/game_state.dart';
import 'package:election_game/domain/models/society_state.dart';
import 'package:election_game/features/citizen/presentation/citizen_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CitizenCreateScreen 名前の長さ上限', () {
    testWidgets('上限超過の長文は50文字に切り詰められ、保存→再読込で先頭50文字が保持される',
        (tester) async {
      Citizen? created;
      await tester.pumpWidget(
        MaterialApp(
          home: CitizenCreateScreen(
            onCitizenCreated: (citizen) => created = citizen,
          ),
        ),
      );

      // 上限(50)を大幅に超える長文。例外なく受け付けられ、先頭50文字だけが残る。
      final overlong = List.filled(300, 'あ').join();
      await tester.enterText(
        find.byKey(const Key('citizen_name_input')),
        overlong,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('citizen_create_button')));
      await tester.pumpAndSettle();

      final expected = overlong.substring(0, 50);
      expect(created, isNotNull);
      expect(created!.name, expected);
      expect(created!.name.length, 50);

      // 保存経路: GameState を JSON 化 → 再読込（バックアップ復元と同じ経路）
      final state = GameState(
        citizen: created!,
        society: SocietyState.initial(),
      );
      final decoded =
          jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>;
      final restored = GameState.fromJson(decoded);

      expect(restored.citizen.name, expected);
      expect(restored.citizen.name.length, 50);
    });

    testWidgets('上限以内の名前は切り捨てられない', (tester) async {
      Citizen? created;
      await tester.pumpWidget(
        MaterialApp(
          home: CitizenCreateScreen(
            onCitizenCreated: (citizen) => created = citizen,
          ),
        ),
      );

      final exactly = List.filled(50, 'い').join();
      await tester.enterText(
        find.byKey(const Key('citizen_name_input')),
        exactly,
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('citizen_create_button')));
      await tester.pumpAndSettle();

      expect(created, isNotNull);
      expect(created!.name, exactly);
    });
  });
}
