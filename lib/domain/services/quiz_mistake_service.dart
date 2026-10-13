import '../models/quiz_mistake_entry.dart';
import '../models/quiz_question.dart';
import '../models/quiz_result.dart';
import 'quiz_service.dart';

/// 誤答復習ノートの純粋ロジック（記録・絞り込み・並び替え・再挑戦の出題）。
///
/// IO を持たず、すべて static な純粋関数として提供する。
/// 時刻は必ず引数（[record] の `now`）で受け取り、内部で `DateTime.now()` を
/// 呼ばない（暦が進んでも試練が赤化しないようにするため）。
class QuizMistakeService {
  QuizMistakeService._();

  /// 採点結果を既存の復習ノートへ反映した新しい一覧を返す。
  ///
  /// - 誤答（未回答・範囲外インデックスを含む）は新規追加または加算更新する
  ///   （[QuizMistakeEntry.wrongCount] +1・直近の誤答選択と日時を更新・未克服へ戻す）
  /// - 正解した問題に既存エントリがあれば克服済みにする（[QuizMistakeEntry.masteredAt] = now）
  /// - 正解した問題にエントリが無ければ何も記録しない
  /// - [questions] に無い ID のエントリは変更せず保持する
  /// - 同じ問題に誤答した後に正解した場合でも、誤答履歴（wrongCount）は失わない
  /// - [answers] が [questions] より短い場合、不足分は未回答として扱う
  static List<QuizMistakeEntry> record(
    List<QuizMistakeEntry> existing,
    List<QuizQuestion> questions,
    QuizResult result, {
    required DateTime now,
  }) {
    final byId = <String, QuizMistakeEntry>{
      for (final entry in existing) entry.questionId: entry,
    };

    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      final answerIndex = i < result.answers.length ? result.answers[i] : null;
      final isCorrect = answerIndex == question.correctIndex;
      final previous = byId[question.id];

      if (isCorrect) {
        if (previous != null && previous.isPending) {
          byId[question.id] = previous.copyWith(
            category: question.category,
            correctIndex: question.correctIndex,
            masteredAt: now,
          );
        }
        continue;
      }

      byId[question.id] = previous == null
          ? QuizMistakeEntry(
              questionId: question.id,
              category: question.category,
              correctIndex: question.correctIndex,
              lastSelectedIndex: answerIndex,
              lastWrongAt: now,
            )
          : previous.copyWith(
              category: question.category,
              correctIndex: question.correctIndex,
              wrongCount: previous.wrongCount + 1,
              lastSelectedIndex: answerIndex,
              lastWrongAt: now,
              clearMastered: true,
            );
    }

    return sort(byId.values.toList(growable: false));
  }

  /// 未克服（要復習）のエントリのみを返す（並びは [sort] に従う）。
  static List<QuizMistakeEntry> pending(List<QuizMistakeEntry> entries) =>
      sort(entries.where((e) => e.isPending).toList(growable: false));

  /// 克服済みのエントリのみを返す（並びは [sort] に従う）。
  static List<QuizMistakeEntry> mastered(List<QuizMistakeEntry> entries) =>
      sort(entries.where((e) => e.isMastered).toList(growable: false));

  /// カテゴリで絞り込む（null なら全件・並びは [sort] に従う）。
  static List<QuizMistakeEntry> filterByCategory(
    List<QuizMistakeEntry> entries,
    QuizCategory? category,
  ) {
    if (category == null) return sort(entries);
    return sort(entries.where((e) => e.category == category).toList(growable: false));
  }

  /// 決定論的な並びへ整える（入力は変更しない）。
  ///
  /// - 未克服を克服済みより先に置く
  /// - 未克服どうしは誤答回数の多い順 → 直近の誤答が新しい順 → 問題ID昇順
  /// - 克服済みどうしは克服日時の新しい順 → 問題ID昇順
  static List<QuizMistakeEntry> sort(List<QuizMistakeEntry> entries) {
    final list = List<QuizMistakeEntry>.of(entries);
    list.sort((a, b) {
      if (a.isPending != b.isPending) return a.isPending ? -1 : 1;
      if (a.isPending) {
        final byCount = b.wrongCount.compareTo(a.wrongCount);
        if (byCount != 0) return byCount;
        final byDate = b.lastWrongAt.compareTo(a.lastWrongAt);
        if (byDate != 0) return byDate;
      } else {
        final byMastered = b.masteredAt!.compareTo(a.masteredAt!);
        if (byMastered != 0) return byMastered;
      }
      return a.questionId.compareTo(b.questionId);
    });
    return List<QuizMistakeEntry>.unmodifiable(list);
  }

  /// 再挑戦用の出題リスト（未克服の問題のみ・復習ノートの並び順）。
  ///
  /// [bank] に存在しない ID のエントリは無視する（問題バンク改訂への耐久）。
  static List<QuizQuestion> buildReviewQuestions(
    List<QuizMistakeEntry> entries, {
    List<QuizQuestion>? bank,
  }) {
    final questions = bank ?? QuizService.defaultQuestions();
    final byId = <String, QuizQuestion>{for (final q in questions) q.id: q};
    final result = <QuizQuestion>[];
    for (final entry in pending(entries)) {
      final question = byId[entry.questionId];
      if (question != null) result.add(question);
    }
    return List<QuizQuestion>.unmodifiable(result);
  }
}
