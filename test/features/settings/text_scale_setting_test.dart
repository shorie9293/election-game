import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/theme/text_scale_repository.dart';

void main() {
  group('TextScaleSetting', () {
    test('presets are 小/通常/大 with scales 0.9/1.0/1.25', () {
      expect(TextScaleSetting.presets.length, 3);
      expect(TextScaleSetting.presets[0].label, '小');
      expect(TextScaleSetting.presets[0].scale, 0.9);
      expect(TextScaleSetting.presets[1].label, '通常');
      expect(TextScaleSetting.presets[1].scale, 1.0);
      expect(TextScaleSetting.presets[2].label, '大');
      expect(TextScaleSetting.presets[2].scale, 1.25);
    });

    test('isAllowed accepts the three preset scales', () {
      expect(TextScaleSetting.isAllowed(0.9), isTrue);
      expect(TextScaleSetting.isAllowed(1.0), isTrue);
      expect(TextScaleSetting.isAllowed(1.25), isTrue);
    });

    test('isAllowed rejects non-preset scales', () {
      expect(TextScaleSetting.isAllowed(0.5), isFalse);
      expect(TextScaleSetting.isAllowed(1.1), isFalse);
      expect(TextScaleSetting.isAllowed(2.0), isFalse);
    });

    test('isAllowed tolerates numeric error within 0.001', () {
      expect(TextScaleSetting.isAllowed(0.9 + 0.0009), isTrue);
      expect(TextScaleSetting.isAllowed(1.25 - 0.0009), isTrue);
      expect(TextScaleSetting.isAllowed(1.0 + 0.002), isFalse);
    });

    test('fromScale returns preset for known scale, null otherwise', () {
      expect(TextScaleSetting.fromScale(0.9)?.label, '小');
      expect(TextScaleSetting.fromScale(1.0)?.label, '通常');
      expect(TextScaleSetting.fromScale(1.25)?.label, '大');
      expect(TextScaleSetting.fromScale(null), isNull);
      expect(TextScaleSetting.fromScale(0.7), isNull);
      expect(TextScaleSetting.fromScale(999), isNull);
    });

    test('normalized returns the scale for presets, 1.0 otherwise', () {
      expect(TextScaleSetting.normalized(0.9), 0.9);
      expect(TextScaleSetting.normalized(1.25), 1.25);
      expect(TextScaleSetting.normalized(null), 1.0);
      expect(TextScaleSetting.normalized(0.7), 1.0);
      expect(TextScaleSetting.normalized(-1.0), 1.0);
    });
  });
}
