import 'dart:convert';
import 'dart:math';

/// 共有ストレージのディレクトリ（他現世と共通）
const String kTakamagaharaSharedDir = '/data/local/tmp/takamagahara_shared';

/// election-game が書き出す報酬イベントのファイル名
const String kElectionRewardEventsFileName = 'election_reward_events.jsonl';

/// 凍結契約 v1 のイベント種別
const String kElectionCompletedEventType = 'election_completed';
const String kQuizCompletedEventType = 'quiz_completed';

/// クロスアプリ連携コードの正規化（前後の空白のみ落とす）。
///
/// コードは rpg-task のリンク設定画面で入力される tsundoku の user_id。
/// 前後の空白混入だけで照合が外れるのを防ぐ。
String normalizeLinkCode(String raw) => raw.trim();

/// 連携コードから書き出し用 user_id（先頭8文字）を導く。
///
/// rpg-task の `FileCrossAppRewardService` は
/// `event.userId.startsWith(linkedUserId)` で照合するため、
/// 書き出す user_id は連携コードの先頭8文字に揃える。
/// 8文字未満・空は照合不能なので空文字を返す（=書き出し抑止）。
String exportUserIdFrom(String linkCode) {
  final normalized = normalizeLinkCode(linkCode);
  if (normalized.length < 8) return '';
  return normalized.substring(0, 8);
}

/// タイムスタンプ整形。常に UTC の ISO8601（`...Z`）へ正規化する。
String formatTimestamp(DateTime timestamp) =>
    timestamp.toUtc().toIso8601String();

/// 得票率（0..100）へクランプする。負値は 0。
int normalizeVoteShare(int raw) => raw < 0 ? 0 : (raw > 100 ? 100 : raw);

/// 件数系（wins / correct_count / total）の負値を 0 に丸める。
int normalizeCount(int raw) => raw < 0 ? 0 : raw;

/// イベントIDを生成する（32桁 hex）。
///
/// uuid パッケージは未導入のため新規依存を足さず、`Random.secure()` を用いる。
/// web 等で secure 乱数が使えない環境では通常の `Random()` へ退避する。
String generateEventId([Random? random]) {
  Random rng;
  if (random != null) {
    rng = random;
  } else {
    try {
      rng = Random.secure();
    } catch (_) {
      rng = Random();
    }
  }
  final buffer = StringBuffer();
  for (var i = 0; i < 16; i++) {
    buffer.write(rng.nextInt(256).toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// 当選者の得票率（0..100 の整数・四捨五入）。
///
/// 総得票0・当選者不明は 0。負の票は 0 として扱う。
int voteSharePercent(Map<String, int>? voteCounts, String? winnerId) {
  if (voteCounts == null || winnerId == null) return 0;
  var total = 0;
  for (final votes in voteCounts.values) {
    if (votes > 0) total += votes;
  }
  if (total <= 0) return 0;
  final winnerVotes = voteCounts[winnerId] ?? 0;
  final clamped = winnerVotes < 0 ? 0 : winnerVotes;
  return normalizeVoteShare((clamped * 100 / total).round());
}

/// `election_completed` イベント（凍結契約 v1）を組み立てる純粋関数。
///
/// 出力スキーマ:
/// `{event_id, event_type, user_id, timestamp, metadata}`
/// metadata: `{wins, won, vote_share, scale, election_id}`
Map<String, dynamic> buildElectionCompletedEvent({
  required String userId,
  required int wins,
  required bool won,
  required int voteShare,
  required String scale,
  required String electionId,
  DateTime Function() clock = DateTime.now,
  String Function()? eventIdGenerator,
}) {
  final generateId = eventIdGenerator ?? generateEventId;
  return <String, dynamic>{
    'event_id': generateId(),
    'event_type': kElectionCompletedEventType,
    'user_id': normalizeLinkCode(userId),
    'timestamp': formatTimestamp(clock()),
    'metadata': <String, dynamic>{
      'wins': normalizeCount(wins),
      'won': won,
      'vote_share': normalizeVoteShare(voteShare),
      'scale': scale,
      'election_id': electionId,
    },
  };
}

/// `quiz_completed` イベント（凍結契約 v1）を組み立てる純粋関数。
///
/// metadata: `{correct_count, total, passed}`
Map<String, dynamic> buildQuizCompletedEvent({
  required String userId,
  required int correctCount,
  required int total,
  required bool passed,
  DateTime Function() clock = DateTime.now,
  String Function()? eventIdGenerator,
}) {
  final generateId = eventIdGenerator ?? generateEventId;
  return <String, dynamic>{
    'event_id': generateId(),
    'event_type': kQuizCompletedEventType,
    'user_id': normalizeLinkCode(userId),
    'timestamp': formatTimestamp(clock()),
    'metadata': <String, dynamic>{
      'correct_count': normalizeCount(correctCount),
      'total': normalizeCount(total),
      'passed': passed,
    },
  };
}

/// イベントを JSONL の1行へ符号化する（改行は含めない）。
///
/// `jsonEncode` は文字列中の改行をエスケープするため、
/// 返り値は必ず1行（`\n` なし）になる。
String encodeEventLine(Map<String, dynamic> event) => jsonEncode(event);
