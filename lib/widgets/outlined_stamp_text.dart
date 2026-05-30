import 'package:flutter/material.dart';
import '../stamp_style.dart';

class OutlinedStampText extends StatelessWidget {
  final String text;
  final double fontSize;
  final TextAlign textAlign;
  final StampStyle? style;
  final Color? stampColor;

  const OutlinedStampText({
    super.key,
    required this.text,
    required this.fontSize,
    this.textAlign = TextAlign.left,
    this.style,
    this.stampColor,
  });

  @override
  Widget build(BuildContext context) {
    final s = style ?? StampStyle.minimal;
    final effectiveTextColor = stampColor ?? s.textColor;
    final effectiveStrokeColor = stampColor == null
        ? s.strokeColor
        : _contrastStrokeFor(stampColor!);
    final hasBox =
        s.backgroundColor != null ||
        s.borderColor != null ||
        s.padding != EdgeInsets.zero;
    final framePadding = s.hasFrame && !s.fullCanvasFrame
        ? s.framePadding
        : EdgeInsets.zero;
    final base = s.baseStyle().copyWith(
      fontSize: fontSize * s.fontSizeScale,
      fontWeight: s.fontWeight,
      height: s.lineHeight,
      letterSpacing: s.letterSpacing,
    );
    final hasStroke = s.strokeRatio > 0;
    final textStack = Stack(
      children: [
        if (s.shadowColor != null && s.shadowBlur > 0)
          Transform.translate(
            offset: s.shadowOffset,
            child: Text.rich(
              _span(base, s, color: s.shadowColor),
              textAlign: textAlign,
              softWrap: false,
              overflow: TextOverflow.visible,
            ),
          ),
        if (hasStroke)
          Text.rich(
            _span(
              base,
              s,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth =
                    fontSize * s.fontSizeScale * (s.strokeRatio * 2.0)
                ..strokeJoin = StrokeJoin.round
                ..color = effectiveStrokeColor,
            ),
            textAlign: textAlign,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
        Text.rich(
          _span(base, s, color: effectiveTextColor),
          textAlign: textAlign,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ],
    );
    final content = framePadding == EdgeInsets.zero
        ? textStack
        : Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _LocalFramePainter(s, colorOverride: stampColor),
                ),
              ),
              Padding(padding: framePadding, child: textStack),
            ],
          );
    final result = !hasBox
        ? content
        : DecoratedBox(
            decoration: BoxDecoration(
              color: s.backgroundColor,
              borderRadius: BorderRadius.circular(s.cornerRadius),
              border: s.borderColor == null || s.borderWidth <= 0
                  ? null
                  : Border.all(
                      color: stampColor ?? s.borderColor!,
                      width: s.borderWidth,
                    ),
              boxShadow: s.shadowColor == null
                  ? null
                  : [
                      BoxShadow(
                        color: s.shadowColor!.withAlpha(90),
                        offset: s.shadowOffset,
                        blurRadius: s.shadowBlur,
                      ),
                    ],
            ),
            child: Padding(padding: s.padding, child: content),
          );

    // 부모 maxWidth보다 자연 폭이 크면 자동 축소 (줄바꿈 방지)
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: _fittedAlignment(textAlign),
      child: result,
    );
  }

  Alignment _fittedAlignment(TextAlign a) {
    switch (a) {
      case TextAlign.left:
      case TextAlign.start:
        return Alignment.centerLeft;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.center;
    }
  }

  TextSpan _span(
    TextStyle base,
    StampStyle style, {
    Color? color,
    Paint? foreground,
  }) {
    final lines = text.split('\n');
    final children = <InlineSpan>[];
    for (var i = 0; i < lines.length; i += 1) {
      final scale = style.lineScales.length > i
          ? style.lineScales[i]
          : style.lineScales.last;
      children.add(
        TextSpan(
          text: i == lines.length - 1 ? lines[i] : '${lines[i]}\n',
          style: _lineStyle(
            base,
            style,
            color: color,
            foreground: foreground,
            scale: scale,
          ),
        ),
      );
    }
    return TextSpan(children: children);
  }

  TextStyle _lineStyle(
    TextStyle base,
    StampStyle style, {
    Color? color,
    Paint? foreground,
    double scale = 1,
  }) {
    return base.copyWith(
      fontSize: (base.fontSize ?? fontSize) * scale,
      color: foreground == null ? color : null,
      foreground: foreground,
      shadows: color == style.shadowColor && style.shadowColor != null
          ? [Shadow(color: style.shadowColor!, blurRadius: style.shadowBlur)]
          : null,
    );
  }
}

class _LocalFramePainter extends CustomPainter {
  final StampStyle style;
  final Color? colorOverride;
  const _LocalFramePainter(this.style, {this.colorOverride});

  @override
  void paint(Canvas canvas, Size size) {
    final color = colorOverride ?? style.frameColor;
    if (color == null) return;
    final short = size.shortestSide;
    final strokeWidth = (short * 0.018).clamp(1.0, 3.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = color;
    final rect = Offset.zero & size;
    switch (style.frameShape) {
      case StampFrameShape.rectangle:
        canvas.drawRect(rect.deflate(strokeWidth), paint);
      case StampFrameShape.circle:
        final frame = rect.deflate(strokeWidth);
        canvas.drawOval(frame, paint);
      case StampFrameShape.horizontalRules:
        final y1 = strokeWidth;
        final y2 = size.height - strokeWidth;
        canvas.drawLine(Offset(0, y1), Offset(size.width, y1), paint);
        canvas.drawLine(Offset(0, y2), Offset(size.width, y2), paint);
      case StampFrameShape.splitBoxes:
        final box = size.height * 0.58;
        final gap = size.width * 0.04;
        final left = size.width / 2 - box - gap / 2;
        final top = strokeWidth;
        canvas.drawRect(Rect.fromLTWH(left, top, box, box), paint);
        canvas.drawRect(Rect.fromLTWH(left + box + gap, top, box, box), paint);
      case StampFrameShape.calendar:
        final frame = rect.deflate(strokeWidth);
        canvas.drawRRect(
          RRect.fromRectAndRadius(frame, Radius.circular(short * 0.08)),
          paint,
        );
        canvas.drawLine(
          Offset(frame.left, frame.top + frame.height * 0.36),
          Offset(frame.right, frame.top + frame.height * 0.36),
          paint,
        );
      case StampFrameShape.none:
      case StampFrameShape.notebook:
      case StampFrameShape.bottomBar:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _LocalFramePainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.colorOverride != colorOverride;
  }
}

Color _contrastStrokeFor(Color color) {
  return color.computeLuminance() > 0.55
      ? const Color(0xAA000000)
      : const Color(0xCCFFFFFF);
}
