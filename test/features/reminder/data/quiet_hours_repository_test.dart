import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:election_game/features/reminder/data/quiet_hours_repository.dart';
import 'package:election_game/features/reminder/domain/quiet_hours.dart';
import 'package:election_game/features/reminder/domain/quiet_hours_settings.dart';

void main() {
  group('InMemoryQuietHoursRepository', () {
    test('save → load で往復し、呼び出し回数を観測できる', () async {
      final repo = InMemoryQuietHoursRepository();
      expect(await repo.load(), QuietHoursSettings.defaults());
      expect(repo.loadCount, 1);

      final s = QuietHoursSettings(
        enabled: true,
        startHour: 20,
        startMinute: 30,
        endHour: 6,
        endMinute: 15,
        policy: QuietHoursPolicy.skip,
      );
      await repo.save(s);
      expect(await repo.load(), s);
      expect(repo.saveCount, 1);
      expect(repo.current, s);
    });
  });

  group('NoopQuietHoursRepository', () {
    test('load は常に既定値、save は捨てる', () async {
      final repo = const NoopQuietHoursRepository();
      await repo.save(QuietHoursSettings(enabled: true));
      expect(await repo.load(), QuietHoursSettings.defaults());
    });
  });

  group('HiveQuietHoursRepository', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('quiet_hours_hive');
      Hive.init(tempDir.path);
    });

    tearDown(() async {
      try {
        await Hive.deleteBoxFromDisk(HiveQuietHoursRepository.boxName);
      } catch (_) {}
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    test('save → load で JSON 往復（別インスタンスでも読める）', () async {
      final s = QuietHoursSettings(
        enabled: true,
        startHour: 23,
        startMinute: 10,
        endHour: 6,
        endMinute: 50,
        policy: QuietHoursPolicy.skip,
      );
      await HiveQuietHoursRepository().save(s);
      final restored = await HiveQuietHoursRepository().load();
      expect(restored, s);
    });

    test('未保存（box 空）は既定値', () async {
      expect(await HiveQuietHoursRepository().load(),
          QuietHoursSettings.defaults());
    });

    test('破損 JSON は既定値へフォールバックする', () async {
      final box = await Hive.openBox<String>(HiveQuietHoursRepository.boxName);
      await box.put(HiveQuietHoursRepository.keyName, '{{{broken');
      final loaded = await HiveQuietHoursRepository().load();
      expect(loaded, QuietHoursSettings.defaults());
    });

    test('型不一致（JSON オブジェクトでない）も既定値', () async {
      final box = await Hive.openBox<String>(HiveQuietHoursRepository.boxName);
      await box.put(
        HiveQuietHoursRepository.keyName,
        jsonEncode(<String>['not', 'a', 'map']),
      );
      expect(await HiveQuietHoursRepository().load(),
          QuietHoursSettings.defaults());
    });

    test('openIfMissing=false で box 未 open なら既定値（通知経路の安全側）',
        () async {
      final repo = HiveQuietHoursRepository(openIfMissing: false);
      expect(await repo.load(), QuietHoursSettings.defaults());
    });

    test('保存した設定は openIfMissing=false の読み手にも見える', () async {
      await HiveQuietHoursRepository()
          .save(QuietHoursSettings(enabled: true, startHour: 22));
      final loaded = await HiveQuietHoursRepository(openIfMissing: false).load();
      expect(loaded.enabled, isTrue);
      expect(loaded.startHour, 22);
    });
  });
}
