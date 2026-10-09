import 'package:equatable/equatable.dart';

import 'citizen_enums.dart';

/// 公約の実現度ステータス。
/// - neutral: 約束の変動量が0（対象外）
/// - fulfilled: 実際の変動 == 約束（完全実現）
/// - partial: 約束と同じ向きだが |実際| < |約束|（一部実現。上限/下限clamp等）
/// - blocked: 約束 != 0 かつ 実際 == 0（全く動かなかった＝上限/下限に到達）
/// - reversed: 約束 != 0 かつ 実際 != 0 かつ 符号が逆（逆行）
enum ManifestoStatus { neutral, fulfilled, partial, blocked, reversed }

extension ManifestoStatusLabel on ManifestoStatus {
  String get label {
    switch (this) {
      case ManifestoStatus.neutral:
        return '対象外';
      case ManifestoStatus.fulfilled:
        return '実現';
      case ManifestoStatus.partial:
        return '一部実現';
      case ManifestoStatus.blocked:
        return '未実現';
      case ManifestoStatus.reversed:
        return '逆行';
    }
  }
}

/// 当選者の公約（生活パラメータkey単位）の実現度1件分。
class ManifestoPledge extends Equatable {
  final String lifeParamKey;
  final int promisedDelta; // 当選者の公約合計（totalEffectsの該当key）
  final int actualDelta; // 選挙適用前後の生活パラメータ差（after - before）
  final List<String> policyTitles; // このkeyに触れた公約タイトル（重複除去・宣言順）

  const ManifestoPledge({
    required this.lifeParamKey,
    required this.promisedDelta,
    required this.actualDelta,
    this.policyTitles = const [],
  });

  ManifestoStatus get status {
    if (promisedDelta == 0) return ManifestoStatus.neutral;
    if (actualDelta == 0) return ManifestoStatus.blocked;
    if (actualDelta.sign != promisedDelta.sign) return ManifestoStatus.reversed;
    if (actualDelta.abs() >= promisedDelta.abs()) {
      return ManifestoStatus.fulfilled;
    }
    return ManifestoStatus.partial;
  }

  double get rate =>
      promisedDelta == 0 ? 0.0 : (actualDelta.abs() / promisedDelta.abs()).clamp(0.0, 1.0);

  int get gap => promisedDelta - actualDelta;

  bool get isFulfilled => status == ManifestoStatus.fulfilled;

  String get label => LifeParamKeys.label(lifeParamKey);

  Map<String, dynamic> toJson() => {
        'lifeParamKey': lifeParamKey,
        'promisedDelta': promisedDelta,
        'actualDelta': actualDelta,
        'policyTitles': policyTitles,
      };

  factory ManifestoPledge.fromJson(Map<String, dynamic> json) {
    return ManifestoPledge(
      lifeParamKey: json['lifeParamKey'] as String,
      promisedDelta: json['promisedDelta'] as int,
      actualDelta: json['actualDelta'] as int,
      policyTitles: (json['policyTitles'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  ManifestoPledge copyWith({
    String? lifeParamKey,
    int? promisedDelta,
    int? actualDelta,
    List<String>? policyTitles,
  }) {
    return ManifestoPledge(
      lifeParamKey: lifeParamKey ?? this.lifeParamKey,
      promisedDelta: promisedDelta ?? this.promisedDelta,
      actualDelta: actualDelta ?? this.actualDelta,
      policyTitles: policyTitles ?? this.policyTitles,
    );
  }

  @override
  List<Object?> get props => [lifeParamKey, promisedDelta, actualDelta, policyTitles];
}

/// 1選挙分の公約実現度の記録。
class ManifestoRecord extends Equatable {
  final String electionId;
  final String title;
  final String winnerId;
  final String winnerName;
  final DateTime? occurredAt;
  final List<ManifestoPledge> pledges;

  const ManifestoRecord({
    required this.electionId,
    required this.title,
    required this.winnerId,
    required this.winnerName,
    this.occurredAt,
    this.pledges = const [],
  });

  int get totalPledges => pledges.length;

  int get relevantPledges => pledges.where((p) => p.promisedDelta != 0).length;

  int get fulfilledCount =>
      pledges.where((p) => p.status == ManifestoStatus.fulfilled).length;

  /// relevant（約束 != 0）の公約に対する rate の平均。0除算ガード付き。
  double get realizationRate {
    final relevant = pledges.where((p) => p.promisedDelta != 0);
    if (relevant.isEmpty) return 0.0;
    return relevant.map((p) => p.rate).reduce((a, b) => a + b) / relevant.length;
  }

  String get percentLabel => '${(realizationRate * 100).round()}%';

  /// 全ステータスを0初期化した上で集計した不変Map。
  Map<ManifestoStatus, int> get statusCounts {
    final counts = <ManifestoStatus, int>{
      for (final status in ManifestoStatus.values) status: 0,
    };
    for (final pledge in pledges) {
      counts[pledge.status] = (counts[pledge.status] ?? 0) + 1;
    }
    return Map.unmodifiable(counts);
  }

  ManifestoRecord copyWith({
    String? electionId,
    String? title,
    String? winnerId,
    String? winnerName,
    DateTime? occurredAt,
    List<ManifestoPledge>? pledges,
  }) {
    return ManifestoRecord(
      electionId: electionId ?? this.electionId,
      title: title ?? this.title,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      occurredAt: occurredAt ?? this.occurredAt,
      pledges: pledges ?? this.pledges,
    );
  }

  Map<String, dynamic> toJson() => {
        'electionId': electionId,
        'title': title,
        'winnerId': winnerId,
        'winnerName': winnerName,
        'occurredAt': occurredAt?.toIso8601String(),
        'pledges': pledges.map((p) => p.toJson()).toList(),
      };

  factory ManifestoRecord.fromJson(Map<String, dynamic> json) {
    return ManifestoRecord(
      electionId: json['electionId'] as String,
      title: json['title'] as String,
      winnerId: json['winnerId'] as String,
      winnerName: json['winnerName'] as String,
      occurredAt: (json['occurredAt'] as String?) != null
          ? DateTime.parse(json['occurredAt'] as String)
          : null,
      pledges: ((json['pledges'] as List?) ?? const [])
          .map((e) => ManifestoPledge.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props =>
      [electionId, title, winnerId, winnerName, occurredAt, pledges];
}
