import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';

void main() {
  group('ThemeModeSetting', () {
    group('fromStorageKey', () {
      test('light キーで light を返す', () {
        expect(ThemeModeSetting.fromStorageKey('light'),
            ThemeModeSetting.light);
      });

      test('dark キーで dark を返す', () {
        expect(
            ThemeModeSetting.fromStorageKey('dark'), ThemeModeSetting.dark);
      });

      test('system キーで system を返す', () {
        expect(ThemeModeSetting.fromStorageKey('system'),
            ThemeModeSetting.system);
      });

      test('null は system を返す', () {
        expect(ThemeModeSetting.fromStorageKey(null),
            ThemeModeSetting.system);
      });

      test('不正値は system を返す', () {
        expect(ThemeModeSetting.fromStorageKey('unknown'),
            ThemeModeSetting.system);
        expect(ThemeModeSetting.fromStorageKey(''),
            ThemeModeSetting.system);
      });
    });

    group('next', () {
      test('light→dark→system→light と巡回する', () {
        expect(ThemeModeSetting.light.next, ThemeModeSetting.dark);
        expect(ThemeModeSetting.dark.next, ThemeModeSetting.system);
        expect(ThemeModeSetting.system.next, ThemeModeSetting.light);
      });
    });

    group('toThemeMode', () {
      test('各値が ThemeMode に対応する', () {
        expect(ThemeModeSetting.light.toThemeMode(), ThemeMode.light);
        expect(ThemeModeSetting.dark.toThemeMode(), ThemeMode.dark);
        expect(ThemeModeSetting.system.toThemeMode(), ThemeMode.system);
      });
    });

    group('label', () {
      test('表示ラベルが定義されている', () {
        expect(ThemeModeSetting.light.label, 'ライト');
        expect(ThemeModeSetting.dark.label, 'ダーク');
        expect(ThemeModeSetting.system.label, 'システム');
      });
    });

    group('storageKey', () {
      test('保存キーが fromStorageKey で復元できる', () {
        for (final mode in ThemeModeSetting.values) {
          expect(ThemeModeSetting.fromStorageKey(mode.storageKey), mode);
        }
      });
    });
  });
}