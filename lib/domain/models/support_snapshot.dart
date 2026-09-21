import 'package:equatable/equatable.dart';

/// 候補者ごとの支持率スナップショット
///
/// 支持率シミュレーション結果の単位。正規化済みの支持シェアと
/// 有権者平均の政策親和性を保持する。
class SupportSnapshot extends Equatable {
  /// 候補者ID（空文字禁止）
  final String candidateId;

  /// 候補者名
  final String candidateName;

  /// 正規化済み支持シェア（0.0-1.0）
  final double supportRate;

  /// 有権者平均の政策親和性（0.0-1.0）
  final double rawAffinity;

  /// 第一選択にした有権者数
  final int supporterCount;

  /// 不変条件は本体で検証（const 不可・ArgumentError を throw）
  SupportSnapshot({
    required this.candidateId,
    required this.candidateName,
    required this.supportRate,
    required this.rawAffinity,
    required this.supporterCount,
  }) {
    if (candidateId.isEmpty) {
      throw ArgumentError.value(candidateId, 'candidateId', '空文字は禁止');
    }
    if (supportRate < 0.0 || supportRate > 1.0) {
      throw ArgumentError.value(
          supportRate, 'supportRate', '0.0-1.0 の範囲外');
    }
    if (rawAffinity < 0.0 || rawAffinity > 1.0) {
      throw ArgumentError.value(
          rawAffinity, 'rawAffinity', '0.0-1.0 の範囲外');
    }
    if (supporterCount < 0) {
      throw ArgumentError.value(supporterCount, 'supporterCount', '負値は禁止');
    }
  }

  /// 支持率の日本語ラベル（例: 0.425 → '42.5%'）
  String get supportPercentLabel =>
      '${(supportRate * 100).toStringAsFixed(1)}%';

  SupportSnapshot copyWith({
    String? candidateId,
    String? candidateName,
    double? supportRate,
    double? rawAffinity,
    int? supporterCount,
  }) {
    return SupportSnapshot(
      candidateId: candidateId ?? this.candidateId,
      candidateName: candidateName ?? this.candidateName,
      supportRate: supportRate ?? this.supportRate,
      rawAffinity: rawAffinity ?? this.rawAffinity,
      supporterCount: supporterCount ?? this.supporterCount,
    );
  }

  @override
  List<Object?> get props =>
      [candidateId, candidateName, supportRate, rawAffinity, supporterCount];
}

/// 支持率シミュレーション結果
///
/// 全候補者のスナップショットと世論の状況をまとめて保持する。
class SupportSimulation extends Equatable {
  /// 選挙タイトル（lastElection?.title ?? '支持率シミュレーション'）
  final String electionTitle;

  /// 支持率降順・同率は candidateId 昇順で整列済みのスナップショット（空リスト許容）
  final List<SupportSnapshot> snapshots;

  /// 有権者数
  final int voterCount;

  /// society.moodLabel を格納
  final String moodLabel;

  /// 世論の頑固さラベル
  final String stubbornnessLabel;

  /// 前回選挙の当選者が確定しているか
  final bool hasHistory;

  /// 不変条件は本体で検証（ArgumentError を throw）
  SupportSimulation({
    required this.electionTitle,
    required this.snapshots,
    required this.voterCount,
    required this.moodLabel,
    required this.stubbornnessLabel,
    required this.hasHistory,
  }) {
    if (voterCount < 0) {
      throw ArgumentError.value(voterCount, 'voterCount', '負値は禁止');
    }
  }

  /// 首位の候補者スナップショット（空なら null）
  SupportSnapshot? get leader => snapshots.isEmpty ? null : snapshots.first;

  /// 候補者IDでスナップショットを検索（見つからなければ null）
  SupportSnapshot? snapshotFor(String candidateId) {
    for (final s in snapshots) {
      if (s.candidateId == candidateId) return s;
    }
    return null;
  }

  /// スナップショットが空か
  bool get isEmpty => snapshots.isEmpty;

  SupportSimulation copyWith({
    String? electionTitle,
    List<SupportSnapshot>? snapshots,
    int? voterCount,
    String? moodLabel,
    String? stubbornnessLabel,
    bool? hasHistory,
  }) {
    return SupportSimulation(
      electionTitle: electionTitle ?? this.electionTitle,
      snapshots: snapshots ?? this.snapshots,
      voterCount: voterCount ?? this.voterCount,
      moodLabel: moodLabel ?? this.moodLabel,
      stubbornnessLabel: stubbornnessLabel ?? this.stubbornnessLabel,
      hasHistory: hasHistory ?? this.hasHistory,
    );
  }

  @override
  List<Object?> get props => [
        electionTitle,
        snapshots,
        voterCount,
        moodLabel,
        stubbornnessLabel,
        hasHistory,
      ];
}
