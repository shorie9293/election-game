import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/features/settings/presentation/text_scale_settings_screen.dart';

Widget _wrap({double currentScale = 1.0, ValueChanged<double>? onChanged}) {
  return MaterialApp(
    home: TextScaleSettingsScreen(
      currentScale: currentScale,
      onScaleChanged: onChanged ?? (_) {},
    ),
  );
}

void main() {
  testWidgets('renders 3 options with keys and labels', (tester) async {
    await tester.pumpWidget(_wrap());

    expect(find.byKey(const Key('text_scale_0.9')), findsOneWidget);
    expect(find.byKey(const Key('text_scale_1.0')), findsOneWidget);
    expect(find.byKey(const Key('text_scale_1.25')), findsOneWidget);
    expect(find.text('小'), findsOneWidget);
    expect(find.text('通常'), findsOneWidget);
    expect(find.text('大'), findsOneWidget);
    expect(find.text('文字サイズ設定'), findsOneWidget);
  });

  testWidgets('tapping 大 calls onScaleChanged with 1.25', (tester) async {
    double? changed;
    await tester.pumpWidget(_wrap(onChanged: (s) => changed = s));

    await tester.tap(find.byKey(const Key('text_scale_1.25')));
    await tester.pump();

    expect(changed, 1.25);
  });

  testWidgets('selected state reflects currentScale', (tester) async {
    await tester.pumpWidget(_wrap(currentScale: 1.25));

    final large = tester.widget<RadioListTile<double>>(
      find.byKey(const Key('text_scale_1.25')),
    );
    final normal = tester.widget<RadioListTile<double>>(
      find.byKey(const Key('text_scale_1.0')),
    );
    expect(large.groupValue, 1.25);
    expect(large.value, 1.25);
    expect(normal.groupValue, 1.25);
    expect(normal.value, 1.0);
  });

  testWidgets('tapping 小 calls onScaleChanged with 0.9', (tester) async {
    double? changed;
    await tester.pumpWidget(_wrap(onChanged: (s) => changed = s));

    await tester.tap(find.byKey(const Key('text_scale_0.9')));
    await tester.pump();

    expect(changed, 0.9);
  });
}
