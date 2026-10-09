/// 一つの選挙が終わった直後の生活パラメータのスナップショット。
class LifeParamSnapshot {
  /// 選挙ID（`Election.id`、形式は `election_<millis>`）
  final String electionId;

  /// 選挙の発生日時
  final DateTime occurredAt;

  /// 生活パラメータのキー → 値
  final Map<String, int> values;

  const LifeParamSnapshot({
    required this.electionId,
    required this.occurredAt,
    required this.values,
  });

  Map<String, dynamic> toJson() {
    return {
      'electionId': electionId,
      'occurredAt': occurredAt.toIso8601String(),
      'values': values,
    };
  }

  /// JSONから復元する。壊れている場合は [FormatException] を投げる。
  factory LifeParamSnapshot.fromJson(Map<String, dynamic> json) {
    final electionIdRaw = json['electionId'];
    if (electionIdRaw is! String) {
      throw const FormatException('electionId is missing or not a String');
    }

    final occurredAtRaw = json['occurredAt'];
    if (occurredAtRaw is! String) {
      throw const FormatException('occurredAt is missing or not a String');
    }
    final DateTime occurredAt;
    try {
      occurredAt = DateTime.parse(occurredAtRaw);
    } on FormatException {
      throw FormatException('occurredAt is not parseable: $occurredAtRaw');
    }

    final valuesRaw = json['values'];
    if (valuesRaw is! Map) {
      throw const FormatException('values is missing or not a Map');
    }
    final values = <String, int>{};
    for (final entry in valuesRaw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String || value is! int) {
        throw const FormatException('values contains a non String/int entry');
      }
      values[key] = value;
    }

    return LifeParamSnapshot(
      electionId: electionIdRaw,
      occurredAt: occurredAt,
      values: values,
    );
  }

  /// 指定キーの値を返す。無ければ null。
  int? valueOf(String key) => values[key];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LifeParamSnapshot &&
        other.electionId == electionId &&
        _mapEquals(other.values, values);
  }

  static bool _mapEquals(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(electionId, Object.hashAllUnordered(
        values.entries.map((e) => Object.hash(e.key, e.value)),
      ));

  @override
  String toString() =>
      'LifeParamSnapshot(electionId: $electionId, occurredAt: $occurredAt, values: $values)';
}
