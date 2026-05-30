import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

/// 촬영 직후 원본 bytes를 임시 폴더에 즉시 기록하고,
/// 갤러리 저장이 끝나면 삭제한다. 비정상 종료 시 다음 실행에서 잔여 파일을
/// 발견해 복구를 시도할 수 있게 한다.
class CaptureBackup {
  static const _dirName = 'pending_captures';

  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/$_dirName');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// bytes를 새 파일로 기록하고 그 경로를 반환.
  /// 이 경로를 review/save 흐름이 끝날 때까지 들고 있다가 [discard]로 정리한다.
  static Future<String> stash(Uint8List bytes) async {
    final dir = await _dir();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final path = '${dir.path}/$ts.jpg';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return path;
  }

  static Future<void> discard(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// 앱 시작 시 호출해 잔여 파일들을 가져온다.
  /// 반환된 파일들은 사용자에게 복구 의사를 묻고 처리한다.
  static Future<List<File>> orphans() async {
    try {
      final dir = await _dir();
      final entries = await dir.list().toList();
      final files = entries.whereType<File>().toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      return files;
    } catch (_) {
      return [];
    }
  }
}
