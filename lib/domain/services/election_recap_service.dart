import 'package:election_game/domain/models/election_archive.dart';
import 'package:election_game/domain/models/election_recap.dart';
import 'package:election_game/domain/models/turnout_snapshot.dart';

/// アーカイブエントリから振り返りカードを組むサービス。
class ElectionRecapService {
  ElectionRecapService._();

  /// アーカイブエントリから振り返りを組む。turnout があれば投票率・関心ラベルを載せる。
  static ElectionRecap build(ElectionArchiveEntry entry,
      {TurnoutSnapshot? turnout}) {
    return ElectionRecap(
      electionId: entry.electionId,
      title: entry.title,
      scaleLabel: entry.scaleLabel,
      winnerName: entry.winnerName,
      winnerVotes: entry.winnerVotes,
      totalVotes: entry.totalVotes,
      runnerUpVotes: entry.runnerUpVotes,
      occurredAt: entry.occurredAt,
      turnoutRate: turnout?.turnoutRate,
      turnoutLabel: turnout?.turnoutLabel,
    );
  }

  /// entries の末尾（occurredAt 昇順に並んでいる前提＝最新）の振り返り。空なら null。
  static ElectionRecap? latest(
    List<ElectionArchiveEntry> entries, {
    Map<String, TurnoutSnapshot> turnoutsByElectionId = const {},
  }) {
    if (entries.isEmpty) return null;
    final entry = entries.last;
    final turnout = turnoutsByElectionId[entry.electionId];
    return build(entry, turnout: turnout);
  }
}