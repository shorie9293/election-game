/// 選挙結果の振り返りカード（共有用テキスト）。
///
/// アーカイブエントリ1回分を、SNS等でそのまま貼れる整形テキストにするための
/// ドメインモデル。不変条件は非constコンストラクタ本体で検証する。
class ElectionRecap {
  /// 元選挙のID
  final String electionId;

  /// 選挙タイトル（空文字禁止）
  final String title;

  /// 規模ラベル（村/町/市）
  final String scaleLabel;

  /// 当選者名（空文字禁止）
  final String winnerName;

  /// 当選者の得票数（負値禁止）
  final int winnerVotes;

  /// 総得票数（負値禁止）
  final int totalVotes;

  /// 2位候補の得票数（負値禁止）
  final int runnerUpVotes;

  /// 選挙が行われた日時（不明ならnull）
  final DateTime? occurredAt;

  /// 投票率（0.0-1.0、不明ならnull）
  final double? turnoutRate;

  /// 関心ラベル（例: '高い関心' / 'ふつう' / '低い関心'。rateがnullならnull）
  final String? turnoutLabel;

  /// 不変条件は本体で検証（ArgumentError を throw・assert 不使用）
  ElectionRecap({
    required this.electionId,
    required this.title,
    required this.scaleLabel,
    required this.winnerName,
    required this.winnerVotes,
    required this.totalVotes,
    required this.runnerUpVotes,
    this.occurredAt,
    this.turnoutRate,
    this.turnoutLabel,
  }) {
    if (title.isEmpty) {
      throw ArgumentError.value(title, 'title', '空文字は禁止');
    }
    if (winnerName.isEmpty) {
      throw ArgumentError.value(winnerName, 'winnerName', '空文字は禁止');
    }
    if (winnerVotes < 0) {
      throw ArgumentError.value(winnerVotes, 'winnerVotes', '負値は禁止');
    }
    if (totalVotes < 0) {
      throw ArgumentError.value(totalVotes, 'totalVotes', '負値は禁止');
    }
    if (runnerUpVotes < 0) {
      throw ArgumentError.value(runnerUpVotes, 'runnerUpVotes', '負値は禁止');
    }
    if (turnoutRate != null && (turnoutRate! < 0 || turnoutRate! > 1)) {
      throw ArgumentError.value(turnoutRate, 'turnoutRate', '0.0-1.0 の範囲外');
    }
    if (turnoutLabel != null && turnoutRate == null) {
      throw ArgumentError.value(
          turnoutLabel, 'turnoutLabel', 'turnoutRate なしでは指定できない');
    }
  }

  /// 当選得票率（0除算ガード付き・0.0〜1.0）
  double get winnerShare => totalVotes <= 0 ? 0.0 : winnerVotes / totalVotes;

  /// 2位との得票差
  int get margin => winnerVotes - runnerUpVotes;

  /// 圧勝（得票率60%以上）か
  bool get isLandslide => winnerShare >= 0.6;

  /// 投票率がわかるか
  bool get hasTurnout => turnoutRate != null;

  /// 得票率ラベル（例: '60.0%'）
  String get sharePercentLabel =>
      '${(winnerShare * 100).toStringAsFixed(1)}%';

  /// 投票率ラベル（不明は '—'）
  String get turnoutPercentLabel =>
      hasTurnout ? '${(turnoutRate! * 100).toStringAsFixed(1)}%' : '—';

  /// 得票差ラベル（例: '300票差'）
  String get marginLabel => '$margin票差';

  /// 実施日ラベル（不明は '日付不明'、それ以外は YYYY/MM/DD ゼロ埋め）
  String get dateLabel {
    final d = occurredAt;
    if (d == null) return '日付不明';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }

  /// 見出し（例: '【天照町長選】当選: 太郎'）
  String get headline => '【$title】当選: $winnerName';

  /// 共有用テキストの行（順序固定）
  List<String> get lines => [
        headline,
        '得票率: $sharePercentLabel（$winnerVotes票 / 総投票 $totalVotes票）',
        isLandslide ? '2位との差: $marginLabel（圧勝）' : '2位との差: $marginLabel',
        hasTurnout ? '投票率: $turnoutPercentLabel（$turnoutLabel）' : '投票率: —',
        '規模: $scaleLabel',
        '実施日: $dateLabel',
      ];

  /// 共有用テキスト全体
  String get text => lines.join('\n');

  List<Object?> get _props => [
        electionId,
        title,
        scaleLabel,
        winnerName,
        winnerVotes,
        totalVotes,
        runnerUpVotes,
        occurredAt,
        turnoutRate,
        turnoutLabel,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElectionRecap &&
          other.runtimeType == runtimeType &&
          _equals(other);

  bool _equals(ElectionRecap other) {
    for (var i = 0; i < _props.length; i++) {
      if (_props[i] != other._props[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}