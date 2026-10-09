import 'package:election_game/domain/models/citizen_enums.dart';
import 'package:election_game/domain/models/election.dart';
import 'package:election_game/domain/models/life_param_snapshot.dart';
import 'package:election_game/domain/models/life_param_trend.dart';
import 'package:election_game/domain/services/election_archive_service.dart';

/// 生活パラメータ推移の純粋ロジックを集めたサービス。
///
/// 副作用・I/O・現在時刻・乱数への依存は一切持たない（完全な静的メソッドのみ）。
class LifeParamTrendService {
  LifeParamTrendService._();

  /// 完了した選挙と選挙後の生活パラメータからスナップショットを作る。
  ///
  /// occurredAt は [ElectionArchiveService.timestampFromId] の結果。
  /// null（不正なID形式）の場合は epoch(0) を使う。
  static LifeParamSnapshot fromElection(
    Election election,
    Map<String, int> lifeParams,
  ) {
    return LifeParamSnapshot(
      electionId: election.id,
      occurredAt:
          ElectionArchiveService.timestampFromId(election.id) ??
              DateTime.fromMillisecondsSinceEpoch(0),
      values: Map<String, int>.of(lifeParams),
    );
  }

  /// 時刻昇順に並べ替える（同一時刻は electionId 昇順）。
  ///
  /// 入力は変更せず新しいリストを返す。
  static List<LifeParamSnapshot> sortSnapshots(
    List<LifeParamSnapshot> snapshots,
  ) {
    final sorted = List<LifeParamSnapshot>.of(snapshots)
      ..sort((a, b) {
        final cmp = a.occurredAt.compareTo(b.occurredAt);
        if (cmp != 0) return cmp;
        return a.electionId.compareTo(b.electionId);
      });
    return List.unmodifiable(sorted);
  }

  /// スナップショット群に出現するキーを返す。
  ///
  /// - 既知キーは [LifeParamKeys.all] の宣言順
  /// - 未知キーは文字列昇順で既知キーの後
  /// - 重複なし
  static List<String> availableKeys(List<LifeParamSnapshot> snapshots) {
    final present = <String>{};
    for (final s in snapshots) {
      present.addAll(s.values.keys);
    }
    final known = <String>[];
    final unknown = <String>[];
    for (final key in LifeParamKeys.all) {
      if (present.contains(key)) known.add(key);
    }
    for (final key in present) {
      if (!LifeParamKeys.all.contains(key)) unknown.add(key);
    }
    unknown.sort();
    return List.unmodifiable([...known, ...unknown]);
  }

  /// キーのラベルを返す。既知キーは [LifeParamKeys.label]、未知キーは生のキー。
  static String labelFor(String key) {
    final label = LifeParamKeys.label(key);
    return label.isEmpty ? key : label;
  }

  /// 指定キーの時系列を作る。
  ///
  /// - キーを持たないスナップショットは読み飛ばす（補間しない）
  /// - delta は直前の「キーを含む」点との差（最初の点は0）
  static LifeParamTrendSeries buildSeries(
    List<LifeParamSnapshot> snapshots,
    String key,
  ) {
    final sorted = sortSnapshots(snapshots);
    final points = <LifeParamTrendPoint>[];
    for (final s in sorted) {
      final value = s.valueOf(key);
      if (value == null) continue;
      final delta = points.isEmpty ? 0 : value - points.last.value;
      points.add(LifeParamTrendPoint(
        electionId: s.electionId,
        occurredAt: s.occurredAt,
        value: value,
        delta: delta,
      ));
    }
    return LifeParamTrendSeries(
      key: key,
      label: labelFor(key),
      points: List.unmodifiable(points),
    );
  }

  /// [availableKeys] の順で全キーの時系列を作る。
  static List<LifeParamTrendSeries> buildAll(List<LifeParamSnapshot> snapshots) {
    return List.unmodifiable(
      availableKeys(snapshots).map((key) => buildSeries(snapshots, key)),
    );
  }

  /// キーを含む最も新しいスナップショットの値。無ければ0。
  static int latestValue(List<LifeParamSnapshot> snapshots, String key) {
    final sorted = sortSnapshots(snapshots);
    for (var i = sorted.length - 1; i >= 0; i--) {
      final value = sorted[i].valueOf(key);
      if (value != null) return value;
    }
    return 0;
  }
}
