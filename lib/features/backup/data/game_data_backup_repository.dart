import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/backup/domain/game_data_backup.dart';

abstract class GameDataBackupRepository {
  /// BackupKeySpec.all に一致する現在の値を収集
  Future<Map<String, Object?>> collect();

  /// data を書き戻す。clearExisting なら先に既存管理キーを消す。
  Future<void> restore(Map<String, Object?> data, {bool clearExisting = false});

  /// 管理キーのみ消す
  Future<void> clear();
}

bool _isManagedKey(String key) {
  return BackupKeySpec.all.any((spec) => spec.matches(key));
}

class SharedPreferencesGameDataBackupRepository
    implements GameDataBackupRepository {
  const SharedPreferencesGameDataBackupRepository();

  @override
  Future<Map<String, Object?>> collect() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <String, Object?>{};
    for (final key in prefs.getKeys()) {
      if (!_isManagedKey(key)) {
        continue;
      }
      final value = prefs.get(key);
      if (value is List) {
        final strings = value.whereType<String>().toList();
        if (strings.length != value.length) {
          continue; // List<String> にキャストできなければスキップ
        }
        result[key] = strings;
      } else if (value is bool ||
          value is int ||
          value is double ||
          value is String) {
        result[key] = value;
      }
    }
    return result;
  }

  @override
  Future<void> restore(
    Map<String, Object?> data, {
    bool clearExisting = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (clearExisting) {
      await clear();
    }
    for (final entry in data.entries) {
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(entry.key, value);
      } else if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is double) {
        await prefs.setDouble(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      } else if (value is List<String>) {
        await prefs.setStringList(entry.key, value);
      }
      // 未知型はスキップ
    }
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getKeys().where(_isManagedKey).toList()) {
      await prefs.remove(key);
    }
  }
}

class InMemoryGameDataBackupRepository implements GameDataBackupRepository {
  final Map<String, Object?> store;

  InMemoryGameDataBackupRepository([Map<String, Object?>? initial])
      : store = Map.from(initial ?? const {});

  @override
  Future<Map<String, Object?>> collect() async {
    return {
      for (final entry in store.entries)
        if (_isManagedKey(entry.key)) entry.key: entry.value,
    };
  }

  @override
  Future<void> restore(
    Map<String, Object?> data, {
    bool clearExisting = false,
  }) async {
    if (clearExisting) {
      // SharedPreferences 実装と同一意味論: 管理対象キーのみを消す
      // （管理外キーは巻き込んで破壊しない）
      await clear();
    }
    store.addAll(data);
  }

  @override
  Future<void> clear() async {
    store.removeWhere((key, _) => _isManagedKey(key));
  }
}

class NoopGameDataBackupRepository implements GameDataBackupRepository {
  const NoopGameDataBackupRepository();

  @override
  Future<Map<String, Object?>> collect() async => {};

  @override
  Future<void> restore(Map<String, Object?> data,
      {bool clearExisting = false}) async {}

  @override
  Future<void> clear() async {}
}
