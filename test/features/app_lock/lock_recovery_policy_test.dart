import 'package:flutter_test/flutter_test.dart';

import 'package:election_game/core/infrastructure/lock_recovery_policy.dart';

void main() {
  test('確認語は「初期化」で固定されている', () {
    expect(LockRecoveryPolicy.confirmationPhrase, '初期化');
  });

  test('canRecover はロック有効時のみ true', () {
    expect(LockRecoveryPolicy.canRecover(enabled: true), isTrue);
    expect(LockRecoveryPolicy.canRecover(enabled: false), isFalse);
  });

  test('確認語の完全一致のみ有効（前後空白は許容）', () {
    expect(LockRecoveryPolicy.isConfirmationValid('初期化'), isTrue);
    expect(LockRecoveryPolicy.isConfirmationValid('  初期化\n'), isTrue);
    expect(LockRecoveryPolicy.isConfirmationValid('初期化する'), isFalse);
    expect(LockRecoveryPolicy.isConfirmationValid('初期'), isFalse);
    expect(LockRecoveryPolicy.isConfirmationValid(''), isFalse);
  });

  test('警告文はデータ消失とバックアップの不確実性に触れる', () {
    expect(LockRecoveryPolicy.warningMessage, contains('元に戻せません'));
    expect(LockRecoveryPolicy.warningMessage, contains('バックアップ'));
  });
}
