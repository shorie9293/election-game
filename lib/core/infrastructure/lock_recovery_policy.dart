/// パスコード忘却時の回復導線の純粋ロジック。
///
/// 破壊的操作（データ初期化）を伴うため、確認語の一致と
/// ロック有効状態の両方を満たすときだけ回復を許可する。
class LockRecoveryPolicy {
  /// 利用者に打ち込ませる確認語（前後空白は無視する）。
  static const String confirmationPhrase = '初期化';

  /// 実行前に見せる警告文。
  static const String warningMessage = '初期化すると、学習の進み具合・設定などのデータは元に戻せません。'
      'パスコードは解除され、次回からパスコードなしで起動します。'
      '必要なら先にバックアップが書き出されます（失敗する場合もあります）。';

  /// 回復を実行してよい状態か。
  ///
  /// ロックされていない（＝解除済み・未設定）なら何も壊す必要がないので false。
  static bool canRecover({required bool enabled}) => enabled;

  /// 確認語が一致するか（前後の空白は無視）。
  static bool isConfirmationValid(String input) =>
      input.trim() == confirmationPhrase;
}
