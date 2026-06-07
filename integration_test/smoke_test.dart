import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/main.dart' as app;

void main() {
  testWidgets('basic smoke test', (WidgetTester tester) async {
    // Launch the app
    await tester.pumpWidget(app.ElectionGameApp());
    await tester.pumpAndSettle();
    // Verify that the main screen contains the app title
    expect(find.text('Election Game'), findsOneWidget);
  });
}
