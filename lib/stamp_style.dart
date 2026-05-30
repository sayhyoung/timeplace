import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum StampTextTemplate {
  standard,
  dietKorean,
  studyStack,
  morningProof,
  workoutFrame,
  koreanBigTime,
  englishTiny,
  lineDivider,
  boxedDate,
  splitBoxes,
  circleTime,
  notebook,
  bottomBar,
  calendarMini,
  digitalClock,
  timeMark,
}

enum StampFrameShape {
  none,
  rectangle,
  circle,
  horizontalRules,
  notebook,
  bottomBar,
  splitBoxes,
  calendar,
}

/// 정보 스탬프(시간/장소)에 적용되는 시각 프리셋.
/// 메모 스탬프는 별도의 손글씨 폰트로 항상 표시된다.
class StampStyle {
  final String id;
  final String displayName;

  /// google_fonts factory. null이면 시스템 기본.
  final TextStyle Function()? fontFactory;
  final FontWeight fontWeight;
  final Color textColor;
  final Color strokeColor;
  final double strokeRatio; // 0이면 외곽선 없음
  final StampTextTemplate template;
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
  final double letterSpacing;
  final double lineHeight;
  final Color? frameColor;
  final double frameInsetRatio;
  final double frameStrokeRatio;
  final StampFrameShape frameShape;
  final bool fullCanvasFrame;
  final EdgeInsets framePadding;

  const StampStyle({
    required this.id,
    required this.displayName,
    required this.fontFactory,
    required this.fontWeight,
    required this.textColor,
    required this.strokeColor,
    required this.strokeRatio,
    this.template = StampTextTemplate.standard,
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
    required this.letterSpacing,
    required this.lineHeight,
    this.frameColor,
    this.frameInsetRatio = 0,
    this.frameStrokeRatio = 0,
    this.frameShape = StampFrameShape.none,
    this.fullCanvasFrame = false,
    this.framePadding = EdgeInsets.zero,
  });

  bool get hasFrame =>
      frameColor != null &&
      frameInsetRatio > 0 &&
      frameStrokeRatio > 0 &&
      frameShape != StampFrameShape.none;

  TextStyle baseStyle() {
    final factory = fontFactory;
    return factory != null ? factory() : const TextStyle();
  }

