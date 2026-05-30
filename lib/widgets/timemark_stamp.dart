import 'package:flutter/material.dart';
import '../stamp_style.dart';

/// 타임마크 스타일 프리뷰 위젯.
/// 레이아웃: [큰 시각] | [날짜 / 연도] 한 행, 그 아래 [주소] 한 줄.
///
/// 정보 줄 구조(고정): lines[0]=시각, lines[1]=날짜, lines[2]=연도, lines[3]=주소(선택).
/// 캔버스 최종 렌더는 StampRenderer._drawTimeMark 가 동일한 레이아웃을 그린다.
class TimeMarkStamp extends StatelessWidget {
  final List<String> lines;
  final double fontSize;
  final StampStyle style;
  final Color? stampColor;

  const TimeMarkStamp({
    super.key,
    required this.lines,
    required this.fontSize,
    required this.style,
    this.stampColor,
  });

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) return const SizedBox.shrink();
    final time = lines[0];
    final dateLine = lines.length > 1 ? lines[1] : '';
    final yearLine = lines.length > 2 ? lines[2] : '';
    final location = lines.length > 3 ? lines[3] : null;

    final textColor = stampColor ?? style.textColor;
    final strokeColor = stampColor == null
        ? style.strokeColor
        : _contrastStrokeFor(stampColor!);

    final timeSize = fontSize * 2.45;
    final dateSize = fontSize * 0.82;
    final locSize = fontSize * 0.78;
    final dividerHeight = timeSize * 0.74;
    final fontFamily = style.baseStyle().fontFamily;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _outlined(
          time,
          fontSize: timeSize,
          weight: FontWeight.w800,
          color: textColor,
          stroke: strokeColor,
          fontFamily: fontFamily,
        ),
        SizedBox(width: fontSize * 0.5),
        Container(
          width: (fontSize * 0.14).clamp(1.5, 4.0),
          height: dividerHeight,
          color: textColor,
        ),
        SizedBox(width: fontSize * 0.5),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _outlined(
              dateLine,
              fontSize: dateSize,
              weight: FontWeight.w700,
              color: textColor,
              stroke: strokeColor,
              fontFamily: fontFamily,
            ),
            _outlined(
              yearLine,
              fontSize: dateSize,
              weight: FontWeight.w500,
              color: textColor,
              stroke: strokeColor,
              fontFamily: fontFamily,
            ),
          ],
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row,
        if (location != null && location.isNotEmpty) ...[
          SizedBox(height: fontSize * 0.35),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.82,
            ),
            child: _outlined(
              location,
              fontSize: locSize,
              weight: FontWeight.w500,
              color: textColor,
              stroke: strokeColor,
              fontFamily: fontFamily,
              softWrap: true,
            ),
          ),
        ],
      ],
    );
  }

  Widget _outlined(
    String text, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    required Color stroke,
    String? fontFamily,
    bool softWrap = false,
  }) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: weight,
      fontFamily: fontFamily,
      height: 1.05,
    );
    final shadow = style.shadowColor;
    return Stack(
      children: [
        if (shadow != null)
          Text(
            text,
            softWrap: softWrap,
            overflow: TextOverflow.visible,
            style: base.copyWith(
              color: shadow,
              shadows: [Shadow(color: shadow, blurRadius: style.shadowBlur)],
            ),
          ),
        Text(
          text,
          softWrap: softWrap,
          overflow: TextOverflow.visible,
          style: base.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fontSize * 0.06
              ..strokeJoin = StrokeJoin.round
              ..color = stroke,
          ),
        ),
        Text(
          text,
          softWrap: softWrap,
          overflow: TextOverflow.visible,
          style: base.copyWith(color: color),
        ),
      ],
    );
  }
}

Color _contrastStrokeFor(Color color) {
  return color.computeLuminance() > 0.55
      ? const Color(0xAA000000)
      : const Color(0xCCFFFFFF);
}
