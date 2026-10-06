import 'dart:convert';

typedef BackupClock = DateTime Function();

const int kBackupSchemaVersion = 1;
const String kBackupAppId = 'election_game';

/// バックアップ値のカテゴリ
enum BackupCategory { archive, prediction, quiz, rating, settings, tutorial, other }

/// カテゴリの日本語表示名
String backupCategoryLabel(BackupCategory c) {
  switch (c) {
    case BackupCategory.archive:
      return '選挙アーカイブ';
    case BackupCategory.prediction:
      return '選挙予想';
    case BackupCategory.quiz:
      return 'クイズ成績';
    case BackupCategory.rating:
      return '候補者評価';
    case BackupCategory.settings:
      return '設定';
    case BackupCategory.tutorial:
      return 'チュートリアル';
    case BackupCategory.other:
      return 'その他';
  }
}

/// 管理対象キーの定義（exact と prefix の2種）
class BackupKeySpec {
  final String pattern;
  final bool isPrefix;
  final BackupCategory category;
  final String label;

  const BackupKeySpec.exact(this.pattern, this.category, this.label)
      : isPrefix = false;

  const BackupKeySpec.prefix(this.pattern, this.category, this.label)
      : isPrefix = true;

  bool matches(String key) =>
      isPrefix ? key.startsWith(pattern) : key == pattern;

  static const List<BackupKeySpec> all = [
    BackupKeySpec.exact('election_archive', BackupCategory.archive, '選挙アーカイブ'),
    BackupKeySpec.exact(
        'election_predictions_v1', BackupCategory.prediction, '選挙予想'),
    BackupKeySpec.exact(
        'election_quiz_best_correct', BackupCategory.quiz, 'クイズ最高正答数'),
    BackupKeySpec.exact(
        'election_quiz_best_total', BackupCategory.quiz, 'クイズ最高出題数'),
    BackupKeySpec.exact(
        'election_quiz_attempts', BackupCategory.quiz, 'クイズ挑戦回数'),
    BackupKeySpec.prefix(
        'candidate_rating_', BackupCategory.rating, '候補者評価'),
    BackupKeySpec.exact(
        'election_game_theme_mode', BackupCategory.settings, 'テーマ設定'),
    BackupKeySpec.exact(
        'election_game_text_scale', BackupCategory.settings, '文字サイズ'),
    BackupKeySpec.exact(
        'election_game_sound_bgm_enabled', BackupCategory.settings, 'BGM設定'),
    BackupKeySpec.exact(
        'election_game_sound_sfx_enabled', BackupCategory.settings, '効果音設定'),
    BackupKeySpec.exact(
        'election_game_sound_volume', BackupCategory.settings, '音量設定'),
    BackupKeySpec.exact('election_game_tutorial_completed',
        BackupCategory.tutorial, 'チュートリアル完了'),
  ];

  static BackupCategory categoryFor(String key) {
    for (final spec in all) {
      if (spec.matches(key)) {
        return spec.category;
      }
    }
    return BackupCategory.other;
  }

  static String labelFor(String key) {
    for (final spec in all) {
      if (spec.matches(key)) {
        return spec.label;
      }
    }
    return key;
  }
}

/// 管理対象キーを1件ずつ集めたエントリ
class BackupEntry {
  final String key;
  final Object? value;

  const BackupEntry(this.key, this.value);

  Map<String, dynamic> toJson() => {'key': key, 'value': value};

  factory BackupEntry.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String) {
      throw const FormatException('key must be a String');
    }
    return BackupEntry(key, json['value']);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupEntry &&
          other.key == key &&
          _valueEquals(other.value, value);

  static bool _valueEquals(Object? a, Object? b) {
    if (a is List && b is List) {
      if (a.length != b.length) {
        return false;
      }
      for (var i = 0; i < a.length; i++) {
        if (!_valueEquals(a[i], b[i])) {
          return false;
        }
      }
      return true;
    }
    return a == b;
  }

  @override
  int get hashCode => key.hashCode ^ value.hashCode;
}

