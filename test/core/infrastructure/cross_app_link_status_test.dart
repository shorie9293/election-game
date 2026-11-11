import 'package:election_game/core/infrastructure/cross_app_link_status.dart';
import 'package:flutter_test/flutter_test.dart';

/// 純粋な状態型・表示文言の試練（Flutter 非依存・保存先も触らない）。
///
/// 壊れた保存値で**例外を投げない**ことが連携機能の生命線なので、
/// 破損系を厚く置く。
void main() {
  CrossAppTransferRecord sentRecord({
    DateTime? at,
    bool ok = true,
    int count = 3,
    String? fileName = 'election_reward_events.jsonl',
    String? error,
  }) =>
      CrossAppTransferRecord(
        at: at ?? DateTime(2026, 11, 11, 9, 12),
        ok: ok,
        count: count,
        fileName: fileName,
        error: error,
      );

  group('CrossAppTransferRecord', () {
    test('toJson → tryFromJson で往復する（fileName/error あり）', () {
      final record = sentRecord(ok: false, count: 0, error: 'boom');

      final restored = CrossAppTransferRecord.tryFromJson(record.toJson());

      expect(restored, isNotNull);
      expect(restored!.at, record.at);
      expect(restored.ok, isFalse);
      expect(restored.count, 0);
      expect(restored.fileName, 'election_reward_events.jsonl');
      expect(restored.error, 'boom');
    });

    test('fileName/error が null なら JSON にキーを出さない', () {
      final json = sentRecord(fileName: null, error: null).toJson();

      expect(json.containsKey('file'), isFalse);
      expect(json.containsKey('error'), isFalse);
      expect(CrossAppTransferRecord.tryFromJson(json)!.fileName, isNull);
    });

    test('tryFromJson は Map 以外・at 欠落・at 不正で null を返す', () {
      expect(CrossAppTransferRecord.tryFromJson(null), isNull);
      expect(CrossAppTransferRecord.tryFromJson('文字列'), isNull);
      expect(CrossAppTransferRecord.tryFromJson(<Object?>[]), isNull);
      expect(CrossAppTransferRecord.tryFromJson(<String, Object?>{}), isNull);
      expect(
        CrossAppTransferRecord.tryFromJson(<String, Object?>{'at': 1}),
        isNull,
      );
      expect(
        CrossAppTransferRecord.tryFromJson(<String, Object?>{'at': 'ちがう'}),
        isNull,
      );
    });

    test('tryFromJson は型違いの ok/count/file/error を既定値へ落とす', () {
      final restored = CrossAppTransferRecord.tryFromJson(<String, Object?>{
        'at': '2026-11-11T09:12:00.000',
        'ok': 'true', // bool でない → false
        'count': 2.0, // num → toInt
        'file': 42, // String でない → null
        'error': '', // 空 → null
      });

      expect(restored, isNotNull);
      expect(restored!.ok, isFalse);
      expect(restored.count, 2);
      expect(restored.fileName, isNull);
      expect(restored.error, isNull);
    });

    test('tryFromJson は count の欠落・非数値を 0 にする', () {
      final missing = CrossAppTransferRecord.tryFromJson(<String, Object?>{
        'at': '2026-11-11T09:12:00.000',
      });
      final broken = CrossAppTransferRecord.tryFromJson(<String, Object?>{
        'at': '2026-11-11T09:12:00.000',
        'count': '3',
      });

      expect(missing!.count, 0);
      expect(broken!.count, 0);
    });
  });

  group('CrossAppLinkSnapshot', () {
    test('encode → decode で送信・受信・フォルダ状態が往復する', () {
      final snapshot = CrossAppLinkSnapshot(
        lastSent: sentRecord(),
        lastReceived: sentRecord(
          ok: false,
          count: 0,
          fileName: 'tsundoku_reward_events.jsonl',
          error: 'permission denied',
        ),
        sharedFolderReady: true,
      );

      final decoded = CrossAppLinkSnapshot.decode(snapshot.encode());

      expect(decoded.sharedFolderReady, isTrue);
      expect(decoded.lastSent, isNotNull);
      expect(decoded.lastSent!.count, 3);
      expect(decoded.lastSent!.ok, isTrue);
      expect(decoded.lastSent!.at, DateTime(2026, 11, 11, 9, 12));
      expect(decoded.lastReceived, isNotNull);
      expect(decoded.lastReceived!.ok, isFalse);
      expect(decoded.lastReceived!.error, 'permission denied');
      expect(
        decoded.lastReceived!.fileName,
        'tsundoku_reward_events.jsonl',
      );
    });

    test('空スナップショットも往復する', () {
      final decoded = CrossAppLinkSnapshot.decode(
        CrossAppLinkSnapshot.empty.encode(),
      );

      expect(decoded.lastSent, isNull);
      expect(decoded.lastReceived, isNull);
      expect(decoded.sharedFolderReady, isFalse);
    });

    test('null・空文字・空白のみは empty を返す', () {
      expect(CrossAppLinkSnapshot.decode(null).lastSent, isNull);
      expect(CrossAppLinkSnapshot.decode('').lastSent, isNull);
      expect(CrossAppLinkSnapshot.decode('   ').sharedFolderReady, isFalse);
    });

    test('破損 JSON・型違いでも throw せず empty を返す', () {
      final broken = <String>[
        '{',
        '壊れた',
        '[]',
        '5',
        '"text"',
        '{"lastSent": 5}',
        '{"lastSent": []}',
        '{"sharedFolderReady": "yes"}',
      ];

      for (final raw in broken) {
        late CrossAppLinkSnapshot decoded;
        expect(
          () => decoded = CrossAppLinkSnapshot.decode(raw),
          returnsNormally,
          reason: raw,
        );
        expect(decoded.lastSent, isNull, reason: raw);
        expect(decoded.lastReceived, isNull, reason: raw);
      }
    });

    test('sharedFolderReady だけが真偽値以外なら false に落ちる', () {
      final decoded = CrossAppLinkSnapshot.decode(
        '{"sharedFolderReady": "true"}',
      );

      expect(decoded.sharedFolderReady, isFalse);
      expect(
          CrossAppLinkSnapshot.decode('{"sharedFolderReady": true}')
              .sharedFolderReady,
          isTrue);
    });

    test('copyWith は指定した項目だけ差し替える', () {
      final base = CrossAppLinkSnapshot(
        lastSent: sentRecord(),
        sharedFolderReady: true,
      );

      final updated = base.copyWith(
        lastReceived: sentRecord(count: 7, fileName: null),
      );

      expect(updated.lastSent!.count, 3);
      expect(updated.lastReceived!.count, 7);
      expect(updated.sharedFolderReady, isTrue);
    });
  });

  group('CrossAppLinkStatusText', () {
    test('time は 0 詰めの yyyy/MM/dd HH:mm、null は未記録', () {
      expect(
        CrossAppLinkStatusText.time(DateTime(2026, 11, 11, 9, 12)),
        '2026/11/11 09:12',
      );
      expect(
        CrossAppLinkStatusText.time(DateTime(2026, 1, 2, 3, 4)),
        '2026/01/02 03:04',
      );
      expect(CrossAppLinkStatusText.time(null), '未記録');
    });

    test('outcome は 成功／失敗／未記録', () {
      expect(CrossAppLinkStatusText.outcome(null), '未記録');
      expect(CrossAppLinkStatusText.outcome(sentRecord()), '成功');
      expect(CrossAppLinkStatusText.outcome(sentRecord(ok: false)), '失敗');
    });

    test('row は 成否・時刻・件数・ファイル名を中黒で連結する', () {
      expect(
        CrossAppLinkStatusText.row(sentRecord()),
        '成功・2026/11/11 09:12・3件・election_reward_events.jsonl',
      );
      expect(CrossAppLinkStatusText.row(null), '未記録');
    });

    test('row はファイル名が無ければ3要素に留める', () {
      expect(
        CrossAppLinkStatusText.row(sentRecord(fileName: null)),
        '成功・2026/11/11 09:12・3件',
      );
      expect(
        CrossAppLinkStatusText.row(sentRecord(fileName: '')),
        '成功・2026/11/11 09:12・3件',
      );
    });

    test('folder は 設定済み／未設定', () {
      expect(CrossAppLinkStatusText.folder(true), '設定済み');
      expect(CrossAppLinkStatusText.folder(false), '未設定（連携は停止中）');
    });

    test('detail は失敗理由だけを返し、成功なら空', () {
      expect(CrossAppLinkStatusText.detail(null), '');
      expect(CrossAppLinkStatusText.detail(sentRecord()), '');
      expect(
        CrossAppLinkStatusText.detail(sentRecord(ok: false, error: '理由あり')),
        '理由あり',
      );
    });

    test('detail は 160 文字を超える理由を切り詰める', () {
      final long = 'あ' * 500;

      final detail = CrossAppLinkStatusText.detail(
        sentRecord(ok: false, error: long),
      );

      expect(detail.length, 161);
      expect(detail.endsWith('…'), isTrue);
      expect(detail.startsWith('あ' * 160), isTrue);
    });

    test('countLines は行数を数え、空は 0', () {
      expect(CrossAppLinkStatusText.countLines(null), 0);
      expect(CrossAppLinkStatusText.countLines(''), 0);
      expect(CrossAppLinkStatusText.countLines('  \n '), 0);
      expect(CrossAppLinkStatusText.countLines('{"a":1}'), 1);
      expect(CrossAppLinkStatusText.countLines('a\nb\nc\n'), 3);
      expect(CrossAppLinkStatusText.countLines('a\r\nb\r\n'), 2);
    });
  });
}
