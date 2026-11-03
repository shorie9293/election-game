import 'package:flutter/foundation.dart';

/// ログの出力先。試練では差し替えて検証する。
typedef LogSink = void Function(String message);

/// 本番で垂れ流さないログの唯一の入口。
///
/// - [debug] / [info] は `isDebug == false`（＝リリースビルド）で無出力。
///   選挙結果・支持率・ユーザー選択などの verbose 情報はここへ。
/// - [warn] / [error] は常時出力。続行可能な失敗は warn、致命／例外詳細は error。
/// - 出力はレベルタグ付き。sink が投げても呼び出し側へは伝播しない
///   （ログの失敗で本処理を落とさない）。
class AppLogger {
  AppLogger({bool? isDebug, LogSink? sink})
      : isDebug = isDebug ?? kDebugMode,
        _sink = sink ?? _defaultSink;

  /// リリースビルドでは false。verbose ログの出し分けに使う。
  final bool isDebug;

  final LogSink _sink;

  /// 既定 sink。`debugPrint` は本番でも出力されるため、ここで一度だけ包む。
  static void _defaultSink(String message) => debugPrint(message);

  /// 開発時のみ残す詳細ログ（選挙結果・支持率・ユーザー選択など）。
  void debug(String message) {
    if (!isDebug) return;
    _emit('DEBUG', message);
  }

  /// 開発時のみ残す情報ログ（起動完了などの通過点）。
  void info(String message) {
    if (!isDebug) return;
    _emit('INFO', message);
  }

  /// 続行可能な失敗。リリースでも残す。
  void warn(String message, [Object? error, StackTrace? stackTrace]) {
    _emit('WARN', message, error, stackTrace);
  }

  /// 致命／要調査の失敗。リリースでも残す。
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _emit('ERROR', message, error, stackTrace);
  }

  void _emit(
    String level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    try {
      final buffer = StringBuffer('[$level] $message');
      if (error != null) buffer.write(' | error: $error');
      if (stackTrace != null) buffer.write(' | stack: $stackTrace');
      _sink(buffer.toString());
    } catch (_) {
      // ログ出力自体の失敗は握りつぶす（本処理を妨げない）。
    }
  }
}

/// アプリ全体で共有するロガー。
final AppLogger appLog = AppLogger();
