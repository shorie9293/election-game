import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/core/theme/text_scale_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextScaleRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('loadScale returns null when unset', () async {
      final repo = const TextScaleRepository();
      expect(await repo.loadScale(), isNull);
    });

    test('save + load round-trip for each preset', () async {
      final repo = const TextScaleRepository();
      for (final scale in [0.9, 1.0, 1.25]) {
        SharedPreferences.setMockInitialValues({});
        await repo.saveScale(scale);
        expect(await repo.loadScale(), scale);
      }
    });

    test('loadScale returns null for stored invalid value', () async {
      SharedPreferences.setMockInitialValues({
        'election_game_text_scale': 1.7,
      });
      final repo = const TextScaleRepository();
      expect(await repo.loadScale(), isNull);
    });

    test('saveScale rejects disallowed values with ArgumentError', () async {
      final repo = const TextScaleRepository();
      expect(
        () => repo.saveScale(1.7),
        throwsArgumentError,
      );
      expect(
        () => repo.saveScale(0.0),
        throwsArgumentError,
      );
    });
  });
}
