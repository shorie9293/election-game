import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:election_game/core/theme/theme_mode_repository.dart';
import 'package:election_game/core/theme/theme_mode_setting.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeModeRepository', () {
    late ThemeModeRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = const ThemeModeRepository();
    });

    test('未保存時は loadThemeMode が null を返す', () async {
      expect(await repository.loadThemeMode(), isNull);
    });

    test('saveThemeMode 後に loadThemeMode で復元できる（light）', () async {
      await repository.saveThemeMode(ThemeModeSetting.light);
      expect(
          await repository.loadThemeMode(), ThemeModeSetting.light);
    });

    test('saveThemeMode 後に loadThemeMode で復元できる（dark）', () async {
      await repository.saveThemeMode(ThemeModeSetting.dark);
      expect(await repository.loadThemeMode(), ThemeModeSetting.dark);
    });

    test('saveThemeMode 後に loadThemeMode で復元できる（system）', () async {
      await repository.saveThemeMode(ThemeModeSetting.system);
      expect(
          await repository.loadThemeMode(), ThemeModeSetting.system);
    });

    test('保存済みでも不正値があれば null を返す', () async {
      SharedPreferences.setMockInitialValues({
        'election_game_theme_mode': 'invalid_value',
      });
      expect(await repository.loadThemeMode(), isNull);
    });
  });
}