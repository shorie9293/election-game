import 'package:election_game/domain/models/candidate.dart';
import 'package:election_game/domain/models/election.dart';


/// 選挙結果の物語的情報
class ElectionNarrative {
  /// 当選者のスピーチ
  final String winnerSpeech;

  /// NPC（他の市民・候補者）の反応
  final List<String> npcReactions;

  /// 投票行動の理由サマリー
  final String reasoningSummary;

  /// 社会ムードの物語的説明
  final String moodStory;

  const ElectionNarrative({
    this.winnerSpeech = '',
    this.npcReactions = const [],
    this.reasoningSummary = '',
    this.moodStory = '',
  });

  static const empty = ElectionNarrative();
}

/// 投票結果を物語化するサービス
class NarrativeService {
  NarrativeService._();

  /// 選挙結果から物語的ナラティブを生成する
  static ElectionNarrative generateNarrative(
    Election result,
    String? votedCandidateId,
    bool abstained,
  ) {
    if (result.winnerId == null || result.voteCounts == null) {
      return ElectionNarrative.empty;
    }

    final winner = _findCandidate(result, result.winnerId!);
    final winnerSpeech =
        winner != null ? _buildWinnerSpeech(winner, result) : '';
    final npcReactions =
        _buildNpcReactions(result, winner);
    final reasoningSummary = _buildReasoningSummary(
      result, votedCandidateId, abstained, winner,
    );
    final moodStory = _buildMoodStory(result, winner);

    return ElectionNarrative(
      winnerSpeech: winnerSpeech,
      npcReactions: npcReactions,
      reasoningSummary: reasoningSummary,
      moodStory: moodStory,
    );
  }

  /// 当選者のスピーチを生成
  static String _buildWinnerSpeech(Candidate winner, Election result) {
    final voteCount = result.voteCounts![winner.id] ?? 0;
    final totalVotes =
        result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final percentage =
        totalVotes > 0 ? (voteCount * 100 ~/ totalVotes) : 0;

    final buffer = StringBuffer();
    buffer.writeln('${winner.name} 氏の勝利演説：');
    buffer.writeln();
    buffer.writeln(
      '「皆さんのご支援に心より感謝します。'
      '$percentage%の得票をいただき、身の引き締まる思いです。」',
    );

    // 候補者の personality に基づく演説
    if (winner.personality.contains('経済') || winner.personality.contains('豊か')) {
      buffer.writeln('「私たちの町を、誰もが豊かに暮らせる場所にしていきましょう。」');
    } else if (winner.personality.contains('支え合')) {
      buffer.writeln('「助け合いの心を大切に、誰一人取り残さない社会を目指します。」');
    } else if (winner.personality.contains('伝統') || winner.personality.contains('安定')) {
      buffer.writeln('「先人から受け継いだこの町の良さを、次の世代へ確かに繋いでまいります。」');
    } else if (winner.personality.contains('若者')) {
      buffer.writeln('「若い力と新しい発想で、この町に新しい風を吹き込みます。」');
    } else {
      buffer.writeln('「この町の未来のために、全力を尽くします。」');
    }

    // 主要政策への言及
    if (winner.policies.isNotEmpty) {
      final mainPolicy = winner.policies.first;
      buffer.writeln(
        '「公約に掲げた『${mainPolicy.title}』を中心に、'
        '具体的な政策を実行してまいります。」',
      );
    }

    return buffer.toString().trim();
  }

