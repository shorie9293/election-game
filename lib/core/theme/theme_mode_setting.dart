import 'package:flutter/material.dart';

/// テーマモード設定（ライト／ダーク／システム）
enum ThemeModeSetting {
  light('light', 'ライト', Icons.light_mode),
  dark('dark', 'ダーク', Icons.dark_mode),
  system('system', 'システム', Icons.brightness_auto);

  const ThemeModeSetting(this.storageKey, this.label, this.icon);

  /// SharedPreferences に保存する識別子
  final String storageKey;

  /// 画面表示用ラベル
  final String label;

  /// 選択肢表示用アイコン
  final IconData icon;

  /// 保存キーから復元する。未保存(null)/不正値は system 扱い。
  static ThemeModeSetting fromStorageKey(String? key) {
    for (final mode in ThemeModeSetting.values) {
      if (mode.storageKey == key) return mode;
    }
    return ThemeModeSetting.system;
  }

  /// 選択順に巡回する（light→dark→system→light）。
  ThemeModeSetting get next {
    final index = ThemeModeSetting.values.indexOf(this);
    return ThemeModeSetting
        .values[(index + 1) % ThemeModeSetting.values.length];
  }

  /// Flutter の ThemeMode へ変換する。
  ThemeMode toThemeMode() {
    switch (this) {
      case ThemeModeSetting.light:
        return ThemeMode.light;
      case ThemeModeSetting.dark:
        return ThemeMode.dark;
      case ThemeModeSetting.system:
        return ThemeMode.system;
    }
  }
}