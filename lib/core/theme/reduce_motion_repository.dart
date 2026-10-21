import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/core/theme/reduce_motion_setting.dart';

/// 動きの削減設定のリポジトリ
abstract class ReduceMotionRepository {
  const ReduceMotionRepository();

  /// 保存された設定を読み込む。未保存/不正値は null（=system 扱い）。
  Future<ReduceMotionSetting?> load();

  /// 設定を保存する。
  Future<void> save(ReduceMotionSetting setting);
}

/// SharedPreferences に動きの削減設定を保存・復元するリポジトリ。
class SharedPreferencesReduceMotionRepository extends ReduceMotionRepository {
  static const String storageKey = 'election_reduce_motion';

  const SharedPreferencesReduceMotionRepository();

  @override
  Future<ReduceMotionSetting?> load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(storageKey)) return null;
    final value = prefs.getString(storageKey);
    if (value == null) return null;
    for (final setting in ReduceMotionSetting.values) {
      if (setting.storageKey == value) return setting;
    }
    return null;
  }

  @override
  Future<void> save(ReduceMotionSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, setting.storageKey);
  }
}

/// 試練（テスト）用のインメモリ実装。
class InMemoryReduceMotionRepository extends ReduceMotionRepository {
  InMemoryReduceMotionRepository([this.saved]);

  /// 最後に保存された設定（未保存は null）。
  ReduceMotionSetting? saved;

  /// `save` が呼ばれた回数。
  int saveCount = 0;

  @override
  Future<ReduceMotionSetting?> load() async => saved;

  @override
  Future<void> save(ReduceMotionSetting setting) async {
    saved = setting;
    saveCount++;
  }
}
