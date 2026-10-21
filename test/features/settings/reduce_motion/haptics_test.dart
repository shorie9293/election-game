import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hapticTap', () {
    test('例外を投げずに完了する（await しない）', () {
      expect(hapticTap, returnsNormally);
    });

    test('連続呼び出しでも例外を投げない', () {
      hapticTap();
      hapticTap();
      hapticTap();
      expect(true, isTrue);
    });
  });
}
