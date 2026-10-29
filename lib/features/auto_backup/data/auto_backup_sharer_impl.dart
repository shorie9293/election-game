import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:election_game/features/auto_backup/domain/auto_backup_sharer.dart';

/// 共有ファイルを渡す実処理（試練で差し替え可能）。
typedef AutoBackupShareAction = Future<void> Function(
  File file,
  String fileName,
);

/// 一時ファイルへ書き出して share_plus で共有する実装。
class TempFileAutoBackupSharer implements AutoBackupSharer {
  /// 書き出し先ディレクトリの解決器。
  final Future<Directory> Function() directoryResolver;

  /// 実際の共有処理（既定は share_plus）。
  final AutoBackupShareAction shareAction;

  TempFileAutoBackupSharer({
    Future<Directory> Function()? directoryResolver,
    AutoBackupShareAction? shareAction,
  })  : directoryResolver = directoryResolver ?? getTemporaryDirectory,
        shareAction = shareAction ?? _shareWithSharePlus;

  static Future<void> _shareWithSharePlus(File file, String fileName) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        text: 'バックアップ: $fileName',
      ),
    );
  }

  @override
  Future<void> share(String fileName, String json) async {
    final dir = await directoryResolver();
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');
    await file.writeAsString(json, flush: true);
    await shareAction(file, fileName);
  }
}
