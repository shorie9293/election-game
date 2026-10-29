import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:election_game/domain/models/play_activity_heatmap.dart';
import 'package:election_game/domain/repositories/election_archive_repository.dart';
import 'package:election_game/domain/services/play_activity_heatmap_service.dart';

/// 選挙アーカイブの一次情報源。
///
/// 試練では `overrideWithValue` でフェイクへ差し替える。
final electionArchiveRepositoryProvider = Provider<ElectionArchiveRepository>(
  (ref) => const SharedPreferencesElectionArchiveRepository(),
);

/// アプリが現在認識している「今日」（ローカル時刻）。
///
/// 日付跨ぎ（[DayRolloverResult.rolledOver]）時に
/// `container.invalidate(appTodayProvider)` で撃ち直すことで、
/// これを watch する日付依存 Provider が一斉に新暦日で再計算される。
final appTodayProvider = Provider<DateTime>((ref) => DateTime.now());

/// 今日を起点に集計するプレイ活動ヒートマップ（連続日数は「今日」依存）。
///
/// 実データ（選挙アーカイブ）を読み、[appTodayProvider] を watch する。
/// 日付跨ぎで「今日」が変わると currentStreak が誤ったまま残るため、
/// 前面復帰時に再計算させる必要がある。
final playActivityHeatmapProvider = FutureProvider<PlayActivityHeatmap>((
  ref,
) async {
  final today = ref.watch(appTodayProvider);
  final elections = await ref.watch(electionArchiveRepositoryProvider).load();
  return PlayActivityHeatmapService.build(elections, now: today);
});
