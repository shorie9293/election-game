import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/theme/theme_mode_setting.dart';

/// テーマモード設定のリポジトリ
///
/// SharedPreferences にテーマモード識別子を保存・復元する。
class ThemeModeRepository {
  static const String _key = 'election_game_theme_mode';

  const ThemeModeRepository();

  /// 保存されたテーマモードを読み込む。未保存/不正値は null（=system 扱い）。
  Future<ThemeModeSetting?> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_key)) return null;
    final value = prefs.getString(_key);
    if (value == null) return null;
    for (final mode in ThemeModeSetting.values) {
      if (mode.storageKey == value) return mode;
    }
    return null;
  }

  /// テーマモードを保存する。
  Future<void> saveThemeMode(ThemeModeSetting mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.storageKey);
  }
}