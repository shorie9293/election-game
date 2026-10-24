import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:election_game/features/crossapp/data/crossapp_link_code_repository.dart';

void main() {
  group('SharedPreferencesCrossAppLinkCodeRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('未保存なら null', () async {
      const repo = SharedPreferencesCrossAppLinkCodeRepository();
      expect(await repo.load(), isNull);
    });

    test('保存したコードを別インスタンスで復元できる', () async {
      const writer = SharedPreferencesCrossAppLinkCodeRepository();
      await writer.save('abcd1234-5678-90ab-cdef-1234567890ab');

      const reader = SharedPreferencesCrossAppLinkCodeRepository();
      expect(await reader.load(), 'abcd1234-5678-90ab-cdef-1234567890ab');
    });

    test('保存時に前後の空白を落とす', () async {
      const repo = SharedPreferencesCrossAppLinkCodeRepository();
      await repo.save('  abcd1234  ');
      expect(await repo.load(), 'abcd1234');
    });

    test('clear で解除される', () async {
      const repo = SharedPreferencesCrossAppLinkCodeRepository();
      await repo.save('abcd1234');
      await repo.clear();
      expect(await repo.load(), isNull);
    });

    test('保存キーは凍結契約の crossapp_link_code', () async {
      const repo = SharedPreferencesCrossAppLinkCodeRepository();
      await repo.save('abcd1234');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('crossapp_link_code'), 'abcd1234');
    });
  });

  group('InMemoryCrossAppLinkCodeRepository', () {
    test('保存・復元・解除ができる', () async {
      final repo = InMemoryCrossAppLinkCodeRepository();
      expect(await repo.load(), isNull);

      await repo.save('  abcd1234  ');
      expect(await repo.load(), 'abcd1234');

      await repo.clear();
      expect(await repo.load(), isNull);
    });

    test('初期値を注入できる', () async {
      final repo = InMemoryCrossAppLinkCodeRepository('abcd1234');
      expect(await repo.load(), 'abcd1234');
    });
  });

  group('resolveExportUserId', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('保存済みコードの先頭8文字を返す', () async {
      final repo = InMemoryCrossAppLinkCodeRepository(
        'abcd1234-5678-90ab-cdef-1234567890ab',
      );
      expect(await resolveExportUserId(repo), 'abcd1234');
    });

    test('未保存なら空文字（書き出し抑止）', () async {
      final repo = InMemoryCrossAppLinkCodeRepository();
      expect(await resolveExportUserId(repo), '');
    });

    test('読み込み失敗でも例外を投げず空文字を返す', () async {
      expect(await resolveExportUserId(_ThrowingLinkCodeRepository()), '');
    });
  });
}

/// load が必ず失敗するリポジトリ（best-effort の検証用）
class _ThrowingLinkCodeRepository implements CrossAppLinkCodeRepository {
  @override
  Future<String?> load() async => throw const _Boom();

  @override
  Future<void> save(String code) async {}

  @override
  Future<void> clear() async {}
}

class _Boom implements Exception {
  const _Boom();
}
