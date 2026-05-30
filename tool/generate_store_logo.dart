import 'dart:io';

import 'package:image/image.dart' as img;

img.ColorRgb8 rgb(int r, int g, int b) => img.ColorRgb8(r, g, b);
img.ColorRgba8 rgba(int r, int g, int b, int a) => img.ColorRgba8(r, g, b, a);

void roundedRect(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  img.Color color,
  int radius,
) {
  img.fillRect(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    color: color,
    radius: radius,
  );
}

void drawLogo(img.Image image) {
  final cream = rgb(248, 245, 239);
  final ivory = rgb(253, 251, 247);
  final green = rgb(31, 122, 92);
  final ink = rgb(48, 50, 58);
  final coral = rgb(255, 107, 95);

  img.fill(image, color: cream);
  roundedRect(image, 112, 112, 912, 912, green, 190);
  roundedRect(image, 172, 178, 852, 846, ivory, 154);

  // Camera body and lens.
  roundedRect(image, 250, 328, 774, 646, ink, 74);
  roundedRect(image, 328, 256, 516, 360, ink, 44);
  img.fillCircle(
    image,
    x: 512,
    y: 488,
    radius: 112,
    color: ivory,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: 512,
    y: 488,
    radius: 66,
    color: green,
    antialias: true,
  );
  img.fillCircle(
    image,
    x: 660,
    y: 396,
    radius: 28,
    color: ivory,
    antialias: true,
  );

  // Certification check mark.
  img.drawLine(
    image,
    x1: 360,
    y1: 666,
    x2: 432,
    y2: 736,
    color: ivory,
    thickness: 52,
    antialias: true,
  );
  img.drawLine(
    image,
    x1: 432,
    y1: 736,
    x2: 670,
    y2: 610,
    color: ivory,
    thickness: 52,
    antialias: true,
  );

  // Place pin.
  img.fillCircle(
    image,
    x: 714,
    y: 344,
    radius: 130,
    color: coral,
    antialias: true,
  );
  img.fillPolygon(
    image,
    vertices: [img.Point(610, 420), img.Point(818, 420), img.Point(714, 566)],
    color: coral,
  );
  img.fillCircle(
    image,
    x: 714,
    y: 344,
    radius: 48,
    color: ivory,
    antialias: true,
  );

  // Small stamp-bar lines.
  roundedRect(image, 304, 696, 720, 766, ivory, 35);
  roundedRect(image, 356, 720, 450, 742, ink, 11);
  roundedRect(image, 478, 720, 668, 742, ink, 11);
}

Future<void> writePng(String path, img.Image image) async {
  await File(path).writeAsBytes(img.encodePng(image, level: 6));
}

Future<void> main() async {
  final outDir = Directory('store_assets/logo');
  await outDir.create(recursive: true);

  final source = img.Image(width: 1024, height: 1024, numChannels: 4);
  drawLogo(source);

  await writePng(
    'store_assets/logo/play_store_icon_512.png',
    img.copyResize(
      source,
      width: 512,
      height: 512,
      interpolation: img.Interpolation.cubic,
    ),
  );
  await writePng('store_assets/logo/app_icon_1024.png', source);

  final androidSizes = <String, int>{
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (final entry in androidSizes.entries) {
    final resized = img.copyResize(
      source,
      width: entry.value,
      height: entry.value,
      interpolation: img.Interpolation.cubic,
    );
    await writePng(
      'android/app/src/main/res/${entry.key}/ic_launcher.png',
      resized,
    );
  }
}
