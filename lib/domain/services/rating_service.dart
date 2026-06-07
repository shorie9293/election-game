import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/candidate_rating.dart';

/// 候補者評価を SharedPreferences に永続化するサービス
class RatingService {
  static const _prefix = 'candidate_rating_';

  /// 評価を保存する
  static Future<void> saveRating(CandidateRating rating) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${rating.candidateId}';
    await prefs.setString(key, jsonEncode(rating.toJson()));
  }

  /// 特定の候補者の評価を取得する
  static Future<CandidateRating?> getRating(String candidateId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$candidateId';
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return CandidateRating.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// 全候補者の評価を取得する
  static Future<List<CandidateRating>> getAllRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratings = <CandidateRating>[];

    for (final key in prefs.getKeys()) {
      if (key.startsWith(_prefix)) {
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            ratings.add(CandidateRating.fromJson(json));
          } catch (_) {
            // 破損データはスキップ
          }
        }
      }
    }

    return ratings;
  }

  /// 全ての評価を削除する
  static Future<void> clearAllRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = prefs.getKeys().where((k) => k.startsWith(_prefix));
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }
}
