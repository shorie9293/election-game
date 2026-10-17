import 'package:flutter/material.dart';

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/services/quiz_service.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

/// 政策・制度クイズの難易度選択画面。
///
/// 初級・中級・上級・すべて（全問）から難易度を選び、
/// 選んだ難易度に合致する問題のみを出題するクイズ画面へ遷移する。
class QuizDifficultyScreen extends StatelessWidget {
  const QuizDifficultyScreen({super.key});

  void _open(BuildContext context, QuizDifficulty? difficulty) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => difficulty == null
            ? const QuizScreen()
            : QuizScreen(difficulty: difficulty),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaults = QuizService.defaultQuestions();

    return Scaffold(
      key: AppKeys.quizDifficultyScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('政策・制度クイズ'),
        backgroundColor: RetroPalette.panelBg,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '難易度を選んでください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: RetroPalette.textAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '自分の理解度に合った難易度に挑戦しましょう',
                textAlign: TextAlign.center,
                style: TextStyle(color: RetroPalette.textNormal, fontSize: 13),
              ),
              const SizedBox(height: 24),
              for (final d in QuizDifficulty.values) ...[
                _DifficultyButton(
                  optionKey: AppKeys.quizDifficultyOption(d),
                  label: '${d.label}（'
                      '${QuizService.countByDifficulty(defaults, d)}問）',
                  onPressed: () => _open(context, d),
                ),
                const SizedBox(height: 12),
              ],
              _DifficultyButton(
                optionKey: AppKeys.quizDifficultyAll,
                label: 'すべて（全問）',
                onPressed: () => _open(context, null),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  final Key optionKey;
  final String label;
  final VoidCallback onPressed;

  const _DifficultyButton({
    required this.optionKey,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: optionKey,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              label,
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