/// バックアップ文書
class GameDataBackup {
  final int schemaVersion;
  final String appId;
  final DateTime exportedAt;
  final Map<String, Object?> data;

  const GameDataBackup({
    required this.schemaVersion,
    required this.appId,
    required this.exportedAt,
    required this.data,
  });

  int get entryCount => data.length;

  Map<BackupCategory, int> get categoryCounts {
    final counts = <BackupCategory, int>{
      for (final c in BackupCategory.values) c: 0,
    };
    for (final key in data.keys) {
      counts[BackupKeySpec.categoryFor(key)] =
          (counts[BackupKeySpec.categoryFor(key)] ?? 0) + 1;
    }
    return counts;
  }

  String get exportedAtLabel {
    final m = exportedAt.month.toString().padLeft(2, '0');
    final d = exportedAt.day.toString().padLeft(2, '0');
    final hh = exportedAt.hour.toString().padLeft(2, '0');
    final mm = exportedAt.minute.toString().padLeft(2, '0');
    return '${exportedAt.year}-$m-$d $hh:$mm';
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'app_id': appId,
        'exported_at': exportedAt.toIso8601String(),
        'data': data,
      };

  factory GameDataBackup.fromJson(Map<String, dynamic> json) {
    final raw = json['data'];
    final data = <String, Object?>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        data[k.toString()] = v;
      });
    }
    return GameDataBackup(
      schemaVersion: json['schema_version'] as int,
      appId: json['app_id'] as String,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      data: data,
    );
  }
}

/// 解析結果
class BackupParseResult {
  final GameDataBackup? backup;
  final String? error;

  const BackupParseResult.success(GameDataBackup this.backup) : error = null;

  const BackupParseResult.failure(String this.error) : backup = null;

  bool get isSuccess => backup != null;

  bool get hasError => error != null;
}

/// 純粋サービス（例外を投げない・副作用なし）
class GameDataBackupService {
  const GameDataBackupService();

  /// data をJSON文字列へ。exportedAt 省略時は DateTime.now()。
  String build(
    Map<String, Object?> data, {
    DateTime? exportedAt,
    String appId = kBackupAppId,
    int schemaVersion = kBackupSchemaVersion,
  }) {
    return jsonEncode({
      'schema_version': schemaVersion,
      'app_id': appId,
      'exported_at': (exportedAt ?? DateTime.now()).toIso8601String(),
      'data': data,
    });
  }

  /// JSON文字列を解析。失敗時は日本語メッセージを持つ failure。
  BackupParseResult parse(String raw) {
    if (raw.trim().isEmpty) {
      return const BackupParseResult.failure('バックアップデータが空です');
    }
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const BackupParseResult.failure(
          'バックアップデータを読み取れません（JSON形式が不正です）');
    }
    if (decoded is! Map) {
      return const BackupParseResult.failure('バックアップデータの形式が不正です');
    }
    final version = decoded['schema_version'];
    if (version is! int) {
      return const BackupParseResult.failure('バックアップ形式のバージョンが不正です');
    }
    if (version > kBackupSchemaVersion) {
      return const BackupParseResult.failure('未対応のバックアップ形式です');
    }
    final appId = decoded['app_id'];
    if (appId is! String || appId != kBackupAppId) {
      return const BackupParseResult.failure('このアプリのバックアップではありません');
    }
    final rawData = decoded['data'];
    if (rawData is! Map) {
      return const BackupParseResult.failure('バックアップデータの中身が不正です');
    }
    final rawExportedAt = decoded['exported_at'];
    if (rawExportedAt is! String) {
      return const BackupParseResult.failure('バックアップの作成日時が不正です');
    }
    DateTime exportedAt;
    try {
      exportedAt = DateTime.parse(rawExportedAt);
    } catch (_) {
      return const BackupParseResult.failure('バックアップの作成日時が不正です');
    }
    final data = <String, Object?>{};
    rawData.forEach((k, v) {
      data[k.toString()] = v;
    });
    return BackupParseResult.success(GameDataBackup(
      schemaVersion: version,
      appId: appId,
      exportedAt: exportedAt,
      data: data,
    ));
  }
}
