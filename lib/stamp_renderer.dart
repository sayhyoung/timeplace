import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

class StampItem {
  final List<String> lines;
  final Offset normalizedCenter; // 0..1 in image space (center anchor)
  final double fontScale;
  final String? fontFamily;
  final FontWeight fontWeight;
  final double letterSpacing;
  final double lineHeight;
  final double strokeRatio; // stroke width / fontSize, 0이면 외곽선 없음
  final Color textColor;
  final Color strokeColor;
  final double fontSizeScale;
  final List<double> lineScales;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double cornerRadius;
  final EdgeInsets padding;
  final Color? shadowColor;
  final Offset shadowOffset;
  final double shadowBlur;
  final Color? frameColor;
  final double frameInsetRatio;
  final double frameStrokeRatio;
  final String frameShape;
  final bool fullCanvasFrame;
  final EdgeInsets framePadding;

  const StampItem({
    required this.lines,
    required this.normalizedCenter,
    this.fontScale = 1.0,
    this.fontFamily,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = -0.2,
    this.lineHeight = 1.25,
    this.strokeRatio = 0.18,
    this.textColor = Colors.white,
    this.strokeColor = Colors.black,
    this.fontSizeScale = 1,
    this.lineScales = const [1],
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.cornerRadius = 0,
    this.padding = EdgeInsets.zero,
    this.shadowColor,
    this.shadowOffset = Offset.zero,
    this.shadowBlur = 0,
    this.frameColor,
    this.frameInsetRatio = 0,
    this.frameStrokeRatio = 0,
    this.frameShape = 'none',
    this.fullCanvasFrame = false,
    this.framePadding = EdgeInsets.zero,
  });
}

