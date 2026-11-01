import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'package:election_game/features/backup/domain/election_csv_service.dart';

/// 選挙結果CSVの共有口（試練で差し替え可能）。
abstract interface class ElectionCsvSharer {
  Future<void> share({required String csv, required String fileName});
}

/// share_plus でCSVを共有する実装。BOM付与はここで1回だけ行う。
class SharePlusElectionCsvSharer implements ElectionCsvSharer {
  const SharePlusElectionCsvSharer();

  @override
  Future<void> share({required String csv, required String fileName}) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(csvBytes(csv)),
            name: fileName,
            mimeType: 'text/csv',
          ),
        ],
        text: fileName,
      ),
    );
  }
}
