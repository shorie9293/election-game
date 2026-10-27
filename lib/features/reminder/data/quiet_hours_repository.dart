import 'dart:convert';

import 'package:hive/hive.dart';

import 'package:election_game/features/reminder/domain/quiet_hours_service.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';

/// 静穏時間（おやすみモード）設定の永続化インターフェース。
abstract class QuietHoursRepository {
  Future<QuietHoursSettings> load();
  Future<void> save(QuietHoursSettings settings);
}

/// Hive 実装。box `quiet_hours_box` / key `quietHours` に JSON 文字列で保存。
///
/// [Hive.init] は呼ばない（呼び出し側が初期化済みである前提）。
/// 破損・型不一致レコードや open 失敗は
/// [QuietHoursSettings.defaults] へ静かにフォールバックする。
class HiveQuietHoursRepository implements QuietHoursRepository {
  HiveQuietHoursRepository({Box<String>? box, this.openIfMissing = true})
      : _injected = box;

  static const String boxName = 'quiet_hours_box';
  static const String keyName = 'quietHours';

  final Box<String>? _injected;

  /// false なら「既に open 済みの box を読むだけ」にし、無ければ既定値を返す。
  ///
  /// 通知経路の既定ガードはこれを false で使う。Hive 未初期化のまま
  /// `openBox` を呼ぶと未処理の非同期エラーになり得るため、
  /// box の open はアプリ起動時と保存時のみに限定する。
  final bool openIfMissing;

  Box<String>? _opened;

  Future<Box<String>?> _box() async {
    if (_injected != null) return _injected;
    if (_opened != null && _opened!.isOpen) return _opened;
    try {
      if (Hive.isBoxOpen(boxName)) {
        _opened = Hive.box<String>(boxName);
        return _opened;
      }
      if (!openIfMissing) return null;
      _opened = await Hive.openBox<String>(boxName);
      return _opened;
    } catch (_) {
      // Hive 未初期化・path 未設定などは「静穏時間なし」に落とす。
      return null;
    }
  }

  @override
  Future<QuietHoursSettings> load() async {
    try {
      final box = await _box();
      if (box == null) return QuietHoursSettings.defaults();
      final raw = box.get(keyName);
      if (raw is! String) return QuietHoursSettings.defaults();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return QuietHoursSettings.defaults();
      }
      return QuietHoursSettings.fromJson(decoded);
    } catch (_) {
      return QuietHoursSettings.defaults();
    }
  }

  @override
  Future<void> save(QuietHoursSettings settings) async {
    final box = await _box();
    if (box == null) return;
    try {
      await box.put(keyName, jsonEncode(settings.toJson()));
    } catch (_) {
      // 保存失敗で設定画面を壊さない。
    }
  }
}

/// 試練用のメモリ内リポジトリ。初期値を注入でき、呼び出しを観測できる。
class InMemoryQuietHoursRepository implements QuietHoursRepository {
  InMemoryQuietHoursRepository([QuietHoursSettings? initial])
      : _settings = initial ?? QuietHoursSettings.defaults();

  QuietHoursSettings _settings;

  int loadCount = 0;
  int saveCount = 0;

  QuietHoursSettings get current => _settings;

  @override
  Future<QuietHoursSettings> load() async {
    loadCount++;
    return _settings;
  }

  @override
  Future<void> save(QuietHoursSettings settings) async {
    saveCount++;
    _settings = settings;
  }
}

/// 常に既定値を返し保存は捨てるリポジトリ。
class NoopQuietHoursRepository implements QuietHoursRepository {
  const NoopQuietHoursRepository();

  @override
  Future<QuietHoursSettings> load() async => QuietHoursSettings.defaults();

  @override
  Future<void> save(QuietHoursSettings settings) async {}
}

/// リポジトリの設定を [QuietHoursGuard] として使う実装。
///
/// 通知送出のたびに [load] するため、設定画面で保存した内容が
/// 次の送出計画から反映される（保存しただけで効かない分裂を作らない）。
class QuietHoursRepositoryGuard implements QuietHoursGuard {
  QuietHoursRepositoryGuard(this._repository);

  final QuietHoursRepository _repository;

  @override
  Future<DateTime?> adjust(DateTime scheduled) async {
    final settings = await _repository.load();
    return QuietHoursService.resolveDelivery(settings, scheduled);
  }
}
