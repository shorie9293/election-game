import 'dart:convert';

/// 端末内クラッシュログの種別。
///
/// 文字列（`value`）が永続化形式。未知の値は「破損」として扱わず
/// [CrashLogKind.unknown] に寄せる（将来の種別追加で既存ログを捨てないため）。
enum CrashLogKind {
  /// Flutter フレームワーク内の例外（build / layout / paint）。
  framework('framework'),

  /// ゾーン外（PlatformDispatcher）の非同期例外。
  platform('platform'),

  /// runZonedGuarded が受け取った未捕捉例外。
  uncaught('uncaught'),

  /// 未知の種別（前方互換）。
  unknown('unknown');

  const CrashLogKind(this.value);

  /// 永続化する文字列。
  final String value;

  /// 永続化文字列から復元する（未知なら [CrashLogKind.unknown]）。
  static CrashLogKind fromValue(String value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return CrashLogKind.unknown;
  }
}

/// 端末内クラッシュログ1件（純粋モデル）。
///
/// 送信は行わない。端末の documents に残し、利用者が設定画面から
/// 内容を確認・コピーして報告できるようにするための最小限の記録。
class CrashLogEntry {
  /// message の最大文字数。
  static const int maxMessageLength = 200;

  /// stackTop に残す最大フレーム数。
  static const int maxStackFrames = 10;

  /// 記録時刻・種別・要旨・スタック先頭。
  ///
  /// [message] は先頭 [maxMessageLength] 文字、[stackTop] は先頭
  /// [maxStackFrames] 行に自動で切り詰める（保存量の上限を型で保証する）。
  CrashLogEntry({
    required this.timestamp,
    required this.kind,
    required String message,
    required String stackTop,
  })  : message = _clipChars(message, maxMessageLength),
        stackTop = _clipLines(stackTop, maxStackFrames);

  /// 例外から1件を組み立てる（切り詰めは本体で行う）。
  factory CrashLogEntry.capture({
    required CrashLogKind kind,
    required Object error,
    StackTrace? stack,
    DateTime? timestamp,
    String? message,
  }) {
    return CrashLogEntry(
      timestamp: timestamp ?? DateTime.now(),
      kind: kind,
      message: message ?? error.toString(),
      stackTop: stack?.toString() ?? '',
    );
  }

  /// 記録時刻。
  final DateTime timestamp;

  /// 種別。
  final CrashLogKind kind;

  /// 例外の要旨（先頭200文字）。
  final String message;

  /// スタックの先頭10フレーム（改行区切り）。
  final String stackTop;

  /// 永続化用の Map。
  Map<String, Object?> toJson() => <String, Object?>{
        'ts': timestamp.toIso8601String(),
        'kind': kind.value,
        'message': message,
        'stackTop': stackTop,
      };

  /// JSON 文字列から復元する。壊れていれば null（呼び出し側は読み飛ばす）。
  static CrashLogEntry? fromJson(String source) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic>) return null;
      final ts = decoded['ts'];
      final kind = decoded['kind'];
      final message = decoded['message'];
      final stackTop = decoded['stackTop'];
      if (ts is! String || kind is! String) return null;
      if (message is! String || stackTop is! String) return null;
      final timestamp = DateTime.tryParse(ts);
      if (timestamp == null) return null;
      return CrashLogEntry(
        timestamp: timestamp,
        kind: CrashLogKind.fromValue(kind),
        message: message,
        stackTop: stackTop,
      );
    } catch (_) {
      return null;
    }
  }

  static String _clipChars(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);

  static String _clipLines(String value, int max) {
    if (value.isEmpty) return '';
    final lines = value
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.isNotEmpty)
        .take(max)
        .toList();
    return lines.join('\n');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrashLogEntry &&
          other.timestamp == timestamp &&
          other.kind == kind &&
          other.message == message &&
          other.stackTop == stackTop;

  @override
  int get hashCode => Object.hash(timestamp, kind, message, stackTop);

  @override
  String toString() =>
      'CrashLogEntry(${timestamp.toIso8601String()}, ${kind.value}, $message)';
}
