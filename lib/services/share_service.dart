import 'package:flutter/services.dart';

class ShareService {
  static const _channel = MethodChannel('timeplace/share');

  static Future<void> shareImage(String path, {String? text}) async {
    await _channel.invokeMethod<void>('shareImage', {
      'path': path,
      'text': text ?? '인증샷 카메라',
    });
  }
}
