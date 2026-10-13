import 'package:equatable/equatable.dart';

import 'quiz_question.dart';

/// 誤答復習ノートの1件（永続化対象の不変モデル）。
///
/// ある問題に対して「誤答したことがある」事実を1件として保持する。
/// 同じ問題に再び誤答すると [wrongCount] が増え、[lastSelectedIndex] /
/// [lastWrongAt] が直近のものへ更新される。その後その問題に正解すると
/// [masteredAt] が記録され「克服済み」となる（誤答すれば再び未克服へ戻る）。
///
/// 不変条件:
/// - [questionId] は空文字を許さない
/// - [wrongCount] は 1 以上
/// - [correctIndex] は 0 以上
/// - [lastSelectedIndex] は null か 0 以上
/// - [masteredAt] は [lastWrongAt] より前にはなれない
class QuizMistakeEntry extends Equatable {
  /// 問題の識別子（[QuizQuestion.id]）
  final String questionId;

  /// カテゴリ（選挙制度 / 政策）
  final QuizCategory category;

  /// 正解の選択肢インデックス
  final int correctIndex;

  /// 誤答した回数（1以上）
  final int wrongCount;

  /// 直近の誤答で選んだ選択肢（未回答だった場合は null）
  final int? lastSelectedIndex;

  /// 直近で誤答した日時
  final DateTime lastWrongAt;

  /// 正解して克服した日時（null = 未克服）
  final DateTime? masteredAt;

  const QuizMistakeEntry._({
    required this.questionId,
    required this.category,
    required this.correctIndex,
    required this.wrongCount,
    required this.lastSelectedIndex,
    required this.lastWrongAt,
    required this.masteredAt,
  });

  /// 検証付きファクトリ。不変条件に反する場合は [ArgumentError] を投げる。
  factory QuizMistakeEntry({
    required String questionId,
    required QuizCategory category,
    required int correctIndex,
    int wrongCount = 1,
    int? lastSelectedIndex,
    required DateTime lastWrongAt,
    DateTime? masteredAt,
  }) {
    if (questionId.trim().isEmpty) {
      throw ArgumentError.value(questionId, 'questionId', '問題IDは空にできません');
    }
    if (wrongCount < 1) {
      throw ArgumentError.value(wrongCount, 'wrongCount', '誤答回数は1以上でなければなりません');
    }
    if (correctIndex < 0) {
      throw ArgumentError.value(correctIndex, 'correctIndex', '正解インデックスは0以上でなければなりません');
    }
    if (lastSelectedIndex != null && lastSelectedIndex < 0) {
      throw ArgumentError.value(
        lastSelectedIndex,
        'lastSelectedIndex',
        '選択肢インデックスは0以上でなければなりません',
      );
    }
    if (masteredAt != null && masteredAt.isBefore(lastWrongAt)) {
      throw ArgumentError.value(masteredAt, 'masteredAt', '克服日時が誤答日時より前になっています');
    }
    return QuizMistakeEntry._(
      questionId: questionId,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex,
      lastWrongAt: lastWrongAt,
      masteredAt: masteredAt,
    );
  }

  /// 未克服（要復習）かどうか
  bool get isPending => masteredAt == null;

  /// 克服済みかどうか
  bool get isMastered => masteredAt != null;

  /// 直近の誤答が未回答だったかどうか
  bool get wasUnanswered => lastSelectedIndex == null;

  /// [clearMastered] を true にすると [masteredAt] を null へ戻せる
  /// （copyWith の null は「変更なし」と区別できないため）。
  QuizMistakeEntry copyWith({
    QuizCategory? category,
    int? correctIndex,
    int? wrongCount,
    int? lastSelectedIndex,
    DateTime? lastWrongAt,
    DateTime? masteredAt,
    bool clearMastered = false,
  }) {
    return QuizMistakeEntry(
      questionId: questionId,
      category: category ?? this.category,
      correctIndex: correctIndex ?? this.correctIndex,
      wrongCount: wrongCount ?? this.wrongCount,
      lastSelectedIndex: lastSelectedIndex ?? this.lastSelectedIndex,
      lastWrongAt: lastWrongAt ?? this.lastWrongAt,
      masteredAt: clearMastered ? null : (masteredAt ?? this.masteredAt),
    );
  }

  /// JSON へ変換する（永続化用）。
  Map<String, Object?> toJson() => {
        'questionId': questionId,
        'category': category.name,
        'correctIndex': correctIndex,
        'wrongCount': wrongCount,
        'lastSelectedIndex': lastSelectedIndex,
        'lastWrongAt': lastWrongAt.toIso8601String(),
        'masteredAt': masteredAt?.toIso8601String(),
      };

  /// JSON から復元する。不正な内容は [FormatException] を投げる。
  factory QuizMistakeEntry.fromJson(Map<String, Object?> json) {
    final id = json['questionId'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('questionId が不正です');
    }
    final categoryName = json['category'];
    QuizCategory? category;
    for (final candidate in QuizCategory.values) {
      if (candidate.name == categoryName) {
        category = candidate;
        break;
      }
    }
    if (category == null) {
      throw FormatException('未知のカテゴリです: $categoryName');
    }
    final correctIndex = json['correctIndex'];
    if (correctIndex is! int) {
      throw const FormatException('correctIndex が不正です');
    }
    final wrongCount = json['wrongCount'];
    if (wrongCount is! int) {
      throw const FormatException('wrongCount が不正です');
    }
    final lastSelectedIndex = json['lastSelectedIndex'];
    if (lastSelectedIndex != null && lastSelectedIndex is! int) {
      throw const FormatException('lastSelectedIndex が不正です');
    }
    final lastWrongAt = _parseDate(json['lastWrongAt'], 'lastWrongAt');
    final masteredRaw = json['masteredAt'];
    final masteredAt = masteredRaw == null
        ? null
        : _parseDate(masteredRaw, 'masteredAt');

    return QuizMistakeEntry(
      questionId: id,
      category: category,
      correctIndex: correctIndex,
      wrongCount: wrongCount,
      lastSelectedIndex: lastSelectedIndex as int?,
      lastWrongAt: lastWrongAt,
      masteredAt: masteredAt,
    );
  }

  static DateTime _parseDate(Object? raw, String field) {
    if (raw is! String) {
      throw FormatException('$field が不正です');
    }
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      throw FormatException('$field の日時を解釈できません: $raw');
    }
    return parsed;
  }

  @override
  List<Object?> get props =>
      [questionId, category, correctIndex, wrongCount, lastSelectedIndex, lastWrongAt, masteredAt];
}