  static StampStyle byId(String? id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static final StampStyle minimal = StampStyle(
    id: 'minimal',
    displayName: '기본',
    fontFactory: () => GoogleFonts.ibmPlexSansKr(),
    fontWeight: FontWeight.w800,
    textColor: Colors.white,
    strokeColor: Colors.black,
    strokeRatio: 0.13,
    shadowColor: const Color(0x99000000),
    shadowOffset: const Offset(0, 1.5),
    shadowBlur: 4,
    letterSpacing: 0,
    lineHeight: 1.25,
  );

  static final StampStyle dietPoster = StampStyle(
    id: 'diet_poster',
    displayName: '큰 한글',
    fontFactory: () => GoogleFonts.gowunDodum(),
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.dietKorean,
    fontSizeScale: 4.15,
    lineScales: const [1.0, 0.38, 0.30],
    shadowColor: const Color(0x66000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 8,
    letterSpacing: 0,
    lineHeight: 1.15,
  );

  static final StampStyle studyPoster = StampStyle(
    id: 'study_poster',
    displayName: '세로 영문',
    fontFactory: () => GoogleFonts.amaticSc(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.studyStack,
    fontSizeScale: 3.2,
    lineScales: const [0.72, 1.0, 0.88, 0.28],
    shadowColor: const Color(0x55000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 4,
    letterSpacing: 1.4,
    lineHeight: 1.12,
  );

  static final StampStyle morningProof = StampStyle(
    id: 'morning_proof',
    displayName: '한 줄',
    fontFactory: () => GoogleFonts.robotoSlab(),
    fontWeight: FontWeight.w800,
    textColor: Colors.white,
    strokeColor: const Color(0x22000000),
    strokeRatio: 0.03,
    template: StampTextTemplate.morningProof,
    fontSizeScale: 1.65,
    lineScales: const [1, 0.42],
    shadowColor: const Color(0x55000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 3,
    letterSpacing: 0.8,
    lineHeight: 1.08,
  );

  static final StampStyle workoutPoster = StampStyle(
    id: 'workout_poster',
    displayName: '큰 프레임',
    fontFactory: () => GoogleFonts.blackHanSans(),
    fontWeight: FontWeight.w900,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.04,
    template: StampTextTemplate.workoutFrame,
    fontSizeScale: 3.05,
    lineScales: const [0.62, 1.0, 0.52, 0.34],
    shadowColor: const Color(0x66000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 5,
    letterSpacing: 0,
    lineHeight: 1.03,
    frameColor: Colors.white,
    frameInsetRatio: 0.085,
    frameStrokeRatio: 0.005,
    frameShape: StampFrameShape.rectangle,
    fullCanvasFrame: true,
  );

  static final StampStyle tinyCorner = StampStyle(
    id: 'tiny_corner',
    displayName: '작은 코너',
    fontFactory: () => GoogleFonts.ibmPlexSansKr(),
    fontWeight: FontWeight.w800,
    textColor: Colors.white,
    strokeColor: const Color(0x66000000),
    strokeRatio: 0.04,
    template: StampTextTemplate.koreanBigTime,
    fontSizeScale: 1.0,
    lineScales: const [0.9, 0.82, 0.68],
    shadowColor: const Color(0x99000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 2,
    letterSpacing: 0,
    lineHeight: 1.15,
  );

  static final StampStyle englishTop = StampStyle(
    id: 'english_top',
    displayName: '얇은 영문',
    fontFactory: () => GoogleFonts.amaticSc(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.englishTiny,
    fontSizeScale: 1.6,
    lineScales: const [0.74, 1.0, 0.9, 0.34],
    shadowColor: const Color(0x55000000),
    shadowOffset: const Offset(0, 1.5),
    shadowBlur: 3,
    letterSpacing: 1.0,
    lineHeight: 1.1,
  );

  static final StampStyle ruledClassic = StampStyle(
    id: 'ruled_classic',
    displayName: '라인',
    fontFactory: () => GoogleFonts.robotoSlab(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.lineDivider,
    fontSizeScale: 1.25,
    lineScales: const [0.54, 0.64, 0.54, 0.28],
    shadowColor: const Color(0x66000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 3,
    letterSpacing: 3.0,
    lineHeight: 1.55,
    frameColor: Colors.white,
    frameInsetRatio: 0.04,
    frameStrokeRatio: 0.003,
    frameShape: StampFrameShape.horizontalRules,
    framePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
  );

  static final StampStyle framedMinimal = StampStyle(
    id: 'framed_minimal',
    displayName: '사각 박스',
    fontFactory: () => GoogleFonts.bebasNeue(),
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.boxedDate,
    fontSizeScale: 1.18,
    lineScales: const [0.85, 0.9, 0.42],
    shadowColor: const Color(0x66000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 2,
    letterSpacing: 1.2,
    lineHeight: 1.25,
    frameColor: Colors.white,
    frameInsetRatio: 0.07,
    frameStrokeRatio: 0.005,
    frameShape: StampFrameShape.rectangle,
    framePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  );

  static final StampStyle circleTime = StampStyle(
    id: 'circle_time',
    displayName: '원형',
    fontFactory: () => GoogleFonts.majorMonoDisplay(),
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    strokeColor: const Color(0x22000000),
    strokeRatio: 0.01,
    template: StampTextTemplate.circleTime,
    fontSizeScale: 1.5,
    lineScales: const [1.0, 0.28, 0.22],
    shadowColor: const Color(0x44000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 2,
    letterSpacing: 0,
    lineHeight: 1.06,
    frameColor: Colors.white,
    frameInsetRatio: 0.06,
    frameStrokeRatio: 0.004,
    frameShape: StampFrameShape.circle,
    framePadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
  );

  static final StampStyle notebookLines = StampStyle(
    id: 'notebook_lines',
    displayName: '노트',
    fontFactory: () => GoogleFonts.gowunDodum(),
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    strokeColor: const Color(0x22000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.notebook,
    fontSizeScale: 1.72,
    lineScales: const [1.0, 0.44, 0.34],
    shadowColor: const Color(0x44000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 3,
    letterSpacing: 0,
    lineHeight: 1.18,
    frameColor: Colors.white,
    frameInsetRatio: 0.06,
    frameStrokeRatio: 0.002,
    frameShape: StampFrameShape.notebook,
    fullCanvasFrame: true,
  );

  static final StampStyle bottomBand = StampStyle(
    id: 'bottom_band',
    displayName: '하단 띠',
    fontFactory: () => GoogleFonts.spaceMono(),
    fontWeight: FontWeight.w700,
    textColor: const Color(0xFF111111),
    strokeColor: Colors.transparent,
    strokeRatio: 0,
    template: StampTextTemplate.bottomBar,
    fontSizeScale: 0.9,
    lineScales: const [1, 0.75],
    letterSpacing: 0.6,
    lineHeight: 1.15,
    backgroundColor: Colors.white,
    cornerRadius: 0,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );

  static final StampStyle calendarMini = StampStyle(
    id: 'calendar_mini',
    displayName: '달력',
    fontFactory: () => GoogleFonts.sourceCodePro(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x22000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.calendarMini,
    fontSizeScale: 0.88,
    lineScales: const [0.82, 0.82, 0.56, 0.34],
    shadowColor: const Color(0x55000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 2,
    letterSpacing: 0,
    lineHeight: 1.18,
    frameColor: Colors.white,
    frameInsetRatio: 0.37,
    frameStrokeRatio: 0.003,
    frameShape: StampFrameShape.calendar,
    framePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  static final StampStyle digitalLarge = StampStyle(
    id: 'digital_large',
    displayName: '디지털',
    fontFactory: () => GoogleFonts.orbitron(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x33000000),
    strokeRatio: 0.02,
    template: StampTextTemplate.digitalClock,
    fontSizeScale: 2.35,
    lineScales: const [1.0, 0.24, 0.22],
    shadowColor: const Color(0x66000000),
    shadowOffset: const Offset(0, 1),
    shadowBlur: 3,
    letterSpacing: 1.2,
    lineHeight: 1.05,
  );

  static final StampStyle compact = StampStyle(
    id: 'compact',
    displayName: '캡슐',
    fontFactory: () => GoogleFonts.ibmPlexSansKr(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0xCC000000),
    strokeRatio: 0.08,
    fontSizeScale: 1.08,
    backgroundColor: const Color(0x8A000000),
    cornerRadius: 8,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    letterSpacing: 0,
    lineHeight: 1.22,
  );

  static final StampStyle bold = StampStyle(
    id: 'bold',
    displayName: '굵은 글자',
    fontFactory: () => GoogleFonts.jua(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: Colors.black,
    strokeRatio: 0.20,
    shadowColor: const Color(0xA6000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 2,
    letterSpacing: 0,
    lineHeight: 1.18,
  );

  static final StampStyle label = StampStyle(
    id: 'label',
    displayName: '흰 라벨',
    fontFactory: () => GoogleFonts.ibmPlexSansKr(),
    fontWeight: FontWeight.w800,
    textColor: const Color(0xFF111111),
    strokeColor: Colors.transparent,
    strokeRatio: 0,
    fontSizeScale: 1.08,
    backgroundColor: const Color(0xEFFFFFFF),
    borderColor: const Color(0x33000000),
    borderWidth: 1,
    cornerRadius: 7,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    shadowColor: const Color(0x55000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 8,
    letterSpacing: 0,
    lineHeight: 1.22,
  );

  static final StampStyle film = StampStyle(
    id: 'film',
    displayName: '필름',
    fontFactory: () => GoogleFonts.dotGothic16(),
    fontWeight: FontWeight.w400,
    textColor: const Color(0xFFFFD60A), // 따뜻한 노랑
    strokeColor: const Color(0xFF1C1C1E),
    strokeRatio: 0.16,
    backgroundColor: const Color(0x8F000000),
    borderColor: const Color(0x55FFD60A),
    borderWidth: 1,
    cornerRadius: 4,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    letterSpacing: 0.4,
    lineHeight: 1.3,
  );

  static final StampStyle diary = StampStyle(
    id: 'diary',
    displayName: '다이어리',
    fontFactory: () => GoogleFonts.gowunDodum(),
    fontWeight: FontWeight.w700,
    textColor: const Color(0xFFFFF7EC),
    strokeColor: const Color(0xFF2A211B),
    strokeRatio: 0.10,
    fontSizeScale: 1.12,
    backgroundColor: const Color(0x662A211B),
    cornerRadius: 14,
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    letterSpacing: 0,
    lineHeight: 1.28,
  );

  static final StampStyle study = StampStyle(
    id: 'study',
    displayName: '블루 라벨',
    fontFactory: () => GoogleFonts.gowunBatang(),
    fontWeight: FontWeight.w700,
    textColor: const Color(0xFFF8FBFF),
    strokeColor: const Color(0xFF06234A),
    strokeRatio: 0.12,
    fontSizeScale: 1.1,
    backgroundColor: const Color(0xAA0A3A72),
    borderColor: const Color(0x668CC7FF),
    borderWidth: 1,
    cornerRadius: 6,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    letterSpacing: 0,
    lineHeight: 1.25,
  );

  static final StampStyle workout = StampStyle(
    id: 'workout',
    displayName: '그린 라벨',
    fontFactory: () => GoogleFonts.gugi(),
    fontWeight: FontWeight.w400,
    textColor: Colors.white,
    strokeColor: const Color(0xFF06140D),
    strokeRatio: 0.18,
    fontSizeScale: 1.08,
    backgroundColor: const Color(0xB0167A4A),
    borderColor: const Color(0x882EEA86),
    borderWidth: 1.2,
    cornerRadius: 18,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    letterSpacing: 0,
    lineHeight: 1.2,
  );

  static final StampStyle meal = StampStyle(
    id: 'meal',
    displayName: '오렌지 라벨',
    fontFactory: () => GoogleFonts.jua(),
    fontWeight: FontWeight.w400,
    textColor: const Color(0xFFFFFCF5),
    strokeColor: const Color(0xFF5A2116),
    strokeRatio: 0.14,
    fontSizeScale: 1.08,
    backgroundColor: const Color(0xB8D95836),
    cornerRadius: 16,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    letterSpacing: 0,
    lineHeight: 1.2,
  );

  static final StampStyle report = StampStyle(
    id: 'report',
    displayName: '증빙',
    fontFactory: () => GoogleFonts.ibmPlexSansKr(),
    fontWeight: FontWeight.w800,
    textColor: const Color(0xFFEAF7FF),
    strokeColor: const Color(0xFF061B24),
    strokeRatio: 0.10,
    fontSizeScale: 1.08,
    backgroundColor: const Color(0xB0061B24),
    borderColor: const Color(0x8037D5FF),
    borderWidth: 1,
    cornerRadius: 3,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    letterSpacing: 0,
    lineHeight: 1.18,
  );

  static final StampStyle elegant = StampStyle(
    id: 'elegant',
    displayName: '세리프',
    fontFactory: () => GoogleFonts.notoSerifKr(),
    fontWeight: FontWeight.w700,
    textColor: const Color(0xFFFFFAEF),
    strokeColor: const Color(0xFF25170C),
    strokeRatio: 0.13,
    fontSizeScale: 1.08,
    shadowColor: const Color(0x99000000),
    shadowOffset: const Offset(0, 2),
    shadowBlur: 5,
    letterSpacing: 0,
    lineHeight: 1.34,
  );

  static final StampStyle timeMark = StampStyle(
    id: 'timemark',
    displayName: '빅타임',
    fontFactory: () => GoogleFonts.robotoSlab(),
    fontWeight: FontWeight.w700,
    textColor: Colors.white,
    strokeColor: const Color(0x66000000),
    strokeRatio: 0.03,
    template: StampTextTemplate.timeMark,
    fontSizeScale: 1.0,
    // [0]=시각(큰글씨) [1]=날짜 [2]=연도 [3]=주소
    lineScales: const [1.0, 0.34, 0.30, 0.30],
    shadowColor: const Color(0x99000000),
    shadowOffset: const Offset(0, 1.5),
    shadowBlur: 6,
    letterSpacing: 0,
    lineHeight: 1.1,
  );

  static final List<StampStyle> all = [
    timeMark,
    dietPoster,
    studyPoster,
    morningProof,
    workoutPoster,
    tinyCorner,
    englishTop,
    ruledClassic,
    framedMinimal,
    circleTime,
    notebookLines,
    bottomBand,
    calendarMini,
    digitalLarge,
    minimal,
    compact,
    label,
    bold,
    film,
    diary,
    study,
    workout,
    meal,
    report,
    elegant,
  ];
}
