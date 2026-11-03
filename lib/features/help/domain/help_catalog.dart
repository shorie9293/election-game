import 'package:election_game/features/help/domain/help_topic.dart';
import 'package:election_game/features/tutorial/domain/tutorial_step.dart';

/// ヘルプの章立てを提供する純粋カタログ。
///
/// 文言の正は [TutorialStep]（label / description）。ここで文字列を
/// 再定義してはならない（二重管理の温床）。I/O は一切行わない。
class HelpCatalog {
  const HelpCatalog();

  /// 宣言順（TutorialStep.values の順）の全トピック。
  List<HelpTopic> get allTopics => TutorialStep.values
      .map(
        (step) => HelpTopic(
          id: step.name,
          title: step.label,
          body: step.description,
        ),
      )
      .toList(growable: false);

  /// タイトル・本文の部分一致で絞り込む（大文字小文字を無視）。
  /// 空クエリ／空白のみは全件。該当なしは空。宣言順は維持する。
  List<HelpTopic> search(String query) {
    final needle = query.trim().toLowerCase();
    final topics = allTopics;
    if (needle.isEmpty) {
      return topics;
    }
    return topics
        .where(
          (topic) =>
              topic.title.toLowerCase().contains(needle) ||
              topic.body.toLowerCase().contains(needle),
        )
        .toList(growable: false);
  }
}