class StampRenderer {
  static Future<Uint8List> render({
    required Uint8List imageBytes,
    required List<StampItem> items,
  }) async {
    if (items.isEmpty) return imageBytes;

    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final srcImage = frame.image;

    final imgW = srcImage.width.toDouble();
    final imgH = srcImage.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));
    canvas.drawImage(srcImage, Offset.zero, Paint());

    for (final item in items) {
      if (item.fullCanvasFrame) {
        _drawFrame(canvas, item, imgW, imgH, null);
      }
    }

    for (final item in items) {
      if (item.lines.isEmpty) continue;
      _drawItem(canvas, item, imgW, imgH);
    }

    final picture = recorder.endRecording();
    final resultImage = await picture.toImage(srcImage.width, srcImage.height);
    final byteData = await resultImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  static void _drawItem(
    Canvas canvas,
    StampItem item,
    double imgW,
    double imgH,
  ) {
    // 세로 사진은 짧은 변 기준 비율을 키우고, 가로 사진은 줄여서
    // 화면을 가득 채우는 큰 폰트 스타일이 가로에서 과도해지지 않도록 한다.
    final shortSide = imgW.clamp(0, imgH);
    final isPortrait = imgH > imgW;
    final ratio = isPortrait ? 0.038 : 0.028;
    final maxSize = isPortrait ? 92.0 : 72.0;
    final initialFontSize =
        (shortSide * ratio).clamp(28.0, maxSize) *
        item.fontScale *
        item.fontSizeScale;
    final maxTextWidth = imgW * 0.84;
    final text = item.lines.join('\n');

    // 1차 padding 계산용으로 임시 폰트 크기 사용 → 실제 가용 폭 계산
    final probePadding =
        item.padding * (initialFontSize / 16.0) +
        ((!item.fullCanvasFrame && item.frameShape != 'none')
            ? item.framePadding * (initialFontSize / 16.0)
            : EdgeInsets.zero);
    final probeAvailable =
        maxTextWidth - probePadding.horizontal - probePadding.horizontal * 0;
    // 줄별 자연 폭을 측정해 가장 긴 줄이 가용 폭에 맞도록 축소.
    final fontSize = _autoFitFontSize(
      lines: item.lines,
      baseStyle: TextStyle(
        fontSize: initialFontSize,
        fontWeight: item.fontWeight,
        height: item.lineHeight,
        letterSpacing: item.letterSpacing,
        fontFamily: item.fontFamily,
      ),
      availableWidth: probeAvailable,
      minScale: 0.55,
    );

    final paddingScale = fontSize / 16.0;
    final padding = item.padding * paddingScale;
    final framePadding = (!item.fullCanvasFrame && item.frameShape != 'none')
        ? item.framePadding * paddingScale
        : EdgeInsets.zero;
    final availableTextWidth =
        maxTextWidth - padding.horizontal - framePadding.horizontal;

    final baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: item.fontWeight,
      height: item.lineHeight,
      letterSpacing: item.letterSpacing,
      fontFamily: item.fontFamily,
    );

    final fillPainter = TextPainter(
      text: _span(text, baseStyle, item, color: item.textColor),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: availableTextWidth);

    final TextPainter? shadowPainter = item.shadowColor == null
        ? null
        : (TextPainter(
            text: _span(text, baseStyle, item, color: item.shadowColor),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: availableTextWidth));

    final TextPainter? strokePainter = item.strokeRatio <= 0
        ? null
        : (TextPainter(
            text: _span(
              text,
              baseStyle,
              item,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * item.strokeRatio
                ..strokeJoin = StrokeJoin.round
                ..color = item.strokeColor,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
          )..layout(maxWidth: availableTextWidth));

    final w = fillPainter.width + padding.horizontal + framePadding.horizontal;
    final h = fillPainter.height + padding.vertical + framePadding.vertical;
    final cx = item.normalizedCenter.dx * imgW;
    final cy = item.normalizedCenter.dy * imgH;
    final maxOriginX = imgW >= w ? imgW - w : 0.0;
    final maxOriginY = imgH >= h ? imgH - h : 0.0;
    final origin = Offset(
      (cx - w / 2).clamp(0.0, maxOriginX),
      (cy - h / 2).clamp(0.0, maxOriginY),
    );
    final hasBox =
        item.backgroundColor != null ||
        item.borderColor != null ||
        padding != EdgeInsets.zero;
    final rect = origin & Size(w, h);
    if (hasBox) {
      final radius = Radius.circular(item.cornerRadius * paddingScale);
      final rrect = RRect.fromRectAndRadius(rect, radius);
      if (item.shadowColor != null && item.shadowBlur > 0) {
        canvas.drawShadow(
          Path()..addRRect(rrect),
          item.shadowColor!,
          item.shadowBlur * paddingScale,
          true,
        );
      }
      if (item.backgroundColor != null) {
        canvas.drawRRect(rrect, Paint()..color = item.backgroundColor!);
      }
      if (item.borderColor != null && item.borderWidth > 0) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = item.borderWidth * paddingScale
            ..color = item.borderColor!,
        );
      }
    }
    if (!item.fullCanvasFrame) {
      final frameRect = Rect.fromLTWH(
        origin.dx + padding.left,
        origin.dy + padding.top,
        w - padding.horizontal,
        h - padding.vertical,
      );
      _drawFrame(canvas, item, imgW, imgH, frameRect);
    }

    final textOrigin =
        origin +
        Offset(
          padding.left + framePadding.left,
          padding.top + framePadding.top,
        );
    if (!hasBox && shadowPainter != null && item.shadowBlur > 0) {
      shadowPainter.paint(
        canvas,
        textOrigin + (item.shadowOffset * paddingScale),
      );
    }
    strokePainter?.paint(canvas, textOrigin);
    fillPainter.paint(canvas, textOrigin);
  }

  static TextSpan _span(
    String text,
    TextStyle baseStyle,
    StampItem item, {
    Color? color,
    Paint? foreground,
  }) {
    final lines = text.split('\n');
    final children = <InlineSpan>[];
    for (var i = 0; i < lines.length; i += 1) {
      final scale = item.lineScales.length > i
          ? item.lineScales[i]
          : item.lineScales.last;
      children.add(
        TextSpan(
          text: i == lines.length - 1 ? lines[i] : '${lines[i]}\n',
          style: baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 16) * scale,
            color: foreground == null ? color : null,
            foreground: foreground,
          ),
        ),
      );
    }
    return TextSpan(children: children);
  }

  static void _drawFrame(
    Canvas canvas,
    StampItem item,
    double imgW,
    double imgH,
    Rect? localRect,
  ) {
    if (item.frameColor == null ||
        item.frameInsetRatio <= 0 ||
        item.frameStrokeRatio <= 0 ||
        item.frameShape == 'none') {
      return;
    }
    final short = imgW.clamp(0, imgH);
    final inset = short * item.frameInsetRatio;
    final strokeWidth = short * item.frameStrokeRatio;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = item.frameColor!;
    final rect =
        localRect ??
        Rect.fromLTWH(inset, inset, imgW - inset * 2, imgH - inset * 2);

    switch (item.frameShape) {
      case 'rectangle':
        canvas.drawRect(rect, paint);
      case 'circle':
        if (localRect == null) {
          canvas.drawCircle(Offset(imgW / 2, imgH / 2), short * 0.19, paint);
        } else {
          canvas.drawOval(localRect.deflate(strokeWidth), paint);
        }
      case 'horizontalRules':
        final base =
            localRect ??
            Rect.fromLTWH(
              inset,
              imgH / 2 - short * 0.08,
              imgW - inset * 2,
              short * 0.16,
            );
        final y1 = base.top + base.height * 0.34;
        final y2 = base.top + base.height * 0.66;
        if (localRect == null) {
          canvas.drawLine(Offset(base.left, y1), Offset(base.right, y1), paint);
          canvas.drawLine(Offset(base.left, y2), Offset(base.right, y2), paint);
        } else {
          canvas.drawLine(
            Offset(base.left, base.top + strokeWidth / 2),
            Offset(base.right, base.top + strokeWidth / 2),
            paint,
          );
          canvas.drawLine(
            Offset(base.left, base.bottom - strokeWidth / 2),
            Offset(base.right, base.bottom - strokeWidth / 2),
            paint,
          );
        }
      case 'notebook':
        final gap = short * 0.075;
        final startY = imgH / 2 - gap * 1.6;
        for (var i = 0; i < 5; i += 1) {
          final y = startY + gap * i;
          canvas.drawLine(Offset(0, y), Offset(imgW, y), paint);
        }
        canvas.drawLine(
          Offset(short * 0.12, startY - gap * 0.55),
          Offset(short * 0.12, startY + gap * 4.2),
          paint,
        );
      case 'bottomBar':
        final barHeight = item.fullCanvasFrame
            ? short * item.frameStrokeRatio
            : (localRect?.height ?? short * item.frameStrokeRatio);
        final top = item.fullCanvasFrame
            ? imgH - barHeight - inset
            : (localRect?.top ?? imgH - barHeight - inset);
        canvas.drawRect(
          Rect.fromLTWH(0, top, imgW, barHeight),
          Paint()..color = item.frameColor!,
        );
      case 'splitBoxes':
        final base = localRect;
        final box = base == null ? short * 0.16 : base.height * 0.58;
        final gap = base == null ? short * 0.025 : base.width * 0.04;
        final top = base == null
            ? imgH / 2 - box / 2
            : base.top + strokeWidth / 2;
        final left = base == null
            ? imgW / 2 - box - gap / 2
            : base.center.dx - box - gap / 2;
        canvas.drawRect(Rect.fromLTWH(left, top, box, box), paint);
        canvas.drawRect(Rect.fromLTWH(left + box + gap, top, box, box), paint);
      case 'calendar':
        final base = localRect;
        final w = base == null ? short * 0.22 : base.width * 1.1;
        final h = base == null ? short * 0.18 : base.height * 1.12;
        final left = base == null ? imgW / 2 - w / 2 : base.center.dx - w / 2;
        final top = base == null ? imgH / 2 - h / 2 : base.center.dy - h / 2;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(left, top, w, h),
            Radius.circular(short * 0.01),
          ),
          paint,
        );
        canvas.drawLine(
          Offset(left, top + h * 0.36),
          Offset(left + w, top + h * 0.36),
          paint,
        );
      default:
        canvas.drawRect(rect, paint);
    }
  }

  /// 줄별 자연 폭을 측정해, 가장 긴 줄이 [availableWidth]를 넘지 않도록
  /// fontSize를 비례 축소한 값을 반환한다. minScale 이하로는 줄지 않는다.
  static double _autoFitFontSize({
    required List<String> lines,
    required TextStyle baseStyle,
    required double availableWidth,
    double minScale = 0.55,
  }) {
    final original = baseStyle.fontSize ?? 16;
    if (availableWidth <= 0) return original;
    double widest = 0;
    for (final line in lines) {
      if (line.isEmpty) continue;
      final tp = TextPainter(
        text: TextSpan(text: line, style: baseStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
    }
    if (widest <= 0 || widest <= availableWidth) return original;
    final ratio = availableWidth / widest;
    return original * ratio.clamp(minScale, 1.0);
  }
}
