import 'package:flutter/material.dart';
import 'package:takamagahara_ui/takamagahara_ui.dart' hide AppKeys;

import 'package:election_game/core/testing/app_keys.dart';
import 'package:election_game/core/theme/retro_theme.dart';
import 'package:election_game/domain/models/quiz_mistake_entry.dart';
import 'package:election_game/domain/models/quiz_question.dart';
import 'package:election_game/domain/repositories/quiz_mistake_repository.dart';
import 'package:election_game/domain/repositories/quiz_repository.dart';
import 'package:election_game/domain/services/quiz_mistake_service.dart';
import 'package:election_game/domain/services/quiz_service.dart';
import 'package:election_game/features/quiz/presentation/quiz_screen.dart';

/// 選挙クイズの間違い復習ノート画面。
///
/// 誤答した問題を持ち越しで記録し、後から見直して再挑戦できる。
/// 未克服（要復習）と克服済みを分けて提示し、誤答回数の多い順に並べる。
/// 試練では [entriesOverride] / [repository] / [questionsOverride] を注入して
/// IO を回避できる。
class QuizMistakeNotebookScreen extends StatefulWidget {
  /// 試練用：null なら [repository] から読み込む。
  final List<QuizMistakeEntry>? entriesOverride;

  /// 復習ノートの永続化先（試練では差し替え可能）。
  final QuizMistakeRepository repository;

  /// 問題バンク（未指定なら標準問題バンク）。
  final List<QuizQuestion>? questionsOverride;

  /// 再挑戦画面へ渡す自己ベスト用リポジトリ（既定は標準実装）。
  final QuizRepository? quizRepository;

  const QuizMistakeNotebookScreen({
    super.key,
    this.entriesOverride,
    this.repository = const SharedPreferencesQuizMistakeRepository(),
    this.questionsOverride,
    this.quizRepository,
  });

  @override
  State<QuizMistakeNotebookScreen> createState() =>
      _QuizMistakeNotebookScreenState();
}

class _QuizMistakeNotebookScreenState extends State<QuizMistakeNotebookScreen> {
  List<QuizMistakeEntry> _entries = const [];
  bool _loading = true;

  /// カテゴリ絞り込み（null = すべて）
  QuizCategory? _category;

  @override
  void initState() {
    super.initState();
    final override = widget.entriesOverride;
    if (override != null) {
      _entries = QuizMistakeService.sort(override);
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final loaded = await widget.repository.load();
      if (!mounted) return;
      setState(() {
        _entries = QuizMistakeService.sort(loaded);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = const [];
        _loading = false;
      });
    }
  }

  List<QuizQuestion> get _bank =>
      widget.questionsOverride ?? QuizService.defaultQuestions();

  QuizQuestion? _questionOf(String questionId) {
    for (final q in _bank) {
      if (q.id == questionId) return q;
    }
    return null;
  }

  List<QuizMistakeEntry> get _visible =>
      QuizMistakeService.filterByCategory(_entries, _category);

  List<QuizMistakeEntry> get _visiblePending =>
      _visible.where((e) => e.isPending).toList(growable: false);

  List<QuizMistakeEntry> get _visibleMastered =>
      _visible.where((e) => e.isMastered).toList(growable: false);

