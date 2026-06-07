import 'package:flutter/material.dart';

/// レトロRPG風の色定義。
class RetroPalette {
  RetroPalette._();

  static const bgDark = Color(0xFF1A1A2E);
  static const panelBg = Color(0xFF16213E);
  static const panelBorder = Color(0xFFE2C275);
  static const textNormal = Color(0xFFE8E8E8);
  static const textAccent = Color(0xFFF5E6CA);
  static const gold = Color(0xFFFFD700);
  static const voteAbstain = Color(0xFF888888);
  static const success = Color(0xFF4CAF50);
  static const danger = Color(0xFFF44336);
  static const warning = Color(0xFFFF9800);

  // 社会ムード色
  static const moodCollusion = Color(0xFFB0BEC5);
  static const moodHarmony = Color(0xFF81C784);
  static const moodHealthyDebate = Color(0xFF64B5F6);
  static const moodUnhealthy = Color(0xFFFF8A65);
  static const moodDictatorship = Color(0xFFE57373);
}

/// レトロRPGテーマ
class RetroTheme {
  RetroTheme._();

  static ThemeData get themeData => ThemeData(
        brightness: Brightness.dark,
        primaryColor: RetroPalette.panelBorder,
        scaffoldBackgroundColor: RetroPalette.bgDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: RetroPalette.panelBg,
          foregroundColor: RetroPalette.textAccent,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: RetroPalette.textNormal, fontSize: 14),
          titleLarge: TextStyle(color: RetroPalette.panelBorder, fontSize: 18),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: RetroPalette.panelBorder,
            foregroundColor: RetroPalette.bgDark,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
        ),
      );
}
