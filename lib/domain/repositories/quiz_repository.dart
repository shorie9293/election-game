import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_result.dart';

/// クイズの自己ベスト・挑戦回数を SharedPreferences に永続化するリポジトリ。
class QuizRepository {
  static const bestCorrectKey = 'election_quiz_best_correct';
  static const bestTotalKey = 'election_quiz_best_total';
  static const attemptsKey = 'election_quiz_attempts';

  const QuizRepository();

  /// 自己ベストを読み込む。記録が無い・破損している場合は null。
  Future<QuizBestScore?> loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    final correct = prefs.getInt(bestCorrectKey);
    final total = prefs.getInt(bestTotalKey);
    final attempts = prefs.getInt(attemptsKey) ?? 0;

    if (correct == null || total == null) return null;
    // 破損データ（負値・正答数が出題数を超過・出題数0）は安全に無視する
    if (correct < 0 || total <= 0 || correct > total) return null;

    return QuizBestScore(
      correctCount: correct,
      total: total,
      attempts: attempts < 0 ? 0 : attempts,
    );
  }

  /// 累計挑戦回数を読み込む。破損時は 0。
  Future<int> loadAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = prefs.getInt(attemptsKey) ?? 0;
    return attempts < 0 ? 0 : attempts;
  }

  /// 採点結果を保存する。
  ///
  /// - 挑戦回数を1増やす
  /// - 正答数が自己ベストを上回った場合のみベストを更新する
  ///   （同点なら既存のベストを保持）
  /// 更新後の自己ベストを返す。
  Future<QuizBestScore> saveResult(QuizResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadBest();
    final attempts = (await loadAttempts()) + 1;

    final previousBestCorrect = current?.correctCount ?? -1;
    final isNewBest = result.correctCount > previousBestCorrect;
    final best = isNewBest || current == null
        ? QuizBestScore(
            correctCount: result.correctCount,
            total: result.total,
            attempts: attempts,
          )
        : current.copyWith(attempts: attempts);

    await prefs.setInt(attemptsKey, attempts);
    if (isNewBest || current == null) {
      await prefs.setInt(bestCorrectKey, best.correctCount);
      await prefs.setInt(bestTotalKey, best.total);
    }
    return best;
  }

  /// 記録を全消去する（試練・デバッグ用）。
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(bestCorrectKey);
    await prefs.remove(bestTotalKey);
    await prefs.remove(attemptsKey);
  }
}