  /// 再挑戦を開始する（未克服の問題のみ出題）。
  Future<void> _startReview() async {
    final reviewBank = QuizMistakeService.buildReviewQuestions(
      _visiblePending,
      bank: _bank,
    );
    if (reviewBank.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          questions: reviewBank,
          mistakeRepository: widget.repository,
          repository: widget.quizRepository ?? const QuizRepository(),
        ),
      ),
    );
    // 復習の結果を反映するため読み直す
    if (!mounted) return;
    final reloaded = widget.entriesOverride ?? await widget.repository.load();
    if (!mounted) return;
    setState(() => _entries = QuizMistakeService.sort(reloaded));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: RetroPalette.panelBg,
        title: const Text(
          '復習ノートを消去しますか？',
          style: TextStyle(color: RetroPalette.gold),
        ),
        content: const Text(
          '記録した誤答の履歴がすべて消えます。この操作は取り消せません。',
          style: TextStyle(color: RetroPalette.textNormal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('やめる',
                style: TextStyle(color: RetroPalette.textAccent)),
          ),
          TextButton(
            key: AppKeys.quizNotebookClearConfirmButton,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('消去する',
                style: TextStyle(color: RetroPalette.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.clear();
    if (!mounted) return;
    setState(() => _entries = const []);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: AppKeys.quizNotebookScreen,
      backgroundColor: RetroPalette.bgDark,
      appBar: AppBar(
        title: const Text('間違い復習ノート'),
        backgroundColor: RetroPalette.panelBg,
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              key: AppKeys.quizNotebookClearButton,
              tooltip: '記録を消去',
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.isEmpty
                ? _buildEmpty()
                : _buildBody(),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      key: AppKeys.quizNotebookEmpty,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.menu_book, color: RetroPalette.textAccent, size: 48),
            SizedBox(height: 12),
            Text(
              'まだ誤答の記録がありません',
              style: TextStyle(color: RetroPalette.textNormal),
            ),
            SizedBox(height: 8),
            Text(
              'クイズで間違えた問題がここに貯まり、後から復習できます。',
              textAlign: TextAlign.center,
              style: TextStyle(color: RetroPalette.textAccent, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final pending = _visiblePending;
    final mastered = _visibleMastered;
    final totalWrong = _visible.fold<int>(0, (sum, e) => sum + e.wrongCount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: AppKeys.quizNotebookSummary,
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
                  '復習の状況',
                  style: TextStyle(
                    color: RetroPalette.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '要復習 ${pending.length} 問 ／ 克服済み ${mastered.length} 問',
                  style: const TextStyle(color: RetroPalette.textNormal),
                ),
                const SizedBox(height: 4),
                Text(
                  'のべ誤答 $totalWrong 回',
                  style: const TextStyle(
                    color: RetroPalette.textAccent,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _categoryChip('すべて', null),
              _categoryChip(QuizCategory.system.label, QuizCategory.system),
              _categoryChip(QuizCategory.policy.label, QuizCategory.policy),
            ],
          ),
          const SizedBox(height: 16),
          if (pending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'この絞り込みに要復習の問題はありません。',
                style: TextStyle(color: RetroPalette.success),
              ),
            )
          else
            for (final entry in pending) _entryCard(entry),
          if (mastered.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              key: AppKeys.quizNotebookMasteredSection,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RetroPalette.panelBg,
                border: Border.all(color: RetroPalette.success),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '克服済み（${mastered.length} 問）',
                    style: const TextStyle(
                      color: RetroPalette.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final entry in mastered)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '・${_questionOf(entry.questionId)?.question ?? entry.questionId}',
                        style: const TextStyle(
                          color: RetroPalette.textAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          DivineButton(
            key: AppKeys.quizNotebookRetryButton,
            onPressed: pending.isEmpty ? null : _startReview,
            width: double.infinity,
            child: Text('要復習 ${pending.length} 問に再挑戦'),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, QuizCategory? category) {
    final selected = _category == category;
    return FilterChip(
      key: AppKeys.quizNotebookCategoryChip(label),
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _category = category),
      backgroundColor: RetroPalette.panelBg,
      selectedColor: RetroPalette.panelBorder,
      labelStyle: TextStyle(
        color: selected ? RetroPalette.gold : RetroPalette.textNormal,
        fontSize: 12,
      ),
    );
  }

  Widget _entryCard(QuizMistakeEntry entry) {
    final question = _questionOf(entry.questionId);
    final choices = question?.choices ?? const <String>[];
    final correctLabel =
        entry.correctIndex < choices.length ? choices[entry.correctIndex] : '（不明）';
    final selectedIndex = entry.lastSelectedIndex;
    final selectedLabel = selectedIndex == null
        ? '未回答'
        : (selectedIndex < choices.length ? choices[selectedIndex] : '（不明）');

    return Container(
      key: AppKeys.quizNotebookEntryCard(entry.questionId),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RetroPalette.panelBg,
        border: Border.all(color: RetroPalette.panelBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question?.question ?? entry.questionId,
                  style: const TextStyle(
                    color: RetroPalette.textNormal,
                    fontWeight: FontWeight.bold,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '×${entry.wrongCount}',
                style: const TextStyle(
                  color: RetroPalette.danger,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${entry.category.label} ／ 直近の誤答 ${_formatDate(entry.lastWrongAt)}',
            style: const TextStyle(
              color: RetroPalette.textAccent,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'あなたの解答: $selectedLabel',
            style: const TextStyle(color: RetroPalette.danger, fontSize: 13),
          ),
          Text(
            '正解: $correctLabel',
            style: const TextStyle(color: RetroPalette.success, fontSize: 13),
          ),
          if (question != null) ...[
            const SizedBox(height: 6),
            Text(
              question.explanation,
              style: const TextStyle(
                color: RetroPalette.textAccent,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}/${two(date.month)}/${two(date.day)}';
  }
}
