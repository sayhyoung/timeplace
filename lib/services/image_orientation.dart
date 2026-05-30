import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// EXIF orientation을 픽셀에 반영한 결과 bytes와 그 크기.
/// 크기를 함께 반환해 리뷰 화면에서 이미지를 한 번 더 디코드하지 않도록 한다.
class BakedImage {
  final Uint8List bytes;
  final int width;
  final int height;
  const BakedImage({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// JPEG bytes의 EXIF orientation을 실제 픽셀에 반영한 새 bytes를 반환한다.
/// 회전 정보가 EXIF에만 있고 픽셀에 적용되지 않으면 스탬프와 사진 방향이
/// 어긋나는 버그가 발생하므로, 캡처 직후 1회 정규화한다.
Uint8List bakeExifOrientation(Uint8List bytes) {
  return bakeExifOrientationWithSize(bytes).bytes;
}

/// [bakeExifOrientation]과 동일하지만 결과 픽셀 크기까지 반환한다.
/// `compute()`로 백그라운드 isolate에서 실행하기 위한 top-level 함수다.
/// 디코드/인코드는 큰 사진에서 수백 ms~수 초가 걸려 UI 스레드에서 돌리면
/// 촬영 직후 화면 전환이 크게 지연되므로 반드시 isolate에서 호출한다.
BakedImage bakeExifOrientationWithSize(Uint8List bytes) {
  try {
    final decoded = img.decodeJpg(bytes);
    if (decoded == null) {
      return BakedImage(bytes: bytes, width: 0, height: 0);
    }
    final baked = img.bakeOrientation(decoded);
    final encoded = Uint8List.fromList(img.encodeJpg(baked, quality: 92));
    return BakedImage(bytes: encoded, width: baked.width, height: baked.height);
  } catch (_) {
    return BakedImage(bytes: bytes, width: 0, height: 0);
  }
}
