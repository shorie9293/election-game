import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/screens/game_screen.dart';

void main() {
  runApp(
    const ErrorBoundary(
      child: ElectionGameApp(),
    ),
  );
}

class ElectionGameApp extends StatelessWidget {
  const ElectionGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '選挙体験RPG — 天照町',
      theme: RetroTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const GameScreen(),
    );
  }
}
