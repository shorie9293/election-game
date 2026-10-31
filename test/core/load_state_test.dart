import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/load_state.dart';

void main() {
  group('LoadState', () {
    test('loading は isLoading のみ true で値を持たない', () {
      final state = LoadState<int>.loading();
      expect(state.phase, LoadPhase.loading);
      expect(state.isLoading, isTrue);
      expect(state.isData, isFalse);
      expect(state.isEmpty, isFalse);
      expect(state.isError, isFalse);
      expect(state.valueOrNull, isNull);
      expect(state.message, isNull);
      expect(state.retryable, isFalse);
    });

    test('data は値を保持し isData のみ true', () {
      final state = LoadState<int>.data(42);
      expect(state.phase, LoadPhase.data);
      expect(state.isData, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.valueOrNull, 42);
      expect(state.message, isNull);
    });

    test('empty は値もメッセージも持たない', () {
      final state = LoadState<int>.empty();
      expect(state.phase, LoadPhase.empty);
      expect(state.isEmpty, isTrue);
      expect(state.isError, isFalse);
      expect(state.valueOrNull, isNull);
      expect(state.message, isNull);
    });

    test('error は message/retryable/cause を保持する', () {
      final cause = StateError('boom');
      final state = LoadState<int>.error('読めない', retryable: false, cause: cause);
      expect(state.phase, LoadPhase.error);
      expect(state.isError, isTrue);
      expect(state.message, '読めない');
      expect(state.retryable, isFalse);
      expect(state.cause, same(cause));
      expect(state.valueOrNull, isNull);
    });

    test('error の message 空文字は ArgumentError', () {
      expect(() => LoadState<int>.error(''), throwsArgumentError);
      expect(() => LoadState<int>.error('   '), throwsArgumentError);
    });

    test('data の null は ArgumentError', () {
      expect(() => LoadState<String?>.data(null), throwsArgumentError);
    });

    test('when は各フェーズのコールバックへ分岐する', () {
      String label(LoadState<int> s) => s.when(
            loading: () => 'loading',
            data: (v) => 'data:$v',
            empty: () => 'empty',
            error: (m, r) => 'error:$m:$r',
          );
      expect(label(LoadState<int>.loading()), 'loading');
      expect(label(LoadState<int>.data(7)), 'data:7');
      expect(label(LoadState<int>.empty()), 'empty');
      expect(label(LoadState<int>.error('x', retryable: false)), 'error:x:false');
    });

    test('== と hashCode はフェーズ・値・メッセージ・再試行可否で決まる', () {
      expect(LoadState<int>.loading(), LoadState<int>.loading());
      expect(LoadState<int>.loading().hashCode,
          LoadState<int>.loading().hashCode);
      expect(LoadState<int>.data(1), LoadState<int>.data(1));
      expect(LoadState<int>.data(1), isNot(LoadState<int>.data(2)));
      expect(LoadState<int>.empty(), isNot(LoadState<int>.loading()));
      expect(
        LoadState<int>.error('e', retryable: true),
        LoadState<int>.error('e', retryable: true),
      );
      expect(
        LoadState<int>.error('e', retryable: true),
        isNot(LoadState<int>.error('e', retryable: false)),
      );
    });

    test('toString はフェーズを判別できる', () {
      expect(LoadState<int>.loading().toString(), contains('loading'));
      expect(LoadState<int>.data(1).toString(), contains('data'));
      expect(LoadState<int>.empty().toString(), contains('empty'));
      expect(LoadState<int>.error('e').toString(), contains('error'));
    });
  });

  group('LoadResult', () {
    test('success は値を保持し isSuccess のみ true', () {
      final result = LoadResult<int>.success(3);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 3);
      expect(result.message, isNull);
    });

    test('success(null) は0件として成功扱い', () {
      final result = LoadResult<String?>.success(null);
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('failure は message/retryable/cause を保持する', () {
      final cause = Exception('io');
      final result =
          LoadResult<int>.failure('失敗', retryable: false, cause: cause);
      expect(result.isFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.message, '失敗');
      expect(result.retryable, isFalse);
      expect(result.cause, same(cause));
    });

    test('failure の message 空文字は ArgumentError', () {
      expect(() => LoadResult<int>.failure(''), throwsArgumentError);
    });

    test('when は成否で分岐する', () {
      String label(LoadResult<int> r) => r.when(
            success: (v) => 'ok:$v',
            failure: (m, retry) => 'ng:$m:$retry',
          );
      expect(label(LoadResult<int>.success(1)), 'ok:1');
      expect(label(LoadResult<int>.failure('x')), 'ng:x:true');
    });

    test('== と hashCode は成否・値・メッセージで決まる', () {
      expect(LoadResult<int>.success(1), LoadResult<int>.success(1));
      expect(LoadResult<int>.success(1).hashCode,
          LoadResult<int>.success(1).hashCode);
      expect(LoadResult<int>.success(1), isNot(LoadResult<int>.success(2)));
      expect(
        LoadResult<int>.failure('e'),
        isNot(LoadResult<int>.success(0)),
      );
      expect(LoadResult<int>.failure('e'), LoadResult<int>.failure('e'));
    });
  });
}
