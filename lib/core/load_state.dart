/// 読み込みの「失敗」と「0件」を区別するための共通型。
///
/// - [LoadState] は画面の表示状態（loading / data / empty / error）
/// - [LoadResult] はリポジトリ層の戻り値（success / failure）
///
/// 従来は null ひとつで「未保存」と「破損・読込失敗」を兼ねていたため、
/// 画面側で失敗を空状態として握り潰していた。本ファイルの型で分離する。
library;

/// 画面の読み込みフェーズ。
enum LoadPhase { loading, data, empty, error }

/// 画面が扱う読み込み状態。
///
/// 本体は非const。不正な引数（data の null、error の空メッセージ）は
/// [ArgumentError] を投げ、不正な状態生成を型で防ぐ。
class LoadState<T> {
  /// 現在のフェーズ。
  final LoadPhase phase;

  final T? _value;
  final String? _message;
  final bool _retryable;
  final Object? _cause;

  /// 読み込み中。
  LoadState.loading()
      : phase = LoadPhase.loading,
        _value = null,
        _message = null,
        _retryable = false,
        _cause = null;

  /// データ取得済み。
  LoadState.data(T value)
      : phase = LoadPhase.data,
        _value = value,
        _message = null,
        _retryable = false,
        _cause = null {
    if (value == null) {
      throw ArgumentError.value(value, 'value', 'must not be null');
    }
  }

  /// 取得は成功したが0件。
  LoadState.empty()
      : phase = LoadPhase.empty,
        _value = null,
        _message = null,
        _retryable = false,
        _cause = null;

  /// 読み込み失敗。[message] は空文字不可。
  LoadState.error(String message, {bool retryable = true, Object? cause})
      : phase = LoadPhase.error,
        _value = null,
        _message = message,
        _retryable = retryable,
        _cause = cause {
    if (message.trim().isEmpty) {
      throw ArgumentError.value(message, 'message', 'must not be empty');
    }
  }

  bool get isLoading => phase == LoadPhase.loading;
  bool get isData => phase == LoadPhase.data;
  bool get isEmpty => phase == LoadPhase.empty;
  bool get isError => phase == LoadPhase.error;

  /// 成功時の値。loading/empty/error では null。
  T? get valueOrNull => phase == LoadPhase.data ? _value : null;

  /// 失敗メッセージ。error 以外では null。
  String? get message => phase == LoadPhase.error ? _message : null;

  /// 再試行可能か。error 以外では false。
  bool get retryable => phase == LoadPhase.error ? _retryable : false;

  /// 失敗の原因（デバッグ用）。
  Object? get cause => phase == LoadPhase.error ? _cause : null;

  /// フェーズごとに分岐する。全引数必須（分岐漏れを防ぐ）。
  R when<R>({
    required R Function() loading,
    required R Function(T value) data,
    required R Function() empty,
    required R Function(String message, bool retryable) error,
  }) {
    switch (phase) {
      case LoadPhase.loading:
        return loading();
      case LoadPhase.data:
        return data(_value as T);
      case LoadPhase.empty:
        return empty();
      case LoadPhase.error:
        return error(_message ?? '', _retryable);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadState<T> &&
        other.phase == phase &&
        other._value == _value &&
        other._message == _message &&
        other._retryable == _retryable &&
        other._cause == _cause;
  }

  @override
  int get hashCode =>
      Object.hash(phase, _value, _message, _retryable, _cause);

  @override
  String toString() {
    switch (phase) {
      case LoadPhase.loading:
        return 'LoadState<$T>.loading()';
      case LoadPhase.data:
        return 'LoadState<$T>.data($_value)';
      case LoadPhase.empty:
        return 'LoadState<$T>.empty()';
      case LoadPhase.error:
        return 'LoadState<$T>.error($_message, retryable: $_retryable)';
    }
  }
}

/// リポジトリ層の戻り値。失敗と0件（success + null）を区別する。
class LoadResult<T> {
  final bool _success;
  final T? _value;
  final String? _message;
  final bool _retryable;
  final Object? _cause;

  /// 読み込み成功。[value] が null の場合は「0件」を意味する
  /// （例: 未保存の予想）。
  LoadResult.success(T value)
      : _success = true,
        _value = value,
        _message = null,
        _retryable = false,
        _cause = null;

  /// 読み込み失敗。[message] は空文字不可。
  LoadResult.failure(String message, {bool retryable = true, Object? cause})
      : _success = false,
        _value = null,
        _message = message,
        _retryable = retryable,
        _cause = cause {
    if (message.trim().isEmpty) {
      throw ArgumentError.value(message, 'message', 'must not be empty');
    }
  }

  bool get isSuccess => _success;
  bool get isFailure => !_success;

  /// 成功時の値。失敗時は null。
  T? get valueOrNull => _success ? _value : null;

  /// 失敗メッセージ。成功時は null。
  String? get message => _success ? null : _message;

  /// 再試行可能か。成功時は false。
  bool get retryable => _success ? false : _retryable;

  /// 失敗の原因（デバッグ用）。
  Object? get cause => _success ? null : _cause;

  /// 成否で分岐する。
  R when<R>({
    required R Function(T value) success,
    required R Function(String message, bool retryable) failure,
  }) {
    if (_success) return success(_value as T);
    return failure(_message ?? '', _retryable);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoadResult<T> &&
        other._success == _success &&
        other._value == _value &&
        other._message == _message &&
        other._retryable == _retryable &&
        other._cause == _cause;
  }

  @override
  int get hashCode =>
      Object.hash(_success, _value, _message, _retryable, _cause);

  @override
  String toString() => _success
      ? 'LoadResult<$T>.success($_value)'
      : 'LoadResult<$T>.failure($_message, retryable: $_retryable)';
}
