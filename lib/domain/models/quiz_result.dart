import 'package:equatable/equatable.dart';

/// クイズの採点結果を表す不変モデル。
///
/// [answers] は各問で選択したインデックス（未回答は null）、
/// [correctIndexes] は各問の正解インデックス。両者の長さは一致しなければならない。
class QuizResult extends Equatable {
  /// 各問の解答（null = 未回答）
  final List<int?> answers;

  /// 各問の正解インデックス
  final List<int> correctIndexes;

  /// 正答数
  final int correctCount;

  /// 出題数
  final int total;

  const QuizResult._({
    required this.answers,
    required this.correctIndexes,
    required this.correctCount,
    required this.total,
  });

  /// 採点付きファクトリ。解答数と正解数が一致しない場合は [ArgumentError]。
  /// 範囲外の解答インデックスは不正解として扱う（例外にはしない）。
  factory QuizResult({
    required List<int?> answers,
    required List<int> correctIndexes,
  }) {
    if (answers.length != correctIndexes.length) {
      throw ArgumentError(
        '解答数(${answers.length})と正解数(${correctIndexes.length})が一致しません',
      );
    }
    var correct = 0;
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] == correctIndexes[i]) correct++;
    }
    return QuizResult._(
      answers: List.unmodifiable(answers),
      correctIndexes: List.unmodifiable(correctIndexes),
      correctCount: correct,
      total: answers.length,
    );
  }

  /// 正答率（0.0〜1.0）。出題数0の場合は 0.0。
  double get ratio => total == 0 ? 0.0 : correctCount / total;

  /// 正答率（0〜100の整数・四捨五入）
  int get percent => (ratio * 100).round();

  /// 合格判定（正答率70%以上）。出題数0は不合格。
  bool get isPassed => total > 0 && ratio >= 0.7;

  /// 全問正解かどうか
  bool get isPerfect => total > 0 && correctCount == total;

  /// 不正解だった問題のインデックス一覧（未回答を含む）
  List<int> get missedIndexes {
    final missed = <int>[];
    for (var i = 0; i < answers.length; i++) {
      if (answers[i] != correctIndexes[i]) missed.add(i);
    }
    return missed;
  }

  /// 理解度の段階ラベル（5段階）
  String get rankLabel {
    if (total == 0) return '未挑戦';
    if (isPerfect) return '選挙マスター';
    if (ratio >= 0.8) return 'よく理解している';
    if (ratio >= 0.7) return '合格ライン';
    if (ratio >= 0.5) return 'もう一息';
    return '復習しよう';
  }

  @override
  List<Object?> get props => [answers, correctIndexes, correctCount, total];
}

/// 自己ベスト記録（永続化用）。
class QuizBestScore extends Equatable {
  /// 最高正答数
  final int correctCount;

  /// そのときの出題数
  final int total;

  /// 累計挑戦回数
  final int attempts;

  const QuizBestScore({
    required this.correctCount,
    required this.total,
    this.attempts = 0,
  });

  /// 記録なしを表す
  static const empty = QuizBestScore(correctCount: 0, total: 0, attempts: 0);

  /// 記録が存在するか
  bool get hasRecord => total > 0;

  /// 正答率（0.0〜1.0）
  double get ratio => total == 0 ? 0.0 : correctCount / total;

  /// 正答率（0〜100の整数）
  int get percent => (ratio * 100).round();

  QuizBestScore copyWith({int? correctCount, int? total, int? attempts}) {
    return QuizBestScore(
      correctCount: correctCount ?? this.correctCount,
      total: total ?? this.total,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  List<Object?> get props => [correctCount, total, attempts];
}
