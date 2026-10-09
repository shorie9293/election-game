/// 選挙ゲーム用リマインダーの設定値オブジェクト。
///
/// 不変（immutable）。[weekdays] は `DateTime.weekday` 準拠
/// （1=月 .. 7=日）の昇順ユニーク。空リストは「通知日なし」を表す。
library;

/// 通知種別。
enum ElectionNotificationKind {
  turnProgress('ターン進行', 'ターン進行の状況をお知らせします'),
  electionDay('選挙期日', '選挙期日の接近をお知らせします'),
  lifeParamWarning('生活パラメータ警告', '生活パラメータの低下をお知らせします');

  const ElectionNotificationKind(this.label, this.description);

  /// 表示用ラベル（日本語）。
  final String label;

  /// 説明文（日本語）。
  final String description;

  /// JSON へ保存する識別子。
  String get id => name;

  static ElectionNotificationKind fromId(String id) {
    for (final kind in ElectionNotificationKind.values) {
      if (kind.name == id) return kind;
    }
    throw FormatException('不明な通知種別: $id');
  }
}

class ElectionReminderSettings {
  ElectionReminderSettings({
    this.enabled = false,
    this.hour = 20,
    this.minute = 0,
    List<int> weekdays = const [1, 2, 3, 4, 5, 6, 7],
    Set<ElectionNotificationKind>? enabledKinds,
    this.updatedAt,
  })  : weekdays = List.unmodifiable(
          List<int>.of(weekdays.toSet().toList())..sort(),
        ),
        enabledKinds = Set.unmodifiable(
          enabledKinds ?? ElectionNotificationKind.values,
        ) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', '0-23 の範囲で指定せよ');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(minute, 'minute', '0-59 の範囲で指定せよ');
    }
    for (final w in this.weekdays) {
      if (w < 1 || w > 7) {
        throw ArgumentError.value(w, 'weekdays', '1(月)-7(日) の範囲で指定せよ');
      }
    }
  }

  /// 既定値: 無効・20:00・毎日・全通知種別有効。
  factory ElectionReminderSettings.defaults() => ElectionReminderSettings();

  final bool enabled;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final Set<ElectionNotificationKind> enabledKinds;
  final DateTime? updatedAt;

  /// 毎日（月〜日すべて）通知するか。
  bool get isDaily => weekdays.length == 7;

  /// [kind] が有効か。
  bool isKindEnabled(ElectionNotificationKind kind) =>
      enabledKinds.contains(kind);

  /// [kind] の有効/無効をトグルした新しい設定を返す（不変）。
  ElectionReminderSettings toggleKind(ElectionNotificationKind kind) {
    final next = Set<ElectionNotificationKind>.of(enabledKinds);
    if (!next.remove(kind)) {
      next.add(kind);
    }
    return copyWith(enabledKinds: next);
  }

  ElectionReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
    List<int>? weekdays,
    Set<ElectionNotificationKind>? enabledKinds,
    DateTime? updatedAt,
  }) {
    return ElectionReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      enabledKinds: enabledKinds ?? this.enabledKinds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'hour': hour,
        'minute': minute,
        'weekdays': List<int>.of(weekdays),
        'enabledKinds': enabledKinds.map((k) => k.id).toList(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  /// 型不一致・欠落・範囲外・不明な通知種別は [FormatException]。
  factory ElectionReminderSettings.fromJson(Map<String, dynamic> json) {
    try {
      final enabled = json['enabled'];
      final hour = json['hour'];
      final minute = json['minute'];
      final weekdays = json['weekdays'];
      final kinds = json['enabledKinds'];
      final updatedAt = json['updatedAt'];
      if (enabled is! bool) throw const FormatException('enabled');
      if (hour is! int) throw const FormatException('hour');
      if (minute is! int) throw const FormatException('minute');
      if (weekdays is! List) throw const FormatException('weekdays');
      if (weekdays.any((w) => w is! int)) {
        throw const FormatException('weekdays');
      }
      if (kinds is! List) throw const FormatException('enabledKinds');
      final parsedKinds = <ElectionNotificationKind>{
        for (final k in kinds) ElectionNotificationKind.fromId(k as String),
      };
      final weekdayList = List<int>.from(weekdays.cast<int>());
      DateTime? updatedAtParsed;
      if (updatedAt is String) {
        updatedAtParsed = DateTime.tryParse(updatedAt);
        if (updatedAtParsed == null) throw const FormatException('updatedAt');
      } else if (updatedAt != null) {
        throw const FormatException('updatedAt');
      }
      return ElectionReminderSettings(
        enabled: enabled,
        hour: hour,
        minute: minute,
        weekdays: weekdayList,
        enabledKinds: parsedKinds,
        updatedAt: updatedAtParsed,
      );
    } on ArgumentError {
      throw const FormatException('ElectionReminderSettings の範囲外の値');
    } on TypeError {
      throw const FormatException('ElectionReminderSettings の型不一致');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElectionReminderSettings &&
          other.enabled == enabled &&
          other.hour == hour &&
          other.minute == minute &&
          other.updatedAt == updatedAt &&
          _listEquals(other.weekdays, weekdays) &&
          other.enabledKinds.length == enabledKinds.length &&
          other.enabledKinds.containsAll(enabledKinds);

  @override
  int get hashCode => Object.hash(
        enabled,
        hour,
        minute,
        updatedAt,
        Object.hashAll(weekdays),
        Object.hashAll(enabledKinds),
      );

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
