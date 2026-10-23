import 'package:equatable/equatable.dart';

/// 世論（支持率）の推移を記録する1エントリ。
///
/// ある時点の首位候補者と支持率、そのときの世論ラベルを保持する。
/// 不変条件は本体で検証する（const 不可・ArgumentError を throw）。
class SupportTimelineEntry extends Equatable {
  /// エントリID（空文字禁止）
  final String id;

  /// 記録日時
  final DateTime recordedAt;

  /// 選挙タイトル
  final String electionTitle;

  /// 首位候補者ID（空文字禁止）
  final String leaderCandidateId;

  /// 首位候補者名（空文字禁止）
  final String leaderCandidateName;

  /// 首位候補者の支持率（0.0-1.0）
  final double leaderSupportRate;

  /// 有権者数
  final int voterCount;

  /// 世論ラベル
  final String moodLabel;

  SupportTimelineEntry({
    required this.id,
    required this.recordedAt,
    required this.electionTitle,
    required this.leaderCandidateId,
    required this.leaderCandidateName,
    required this.leaderSupportRate,
    required this.voterCount,
    required this.moodLabel,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', '空文字は禁止');
    }
    if (electionTitle.isEmpty) {
      throw ArgumentError.value(electionTitle, 'electionTitle', '空文字は禁止');
    }
    if (leaderCandidateId.isEmpty) {
      throw ArgumentError.value(
          leaderCandidateId, 'leaderCandidateId', '空文字は禁止');
    }
    if (leaderCandidateName.isEmpty) {
      throw ArgumentError.value(
          leaderCandidateName, 'leaderCandidateName', '空文字は禁止');
    }
    if (leaderSupportRate < 0.0 || leaderSupportRate > 1.0) {
      throw ArgumentError.value(
          leaderSupportRate, 'leaderSupportRate', '0.0-1.0 の範囲外');
    }
    if (voterCount < 0) {
      throw ArgumentError.value(voterCount, 'voterCount', '負値は禁止');
    }
  }

  /// 首位候補者の支持率ラベル（例: 0.425 → '42.5%'）
  String get leaderShareLabel => '${(leaderSupportRate * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordedAt': recordedAt.toIso8601String(),
      'electionTitle': electionTitle,
      'leaderCandidateId': leaderCandidateId,
      'leaderCandidateName': leaderCandidateName,
      'leaderSupportRate': leaderSupportRate,
      'voterCount': voterCount,
      'moodLabel': moodLabel,
    };
  }

  /// JSON から復元する。型不一致・変換不能は [FormatException]。
  factory SupportTimelineEntry.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    if (idRaw is! String) {
      throw const FormatException('id is missing or not a String');
    }

    final recordedAtRaw = json['recordedAt'];
    if (recordedAtRaw is! String) {
      throw const FormatException('recordedAt is missing or not a String');
    }
    final DateTime recordedAt;
    try {
      recordedAt = DateTime.parse(recordedAtRaw);
    } on FormatException {
      throw FormatException('recordedAt is not parseable: $recordedAtRaw');
    }

    final electionTitleRaw = json['electionTitle'];
    if (electionTitleRaw is! String) {
      throw const FormatException('electionTitle is missing or not a String');
    }

    final leaderCandidateIdRaw = json['leaderCandidateId'];
    if (leaderCandidateIdRaw is! String) {
      throw const FormatException(
          'leaderCandidateId is missing or not a String');
    }

    final leaderCandidateNameRaw = json['leaderCandidateName'];
    if (leaderCandidateNameRaw is! String) {
      throw const FormatException(
          'leaderCandidateName is missing or not a String');
    }

    final leaderSupportRateRaw = json['leaderSupportRate'];
    if (leaderSupportRateRaw is! num) {
      throw const FormatException(
          'leaderSupportRate is missing or not a num');
    }

    final voterCountRaw = json['voterCount'];
    if (voterCountRaw is! int) {
      throw const FormatException('voterCount is missing or not an int');
    }

    final moodLabelRaw = json['moodLabel'];
    if (moodLabelRaw is! String) {
      throw const FormatException('moodLabel is missing or not a String');
    }

    return SupportTimelineEntry(
      id: idRaw,
      recordedAt: recordedAt,
      electionTitle: electionTitleRaw,
      leaderCandidateId: leaderCandidateIdRaw,
      leaderCandidateName: leaderCandidateNameRaw,
      leaderSupportRate: leaderSupportRateRaw.toDouble(),
      voterCount: voterCountRaw,
      moodLabel: moodLabelRaw,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recordedAt,
        electionTitle,
        leaderCandidateId,
        leaderCandidateName,
        leaderSupportRate,
        voterCount,
        moodLabel,
      ];
}

/// あるエントリと直前エントリとの差分。
class SupportTimelineDelta extends Equatable {
  /// 対象エントリID
  final String entryId;

  /// 直前エントリID（先頭なら null）
  final String? previousEntryId;

  /// 首位候補者が交代したか
  final bool leaderChanged;

  /// 支持率の差分（0.0-1.0 スケール）
  final double shareDelta;

  /// 首位交代ラベル（交代時のみ '首位交代'、それ以外は空文字）
  final String leaderChangeLabel;

  const SupportTimelineDelta({
    required this.entryId,
    required this.previousEntryId,
    required this.leaderChanged,
    required this.shareDelta,
    required this.leaderChangeLabel,
  });

  /// 符号付き pt 表記（例: '+2.3pt' / '-1.0pt' / '±0.0pt'）
  String get deltaLabel {
    final pct = shareDelta * 100;
    if (pct.abs() < 0.05) return '±0.0pt';
    final sign = pct > 0 ? '+' : '-';
    return '$sign${pct.abs().toStringAsFixed(1)}pt';
  }

  @override
  List<Object?> get props =>
      [entryId, previousEntryId, leaderChanged, shareDelta, leaderChangeLabel];
}
