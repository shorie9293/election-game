/// 選挙結果を画像カード化して共有するためのデータ（不変・純粋な値オブジェクト）。
///
/// [ElectionArchiveEntry] から組み立て、当選者・得票率・得票差・規模・投票率
/// ・実施日を1枚のカードへ載せる。不変条件は非constコンストラクタ本体で検証する
/// （assert は release で無効ゆえ使わない）。
class ElectionShareCardData {
  /// 元選挙のID
  final String electionId;

  /// 選挙タイトル（空文字禁止）
  final String title;

  /// 当選者名（空文字禁止）
  final String winnerName;

  /// 当選者の得票数（負値禁止）
  final int winnerVotes;

  /// 総得票数（負値禁止）
  final int totalVotes;

  /// 2位候補の得票数（負値禁止）
  final int runnerUpVotes;

  /// 規模ラベル（村/町/市・空文字禁止）
  final String scaleLabel;

  /// 投票率（0.0-1.0・不明ならnull）
  final double? turnoutRate;

  /// 関心ラベル（turnoutRate が null なら null）
  final String? turnoutLabel;

  /// 実施日時（不明ならnull）
  final DateTime? occurredAt;

  /// カード生成日時
  final DateTime generatedAt;

  ElectionShareCardData({
    required this.electionId,
    required this.title,
    required this.winnerName,
    required this.winnerVotes,
    required this.totalVotes,
    required this.runnerUpVotes,
    required this.scaleLabel,
    this.turnoutRate,
    this.turnoutLabel,
    this.occurredAt,
    required this.generatedAt,
  }) {
    if (title.isEmpty) {
      throw ArgumentError.value(title, 'title', '空文字は禁止');
    }
    if (winnerName.isEmpty) {
      throw ArgumentError.value(winnerName, 'winnerName', '空文字は禁止');
    }
    if (scaleLabel.isEmpty) {
      throw ArgumentError.value(scaleLabel, 'scaleLabel', '空文字は禁止');
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

  /// 得票率ラベル（例: '60.0%'）
  String get sharePercentLabel => '${(winnerShare * 100).toStringAsFixed(1)}%';

  /// 2位との得票差
  int get margin => winnerVotes - runnerUpVotes;

  /// 得票差ラベル（例: '20票差'）
  String get marginLabel => '$margin票差';

  /// 圧勝（得票率60%以上）か
  bool get isLandslide => winnerShare >= 0.6;

  /// 投票率がわかるか
  bool get hasTurnout => turnoutRate != null;

  /// 投票率ラベル（不明は '—'）
  String get turnoutPercentLabel =>
      hasTurnout ? '${(turnoutRate! * 100).toStringAsFixed(1)}%' : '—';

  /// 実施日ラベル（不明は '日付不明'、それ以外は YYYY/MM/DD ゼロ埋め）
  String get dateLabel => _formatDate(occurredAt) ?? '日付不明';

  /// カード生成日ラベル（YYYY/MM/DD ゼロ埋め）
  String get generatedDateLabel => _formatDate(generatedAt)!;

  /// 見出し（例: '【天照町長選】当選: 太郎'）
  String get headline => '【$title】当選: $winnerName';

  /// カード上部のタイトル
  String get header => '🗳️ 選挙の歩み';

  /// カード本文の行（順序固定）
  List<String> get lines => [
        headline,
        '得票率: $sharePercentLabel（$winnerVotes票 / 総投票 $totalVotes票）',
        isLandslide ? '2位との差: $marginLabel（圧勝）' : '2位との差: $marginLabel',
        hasTurnout ? '投票率: $turnoutPercentLabel（$turnoutLabel）' : '投票率: —',
        '規模: $scaleLabel',
        '実施日: $dateLabel',
      ];

  /// 共有用テキスト全体（見出し行＋本文＋生成日）
  String get shareText => [header, ...lines, generatedDateLabel].join('\n');

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}/$m/$day';
  }

  List<Object?> get _props => [
        electionId,
        title,
        winnerName,
        winnerVotes,
        totalVotes,
        runnerUpVotes,
        scaleLabel,
        turnoutRate,
        turnoutLabel,
        occurredAt,
        generatedAt,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElectionShareCardData &&
          other.runtimeType == runtimeType &&
          _equals(other);

  bool _equals(ElectionShareCardData other) {
    for (var i = 0; i < _props.length; i++) {
      if (_props[i] != other._props[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_props);
}
