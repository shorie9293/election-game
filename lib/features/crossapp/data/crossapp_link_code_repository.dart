import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/crossapp/domain/election_reward_event.dart';

/// クロスアプリ連携コード（= tsundoku の user_id）の永続化口。
///
/// rpg-task 側で同じコードを入力すると、本アプリが共有ストレージへ
/// 書き出す報酬イベントが報酬へ変換される（学びの循環の第4の脚）。
abstract class CrossAppLinkCodeRepository {
  /// 保存済みの連携コード。未保存なら null。
  Future<String?> load();

  /// 連携コードを保存する（実装側で正規化してよい）。
  Future<void> save(String code);

  /// 連携を解除する。
  Future<void> clear();
}

/// SharedPreferences 実装。キーは凍結契約の `crossapp_link_code`。
class SharedPreferencesCrossAppLinkCodeRepository
    implements CrossAppLinkCodeRepository {
  static const key = 'crossapp_link_code';

  const SharedPreferencesCrossAppLinkCodeRepository();

  @override
  Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(key);
    if (code == null) return null;
    final normalized = normalizeLinkCode(code);
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, normalizeLinkCode(code));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}

/// 試練・プレビュー用のメモリ実装。
class InMemoryCrossAppLinkCodeRepository implements CrossAppLinkCodeRepository {
  String? _code;

  InMemoryCrossAppLinkCodeRepository([String? initialCode])
      : _code = _normalize(initialCode);

  static String? _normalize(String? code) {
    if (code == null) return null;
    final normalized = normalizeLinkCode(code);
    return normalized.isEmpty ? null : normalized;
  }

  @override
  Future<String?> load() async => _code;

  @override
  Future<void> save(String code) async => _code = _normalize(code);

  @override
  Future<void> clear() async => _code = null;
}

/// 連携コードから書き出し用 user_id（先頭8文字）を解決する。
///
/// 読み込み失敗は握りつぶして空文字を返す（=書き出し抑止）。
/// 報酬イベントの書き出しで本編を止めないための best-effort。
Future<String> resolveExportUserId(
    CrossAppLinkCodeRepository repository) async {
  try {
    final code = await repository.load();
    if (code == null) return '';
    return exportUserIdFrom(code);
  } catch (_) {
    return '';
  }
}
