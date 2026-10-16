import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';
import 'package:election_game/domain/services/election_recap_service.dart';
import 'package:election_game/features/share/domain/election_share_card_data.dart';

/// 選挙アーカイブエントリから共有カードデータを組む純粋ロジック。
///
/// 整形の意味論は既存の [ElectionRecapService] と同一に保ち、
/// ここでは「生成日時」を足してカード用の値オブジェクトへ写すだけに留める
/// （二重定義を避けるため、ラベル文字列は ElectionShareCardData 側に集約）。
class ElectionShareCardService {
  ElectionShareCardService._();

  /// アーカイブエントリから共有カードを組む。
  static ElectionShareCardData build({
    required ElectionArchiveEntry entry,
    TurnoutSnapshot? turnout,
    required DateTime generatedAt,
  }) {
    final recap = ElectionRecapService.build(entry, turnout: turnout);
    return ElectionShareCardData(
      electionId: recap.electionId,
      title: recap.title,
      winnerName: recap.winnerName,
      winnerVotes: recap.winnerVotes,
      totalVotes: recap.totalVotes,
      runnerUpVotes: recap.runnerUpVotes,
      scaleLabel: recap.scaleLabel,
      turnoutRate: recap.turnoutRate,
      turnoutLabel: recap.turnoutLabel,
      occurredAt: recap.occurredAt,
      generatedAt: generatedAt,
    );
  }

  /// entries の末尾（occurredAt 昇順に並んでいる前提＝最新）の共有カード。
  /// 空リストなら null。
  static ElectionShareCardData? latest(
    List<ElectionArchiveEntry> entries, {
    Map<String, TurnoutSnapshot> turnoutsByElectionId = const {},
    required DateTime generatedAt,
  }) {
    if (entries.isEmpty) return null;
    final entry = entries.last;
    return build(
      entry: entry,
      turnout: turnoutsByElectionId[entry.electionId],
      generatedAt: generatedAt,
    );
  }
}
