import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/load_state.dart';
import '../domain/election_prediction.dart';

/// 選挙結果の予想を永続化するリポジトリの抽象。
abstract class PredictionRepository {
  /// 指定選挙の予想を読み込む。未保存・破損時は null。
  Future<ElectionPrediction?> load(String electionId);

  /// 指定選挙の予想を読み込み、失敗と0件を区別して返す。
  ///
  /// 既定実装は [load] の例外のみを failure に変換し、null を
  /// 「0件」として success に包む。破損を検知できる実装は上書きする。
  /// （既存実装を壊さないための後方互換な既定実装）
  Future<LoadResult<ElectionPrediction?>> tryLoad(String electionId) async {
    try {
      return LoadResult<ElectionPrediction?>.success(await load(electionId));
    } catch (error) {
      return LoadResult<ElectionPrediction?>.failure(
        '予想の読み込みに失敗しました',
        cause: error,
      );
    }
  }

  /// 予想を保存する（同一 electionId は上書き）。
  Future<void> save(ElectionPrediction prediction);

  /// 指定選挙の予想を削除する。
  Future<void> remove(String electionId);
}

/// SharedPreferences に予想を永続化するリポジトリ。
///
/// 保存形式: JSON map {electionId: predictionJson}
/// 破損時のフォールバック方針（election_archive_repository.dart と共通）:
/// キー未保存・JSON破損・型不一致 → null。
class SharedPreferencesPredictionRepository implements PredictionRepository {
  /// SharedPreferences 上の保存キー
  static const predictionsKey = 'election_predictions_v1';

  const SharedPreferencesPredictionRepository();

  /// 保存済み map を読む。未保存・破損・型不一致時は null。
  Future<Map<String, dynamic>?> _readMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(predictionsKey);
    if (raw == null) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) {
        return value is Map ? Map<String, dynamic>.from(value) : null;
      }
      return value;
    } catch (_) {
      // JSON全体が破損している場合は安全に null へフォールバック
      return null;
    }
  }

  @override
  Future<ElectionPrediction?> load(String electionId) async {
    final map = await _readMap();
    if (map == null) return null;
    final dynamic raw = map[electionId];
    if (raw is! Map) return null;
    try {
      return ElectionPrediction.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      // 1件の破損要素は null として扱う
      return null;
    }
  }

  @override
  Future<LoadResult<ElectionPrediction?>> tryLoad(String electionId) async {
    final String? raw;
    try {
      final prefs = await SharedPreferences.getInstance();
      raw = prefs.getString(predictionsKey);
    } catch (error) {
      return LoadResult<ElectionPrediction?>.failure(
        '予想の読み込みに失敗しました',
        cause: error,
      );
    }
    // 未保存は「0件」であり失敗ではない。
    if (raw == null) {
      return LoadResult<ElectionPrediction?>.success(null);
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (error) {
      return LoadResult<ElectionPrediction?>.failure(
        '保存された予想データが破損しています',
        cause: error,
      );
    }
    if (decoded is! Map) {
      return LoadResult<ElectionPrediction?>.failure(
        '保存された予想データの形式が不正です',
        cause:
            FormatException('expected JSON object, got ${decoded.runtimeType}'),
      );
    }

    final dynamic entry = Map<String, dynamic>.from(decoded)[electionId];
    if (entry == null) {
      return LoadResult<ElectionPrediction?>.success(null);
    }
    if (entry is! Map) {
      return LoadResult<ElectionPrediction?>.failure(
        '保存された予想データの形式が不正です',
        cause: FormatException('expected JSON object for $electionId'),
      );
    }
    try {
      return LoadResult<ElectionPrediction?>.success(
        ElectionPrediction.fromJson(Map<String, dynamic>.from(entry)),
      );
    } catch (error) {
      return LoadResult<ElectionPrediction?>.failure(
        '保存された予想データを復元できませんでした',
        cause: error,
      );
    }
  }

  @override
  Future<void> save(ElectionPrediction prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readMap() ?? <String, dynamic>{};
    map[prediction.electionId] = prediction.toJson();
    await prefs.setString(predictionsKey, jsonEncode(map));
  }

  @override
  Future<void> remove(String electionId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await _readMap();
    if (map == null || !map.containsKey(electionId)) return;
    map.remove(electionId);
    await prefs.setString(predictionsKey, jsonEncode(map));
  }
}

/// 試験用のメモリ内リポジトリ。SharedPreferences に触れない。
class InMemoryPredictionRepository implements PredictionRepository {
  /// 保存領域（試練から観察可能）
  final Map<String, ElectionPrediction> store;

  InMemoryPredictionRepository([Map<String, ElectionPrediction>? initial])
      : store = Map<String, ElectionPrediction>.from(initial ?? const {});

  @override
  Future<ElectionPrediction?> load(String electionId) async => store[electionId];

  @override
  Future<LoadResult<ElectionPrediction?>> tryLoad(String electionId) async =>
      LoadResult<ElectionPrediction?>.success(store[electionId]);

  @override
  Future<void> save(ElectionPrediction prediction) async {
    store[prediction.electionId] = prediction;
  }

  @override
  Future<void> remove(String electionId) async {
    store.remove(electionId);
  }
}

/// 何もしないリポジトリ（予想機能を無効化する場合の差し替え用）。
class NoopPredictionRepository implements PredictionRepository {
  const NoopPredictionRepository();

  @override
  Future<ElectionPrediction?> load(String electionId) async => null;

  @override
  Future<LoadResult<ElectionPrediction?>> tryLoad(String electionId) async =>
      LoadResult<ElectionPrediction?>.success(null);

  @override
  Future<void> save(ElectionPrediction prediction) async {}

  @override
  Future<void> remove(String electionId) async {}
}