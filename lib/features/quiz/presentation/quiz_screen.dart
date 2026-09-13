import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/models/quiz_result.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';
import 'package:election_game/domain/services/quiz_service.dart';

/// 政策・制度クイズ（理解度テスト）画面。
///
/// 1問ずつ出題し、選択と同時に正誤と解説を提示する。
/// 全問終了後に理解度（正答率・段階ラベル・合格判定）と間違えた問題の
/// 振り返り、自己ベストを表示する。
class QuizScreen extends StatefulWidget {
  /// 自己ベスト永続化リポジトリ（試練では差し替え可能）
  final QuizRepository repository;

  /// 出題する問題（未指定なら標準問題バンク）
  final List<QuizQuestion>? questions;

  const QuizScreen({
    super.key,
    this.repository = const QuizRepository(),
    this.questions,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<QuizQuestion> _questions;
  late List<int?> _answers;
  int _index = 0;
  bool _answered = false;
  int? _selected;
  QuizResult? _result;
  QuizBestScore? _best;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _resetSession();
    _loadBest();
  }

  void _resetSession() {
    _questions = widget.questions ?? QuizService.defaultQuestions();
    _answers = List<int?>.filled(_questions.length, null);
    _index = 0;
    _answered = false;
    _selected = null;
    _result = null;
  }

  Future<void> _loadBest() async {
    final best = await widget.repository.loadBest();
    if (!mounted) return;
    setState(() => _best = best);
  }

  void _select(int choiceIndex) {
    if (_answered) return;
    setState(() {
      _selected = choiceIndex;
      _answers[_index] = choiceIndex;
      _answered = true;
    });
  }

  Future<void> _next() async {
    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _answered = false;
        _selected = null;
      });
      return;
    }
    final result = QuizService.grade(_questions, _answers);
    setState(() {
      _result = result;
      _saving = true;
    });
    final best = await widget.repository.saveResult(result);
    if (!mounted) return;
    setState(() {
      _best = best;
      _saving = false;
    });
  }

  void _retry() {
    setState(_resetSession);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('政策・制度クイズ', key: AppKeys.quizTitle),
        backgroundColor: RetroPalette.panelBg,
      ),
      body: SafeArea(
        child: _result == null ? _buildQuestion() : _buildResult(_result!),
      ),
    );
  }

  Widget _buildQuestion() {
    final q = _questions[_index];
    final isLast = _index == _questions.length - 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '問 ${_index + 1} / ${_questions.length}',
                key: AppKeys.quizProgress,
                style: const TextStyle(
                  color: RetroPalette.textAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                key: AppKeys.quizCategory,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RetroPalette.panelBg,
                  border: Border.all(color: RetroPalette.panelBorder),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  q.category.label,
                  style: const TextStyle(color: RetroPalette.gold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RetroPalette.panelBg,
              border: Border.all(color: RetroPalette.panelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              q.question,
              key: AppKeys.quizQuestionText,
              style: const TextStyle(
                color: RetroPalette.textNormal,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < q.choices.length; i++) ...[
            _ChoiceButton(
              choiceKey: AppKeys.quizChoice(i),
              label: q.choices[i],
              state: _choiceState(i, q),
              onPressed: _answered ? null : () => _select(i),
            ),
            const SizedBox(height: 8),
          ],
          if (_answered) ...[
            const SizedBox(height: 8),
            Container(
              key: AppKeys.quizFeedback,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(
                  color: q.isCorrect(_selected)
                      ? RetroPalette.success
                      : RetroPalette.danger,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.isCorrect(_selected) ? '正解！' : '不正解…',
                    style: TextStyle(
                      color: q.isCorrect(_selected)
                          ? RetroPalette.success
                          : RetroPalette.danger,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    key: AppKeys.quizExplanation,
                    style: const TextStyle(
                      color: RetroPalette.textNormal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            DivineButton(
              key: AppKeys.quizNextButton,
              onPressed: _next,
              width: double.infinity,
              child: Text(isLast ? '結果を見る' : '次の問題へ'),
            ),
          ],
        ],
      ),
    );
  }

  _ChoiceState _choiceState(int i, QuizQuestion q) {
    if (!_answered) return _ChoiceState.idle;
    if (i == q.correctIndex) return _ChoiceState.correct;
    if (i == _selected) return _ChoiceState.wrong;
    return _ChoiceState.idle;
  }

  Widget _buildResult(QuizResult result) {
    final missed = result.missedIndexes;
    return SingleChildScrollView(
      key: AppKeys.quizResultView,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: RetroPalette.panelBg,
              border: Border.all(
                color: result.isPassed
                    ? RetroPalette.gold
                    : RetroPalette.panelBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  result.rankLabel,
                  key: AppKeys.quizResultRank,
                  style: TextStyle(
                    color: result.isPassed
                        ? RetroPalette.gold
                        : RetroPalette.textAccent,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${result.correctCount} / ${result.total} 問正解（${result.percent}%）',
                  key: AppKeys.quizResultScore,
                  style: const TextStyle(
                    color: RetroPalette.textNormal,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.isPassed ? '合格ライン達成 🎉' : '合格ラインは70%です',
                  key: AppKeys.quizResultBadge,
                  style: TextStyle(
                    color: result.isPassed
                        ? RetroPalette.success
                        : RetroPalette.warning,
                  ),
                ),
                if (_best != null && _best!.hasRecord) ...[
                  const SizedBox(height: 8),
                  Text(
                    '自己ベスト: ${_best!.correctCount} / ${_best!.total}'
                    '（${_best!.percent}%）'
                    '${_saving ? ' 保存中…' : ''}',
                    key: AppKeys.quizBestScore,
                    style: const TextStyle(
                      color: RetroPalette.textAccent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            key: AppKeys.quizResultMissed,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: RetroPalette.panelBg,
              border: Border.all(color: RetroPalette.panelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '振り返り',
                  style: TextStyle(
                    color: RetroPalette.textAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (missed.isEmpty)
                  const Text(
                    '全問正解です。素晴らしい理解度です！',
                    style: TextStyle(color: RetroPalette.success),
                  )
                else
                  for (final i in missed) ...[
                    Text(
                      '・${_questions[i].question}',
                      style: const TextStyle(color: RetroPalette.textNormal),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        _questions[i].explanation,
                        style: const TextStyle(
                          color: RetroPalette.textAccent,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          DivineButton(
            key: AppKeys.quizRetryButton,
            onPressed: _retry,
            width: double.infinity,
            child: const Text('もう一度挑戦'),
          ),
          const SizedBox(height: 8),
          DivineButton(
            key: AppKeys.quizCloseButton,
            onPressed: () => Navigator.of(context).maybePop(),
            width: double.infinity,
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }
}

/// 選択肢の表示状態
enum _ChoiceState { idle, correct, wrong }

class _ChoiceButton extends StatelessWidget {
  final Key choiceKey;
  final String label;
  final _ChoiceState state;
  final VoidCallback? onPressed;

  const _ChoiceButton({
    required this.choiceKey,
    required this.label,
    required this.state,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    Color border;
    Color text;
    IconData? icon;
    switch (state) {
      case _ChoiceState.correct:
        border = RetroPalette.success;
        text = RetroPalette.success;
        icon = Icons.check_circle;
      case _ChoiceState.wrong:
        border = RetroPalette.danger;
        text = RetroPalette.danger;
        icon = Icons.cancel;
      case _ChoiceState.idle:
        border = RetroPalette.panelBorder;
        text = RetroPalette.textNormal;
        icon = null;
    }

    return Container(
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: choiceKey,
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: text, height: 1.4),
                  ),
                ),
                if (icon != null) Icon(icon, color: text, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
