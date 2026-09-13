import '../models/quiz_question.dart';
import '../models/quiz_result.dart';

/// 政策・制度クイズの純粋ロジック（採点・出題）。
///
/// IO を持たず、すべて static な純粋関数として提供する。
class QuizService {
  QuizService._();

  /// 標準問題バンク（選挙制度5問・政策5問）。
  static List<QuizQuestion> defaultQuestions() {
    return [
      QuizQuestion(
        id: 'system_1',
        category: QuizCategory.system,
        question: '衆議院議員の任期は何年か？',
        choices: const ['2年', '3年', '4年', '6年'],
        correctIndex: 2,
        explanation: '衆議院議員の任期は4年です（ただし解散により任期途中で終了することがあります）。',
      ),
      QuizQuestion(
        id: 'system_2',
        category: QuizCategory.system,
        question: '参議院議員の任期は何年か？',
        choices: const ['3年', '4年', '6年', '8年'],
        correctIndex: 2,
        explanation: '参議院議員の任期は6年で、3年ごとに半数が改選されます。',
      ),
      QuizQuestion(
        id: 'system_3',
        category: QuizCategory.system,
        question: '国政選挙で投票できるのは何歳からか？',
        choices: const ['18歳以上', '20歳以上', '21歳以上', '25歳以上'],
        correctIndex: 0,
        explanation: '2016年の公職選挙法改正により、選挙権年齢は18歳以上に引き下げられました。',
      ),
      QuizQuestion(
        id: 'system_4',
        category: QuizCategory.system,
        question: '比例代表制とはどのような制度か？',
        choices: const [
          '各選挙区で最も得票した候補だけが当選する',
          '政党の得票数に応じて議席を配分する',
          '有権者が候補者を指名して首相を選ぶ',
          '抽選で議員を選出する',
        ],
        correctIndex: 1,
        explanation: '比例代表制は、各政党の得票数に応じて議席を配分する制度です。',
      ),
      QuizQuestion(
        id: 'system_5',
        category: QuizCategory.system,
        question: '公職選挙法が定めているものはどれか？',
        choices: const [
          '税金の使い道',
          '選挙運動や投票のルール',
          '会社の就業規則',
          '学校教育のカリキュラム',
        ],
        correctIndex: 1,
        explanation:
            '公職選挙法は、選挙運動の方法・期間・投票手続きなど選挙のルールを定めています。',
      ),
      QuizQuestion(
        id: 'policy_1',
        category: QuizCategory.policy,
        question: '奨学金の拡充や少人数学級の実現は、どの政策分野か？',
        choices: const ['教育政策', '農業政策', '治安政策', '雇用政策'],
        correctIndex: 0,
        explanation: '奨学金・少人数学級などは、学びの機会を支える教育政策の代表例です。',
      ),
      QuizQuestion(
        id: 'policy_2',
        category: QuizCategory.policy,
        question: '再生可能エネルギーの導入支援やCO2削減は、どの政策分野か？',
        choices: const ['経済政策', '環境政策', '医療政策', '教育政策'],
        correctIndex: 1,
        explanation: '気候変動対策や再生可能エネルギー推進は環境政策の中心テーマです。',
      ),
      QuizQuestion(
        id: 'policy_3',
        category: QuizCategory.policy,
        question: '国民皆保険の維持や医療費助成は、どの政策分野か？',
        choices: const ['医療政策', '農業政策', '治安政策', '経済政策'],
        correctIndex: 0,
        explanation: '医療保険制度や医療費の公的助成は医療政策（社会保障）の柱です。',
      ),
      QuizQuestion(
        id: 'policy_4',
        category: QuizCategory.policy,
        question: '最低賃金の引き上げや就労支援は、どの政策分野か？',
        choices: const ['環境政策', '教育政策', '雇用政策', '治安政策'],
        correctIndex: 2,
        explanation: '賃金や働く場を支える施策は雇用政策（労働政策）に分類されます。',
      ),
      QuizQuestion(
        id: 'policy_5',
        category: QuizCategory.policy,
        question: '耕作放棄地の解消や農家への補助金は、どの政策分野か？',
        choices: const ['農業政策', '医療政策', '経済政策', '教育政策'],
        correctIndex: 0,
        explanation: '農地の保全や農業経営への支援は農業政策の役割です。',
      ),
    ];
  }

  /// 解答を採点する。
  ///
  /// - 未回答（null）および範囲外インデックスは不正解として扱う
  /// - [answers] が [questions] より短い場合、不足分は未回答として扱う
  /// - [answers] が長い場合、余剰分は無視する
  /// - [questions] が空の場合は出題数0の [QuizResult] を返す
  static QuizResult grade(List<QuizQuestion> questions, List<int?> answers) {
    final correctIndexes =
        questions.map((q) => q.correctIndex).toList(growable: false);
    final normalized = List<int?>.generate(
      questions.length,
      (i) => i < answers.length ? answers[i] : null,
      growable: false,
    );
    return QuizResult(answers: normalized, correctIndexes: correctIndexes);
  }

  /// カテゴリで問題を絞り込む（元の順序を保持）。
  static List<QuizQuestion> questionsByCategory(
    List<QuizQuestion> questions,
    QuizCategory category,
  ) {
    return questions.where((q) => q.category == category).toList(growable: false);
  }

  /// 出題する問題を選ぶ（指定が無ければ標準問題バンク全体）。
  static List<QuizQuestion> questionsFor({QuizCategory? category}) {
    final all = defaultQuestions();
    if (category == null) return all;
    return questionsByCategory(all, category);
  }
}