  /// NPC（他の候補者・市民）の反応を生成
  static List<String> _buildNpcReactions(
    Election result,
    Candidate? winner,
  ) {
    final reactions = <String>[];

    // 落選した候補者の反応
    for (final candidate in result.candidates) {
      if (candidate.id == result.winnerId) continue;

      final voteCount = result.voteCounts![candidate.id] ?? 0;
      if (candidate.faction.contains('共生')) {
        reactions.add(
          '${candidate.name} 氏：「結果は残念ですが、${winner?.name ?? "当選者"}さんの'
          '政策を注視していきます。福祉の視点は忘れないでほしい。」',
        );
      } else if (candidate.faction.contains('発展')) {
        reactions.add(
          '${candidate.name} 氏：「町の成長は待ったなしです。新政権でも経済を止めないでください。」',
        );
      } else if (candidate.faction.contains('守り')) {
        reactions.add(
          '${candidate.name} 氏：「$voteCount票をいただいた責任として、'
          '治安と伝統を守る立場から提言を続けます。」',
        );
      } else if (candidate.faction.contains('改革')) {
        reactions.add(
          '${candidate.name} 氏：「今回の結果を糧に、若者の声をより多くの人に届けます。」',
        );
      }
    }

    // 一般市民の反応（得票差に基づく）
    final winnerVotes = result.voteCounts![result.winnerId!] ?? 0;
    final totalVotes =
        result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final winnerPct = totalVotes > 0 ? winnerVotes / totalVotes : 0.0;

    if (winnerPct > 0.6) {
      reactions.add('市民A：「今回ははっきりとした結果が出たね。町が一つの方向に動きそうだ。」');
    } else if (winnerPct >= 0.4) {
      reactions.add('市民B：「いい選挙だった。競い合うことで良い政策が生まれる。」');
    } else {
      reactions.add('市民C：「意見が分かれたな…みんなが納得できる政策が必要だ。」');
    }

    return reactions;
  }

  /// 投票行動の理由サマリーを生成
  static String _buildReasoningSummary(
    Election result,
    String? votedCandidateId,
    bool abstained,
    Candidate? winner,
  ) {
    if (abstained) {
      return 'あなたは今回の選挙を棄権しました。'
          '棄権により、あなたの生活に関わる政策決定に'
          'あなたの意思は反映されませんでした。'
          '次の選挙では、あなたの一票が町の未来を変えるかもしれません。';
    }

    if (votedCandidateId == null) {
      return 'あなたは投票しませんでした。';
    }

    final voted = _findCandidate(result, votedCandidateId);
    final votedName = voted?.name ?? '不明';
    final winnerName = winner?.name ?? '不明';

    final winnerVotes = result.voteCounts![result.winnerId!] ?? 0;
    final totalVotes =
        result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final winnerPct =
        totalVotes > 0 ? (winnerVotes * 100 ~/ totalVotes) : 0;

    final buffer = StringBuffer();

    if (votedCandidateId == result.winnerId) {
      buffer.writeln(
        'あなたが投票した $votedName 氏が当選しました。',
      );
      buffer.writeln(
        '$winnerPct%の得票で信任を得た新政権のもと、'
        'あなたが支持した政策が現実のものとなります。',
      );
      buffer.write(
        'あなたの一票が、この選挙結果を後押ししました。',
      );
    } else {
      buffer.writeln(
        'あなたが投票した $votedName 氏は惜しくも落選しました。',
      );
      buffer.writeln(
        '当選した $winnerName 氏が $winnerPct%の票を獲得し、'
        '新たなリーダーとなります。',
      );
      buffer.write(
        'あなたの意見は今回の結果には直接結びつきませんでしたが、'
        '次の選挙で再び意思を示すことができます。',
      );
    }

    return buffer.toString().trim();
  }

  /// 社会ムードの物語的説明を生成
  static String _buildMoodStory(Election result, Candidate? winner) {
    final winnerVotes = result.voteCounts![result.winnerId!] ?? 0;
    final totalVotes =
        result.voteCounts!.values.fold<int>(0, (a, b) => a + b);
    final winnerPct = totalVotes > 0 ? winnerVotes / totalVotes : 0.0;
    final winnerName = winner?.name ?? '当選者';

    if (winnerPct > 0.6) {
      return '$winnerName 氏の大差での勝利により、'
          '町の空気は大きく変わりつつあります。'
          '多くの市民が同じ方向を向いたことで、政策は力強く推進されるでしょう。'
          'ただし、少数意見が埋もれないよう注意が必要です。';
    } else if (winnerPct >= 0.4) {
      return '$winnerName 氏の勝利は僅差でした。'
          '町には多様な意見が存在し、健全な競争が行われています。'
          '新政権には、対立候補の支持者の声にも耳を傾ける姿勢が求められます。';
    } else {
      return '意見が割れる接戦の末、$winnerName 氏が選ばれました。'
          '町の分断が深まっており、融和を図る政策が急務です。'
          '対話と歩み寄りが、これからの町の課題となるでしょう。';
    }
  }

  static Candidate? _findCandidate(Election election, String id) {
    try {
      return election.candidates.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
