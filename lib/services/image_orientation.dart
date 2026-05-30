import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// JPEG bytes의 EXIF orientation을 실제 픽셀에 반영한 새 bytes를 반환한다.
/// 회전 정보가 EXIF에만 있고 픽셀에 적용되지 않으면 스탬프와 사진 방향이
/// 어긋나는 버그가 발생하므로, 캡처 직후 1회 정규화한다.
Uint8List bakeExifOrientation(Uint8List bytes) {
  try {
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) return bytes;
    final baked = img.bakeOrientation(decoded);
    return Uint8List.fromList(img.encodeJpg(baked, quality: 95));
  } catch (_) {
    return bytes;
  }
}
