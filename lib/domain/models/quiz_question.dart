import 'package:equatable/equatable.dart';

/// クイズのカテゴリ（政策 / 選挙制度）
enum QuizCategory {
  system('選挙制度'),
  policy('政策');

  const QuizCategory(this.label);

  /// 日本語ラベル
  final String label;
}

/// 政策・制度クイズの1問を表す不変モデル。
///
/// 不変条件:
/// - [id] / [question] / [explanation] は空文字を許さない
/// - [choices] は2件以上
/// - [correctIndex] は `0 <= correctIndex < choices.length`
class QuizQuestion extends Equatable {
  /// 問題の識別子
  final String id;

  /// カテゴリ（選挙制度 / 政策）
  final QuizCategory category;

  /// 問題文
  final String question;

  /// 選択肢（2件以上）
  final List<String> choices;

  /// 正解の選択肢インデックス
  final int correctIndex;

  /// 解説文
  final String explanation;

  const QuizQuestion._({
    required this.id,
    required this.category,
    required this.question,
    required this.choices,
    required this.correctIndex,
    required this.explanation,
  });

  /// 検証付きファクトリ。不変条件に反する場合は [ArgumentError] を投げる。
  factory QuizQuestion({
    required String id,
    required QuizCategory category,
    required String question,
    required List<String> choices,
    required int correctIndex,
    required String explanation,
  }) {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id', '問題IDは空にできません');
    }
    if (question.trim().isEmpty) {
      throw ArgumentError.value(question, 'question', '問題文は空にできません');
    }
    if (explanation.trim().isEmpty) {
      throw ArgumentError.value(explanation, 'explanation', '解説は空にできません');
    }
    if (choices.length < 2) {
      throw ArgumentError.value(choices, 'choices', '選択肢は2件以上必要です');
    }
    if (correctIndex < 0 || correctIndex >= choices.length) {
      throw ArgumentError.value(
        correctIndex,
        'correctIndex',
        '正解インデックスは選択肢の範囲内でなければなりません',
      );
    }
    return QuizQuestion._(
      id: id,
      category: category,
      question: question,
      choices: List.unmodifiable(choices),
      correctIndex: correctIndex,
      explanation: explanation,
    );
  }

  QuizQuestion copyWith({
    String? id,
    QuizCategory? category,
    String? question,
    List<String>? choices,
    int? correctIndex,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
    );
  }

  /// 指定インデックスが正解かどうか（未回答 null は常に不正解）。
  bool isCorrect(int? answerIndex) => answerIndex == correctIndex;

  @override
  List<Object?> get props =>
      [id, category, question, choices, correctIndex, explanation];
}
