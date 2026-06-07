import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:election_game/core/error/error_boundary.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/core/infrastructure/hive_game_repository.dart';
import 'package:election_game/features/shared/viewmodels/game_notifier.dart';
import 'package:election_game/screens/game_screen.dart';

final _repo = HiveGameRepository();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _repo.init();

  runApp(
    ProviderScope(
      overrides: [
        gameNotifierProvider.overrideWith((ref) {
          return GameNotifier(_repo, GameNotifier.emptyState());
        }),
      ],
      child: const ErrorBoundary(
        child: ElectionGameApp(),
      ),
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
      home: const ErrorBoundaryWidget(child: GameScreen()),
    );
  }
}
