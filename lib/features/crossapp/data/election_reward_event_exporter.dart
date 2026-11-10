import 'dart:io';

import 'package:election_game/core/infrastructure/shared_file_store.dart';
import 'package:election_game/core/logging/app_logger.dart';
import 'package:election_game/features/crossapp/domain/election_reward_event.dart';

/// クロスアプリ報酬イベントの書き出し口。
///
/// rpg-task が共有ストレージの JSONL を読み、コイン/EXP/称号を付与する。
/// 書き出しは best-effort（失敗しても本編を止めない）。
abstract class IElectionRewardEventExporter {
  /// 書き出しに使う user_id（連携コードの先頭8文字）。
  ///
  /// 空のまま書き出すと rpg-task の `CrossAppRewardEvent.fromJson` が
  /// user_id 空で行ごと捨てるため、実装は空のとき書き出さないこと。
  String get userId;
  set userId(String value);

  /// 選挙確定イベント（`election_completed`）を1行追記する。
  Future<void> exportElectionCompleted({
    required int wins,
    required bool won,
    required int voteShare,
    required String scale,
    required String electionId,
  });

  /// クイズ採点イベント（`quiz_completed`）を1行追記する。
  Future<void> exportQuizCompleted({
    required int correctCount,
    required int total,
    required bool passed,
  });
}

/// 共有ストレージへ JSONL を追記する実装。
///
/// 既定の保存先は [SharedFileStore] が解決する（Android 実機では SAF の共有フォルダ）。
/// [filePath] を明示した場合のみ、そのパスへ直接書く（試練用の後方互換）。
/// 追記専用・1行1コンパクトJSON（凍結契約 v1）。
class FileElectionRewardEventExporter implements IElectionRewardEventExporter {
  /// 試練用の明示パス。null なら共有ストア経由。
  final String? filePath;

  /// 共有ストアの差し替え（試練用）。null なら [SharedFileStore.instance]。
  final ISharedFileStore? store;

  /// 時刻注入（試練で固定時刻にするため）
  final DateTime Function() clock;

  /// イベントID注入（試練で固定IDにするため）
  final String Function() eventIdGenerator;

  String _userId;

  FileElectionRewardEventExporter({
    this.filePath,
    this.store,
    String? userId,
    DateTime Function()? clock,
    String Function()? eventIdGenerator,
  })  : _userId = userId ?? '',
        clock = clock ?? DateTime.now,
        eventIdGenerator = eventIdGenerator ?? generateEventId;

  @override
  String get userId => _userId;

  @override
  set userId(String value) => _userId = value;

  @override
  Future<void> exportElectionCompleted({
    required int wins,
    required bool won,
    required int voteShare,
    required String scale,
    required String electionId,
  }) {
    final event = buildElectionCompletedEvent(
      userId: _userId,
      wins: wins,
      won: won,
      voteShare: voteShare,
      scale: scale,
      electionId: electionId,
      clock: clock,
      eventIdGenerator: eventIdGenerator,
    );
    return _appendLine(event);
  }

  @override
  Future<void> exportQuizCompleted({
    required int correctCount,
    required int total,
    required bool passed,
  }) {
    final event = buildQuizCompletedEvent(
      userId: _userId,
      correctCount: correctCount,
      total: total,
      passed: passed,
      clock: clock,
      eventIdGenerator: eventIdGenerator,
    );
    return _appendLine(event);
  }

  /// JSONL へ1行追記する。
  ///
  /// - [filePath] 明示時は従来どおりのベストエフォート（失敗は握りつぶす）。
  /// - 共有ストア経由では失敗を**無音にせず** [SharedStorageException] として
  ///   上位へ伝える。呼び出し側（選挙・クイズの本処理）はこれを連携失敗として
  ///   記録し、本編は止めない。
  Future<void> _appendLine(Map<String, dynamic> event) async {
    if (_userId.trim().isEmpty) return;
    final line = encodeEventLine(event);

    if (filePath != null) {
      await _appendToFile(filePath!, line);
      return;
    }

    try {
      await (store ?? SharedFileStore.instance).appendLine(
        SharedCrossAppFiles.electionRewardEvents,
        line,
      );
    } on SharedStorageException catch (e, stack) {
      appLog.warn('[crossapp] 選挙報酬イベントの書き出し失敗', e, stack);
      rethrow;
    }
  }

  /// 試練用: 明示パスへの直書き（従来の契約をそのまま保持）。
  Future<void> _appendToFile(String path, String line) async {
    try {
      final file = File(path);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '$line\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      // Best-effort export — 書き込み失敗は本編の進行を妨げない
    }
  }
}
