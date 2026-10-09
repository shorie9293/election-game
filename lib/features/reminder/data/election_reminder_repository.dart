import 'dart:convert';

import 'package:election_game/features/reminder/domain/election_reminder_settings.dart';
import 'package:hive/hive.dart';

/// 選挙リマインダー設定の永続化インターフェース。
abstract class ElectionReminderRepository {
  Future<ElectionReminderSettings> load();
  Future<void> save(ElectionReminderSettings s);
}

/// Hive 実装。box `election_reminder_box` / key `electionReminder` に
/// JSON 文字列で保存。破損・型不一致レコードは
/// [ElectionReminderSettings.defaults] へフォールバックする。
/// Hive が未初期化等の例外時も静かに defaults を返す。
class HiveElectionReminderRepository implements ElectionReminderRepository {
  static const String boxName = 'election_reminder_box';
  static const String keyName = 'electionReminder';

  Box<String>? _box;

  Future<Box<String>> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(boxName);
    return _box!;
  }

  @override
  Future<ElectionReminderSettings> load() async {
    try {
      final box = await _getBox();
      final raw = box.get(keyName);
      if (raw is! String) return ElectionReminderSettings.defaults();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return ElectionReminderSettings.defaults();
      }
      return ElectionReminderSettings.fromJson(decoded);
    } catch (_) {
      // 破損 JSON・Hive 未初期化等は全て静かに既定値へ。
      return ElectionReminderSettings.defaults();
    }
  }

  @override
  Future<void> save(ElectionReminderSettings s) async {
    final box = await _getBox();
    await box.put(keyName, jsonEncode(s.toJson()));
  }
}

/// 試練用のメモリ内リポジトリ。初期値を注入できる。
class InMemoryElectionReminderRepository implements ElectionReminderRepository {
  InMemoryElectionReminderRepository([ElectionReminderSettings? initial])
      : _settings = initial ?? ElectionReminderSettings.defaults();

  ElectionReminderSettings _settings;

  @override
  Future<ElectionReminderSettings> load() async => _settings;

  @override
  Future<void> save(ElectionReminderSettings s) async => _settings = s;
}

/// 常に defaults を返し save は何もしないリポジトリ。
/// UI テストの既定として使用できる。
class NoopElectionReminderRepository implements ElectionReminderRepository {
  const NoopElectionReminderRepository();

  @override
  Future<ElectionReminderSettings> load() async =>
      ElectionReminderSettings.defaults();

  @override
  Future<void> save(ElectionReminderSettings s) async {}
}
