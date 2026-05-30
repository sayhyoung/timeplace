import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'stamp_style.dart';

enum StampLanguage {
  auto,
  ko,
  en;

  String get title {
    switch (this) {
      case StampLanguage.auto:
        return '자동 (시스템)';
      case StampLanguage.ko:
        return '한국어';
      case StampLanguage.en:
        return 'English';
    }
  }

  String resolve(String systemLanguageCode) {
    switch (this) {
      case StampLanguage.auto:
        return systemLanguageCode == 'ko' ? 'ko' : 'en';
      case StampLanguage.ko:
        return 'ko';
      case StampLanguage.en:
        return 'en';
    }
  }
}

enum TimeStampMode {
  off,
  date,
  hour,
  minute,
  second,
  timeOnly;

  String get title {
    switch (this) {
      case TimeStampMode.off:
        return 'OFF';
      case TimeStampMode.date:
        return '날짜만';
      case TimeStampMode.hour:
        return '날짜 + 시';
      case TimeStampMode.minute:
        return '날짜 + 시:분';
      case TimeStampMode.second:
        return '날짜 + 시:분:초';
      case TimeStampMode.timeOnly:
        return '시간만';
    }
  }

  String? textFor(
    DateTime date, {
    required String locale,
    TimeHourFormat hourFormat = TimeHourFormat.h24,
  }) {
    if (this == TimeStampMode.off) return null;
    final isKo = locale == 'ko';
    final datePart = isKo
        ? DateFormat('yyyy.MM.dd', 'ko').format(date)
        : DateFormat.yMMMd('en').format(date);
    final minuteText = hourFormat.formatMinute(date, locale: locale);
    final secondText = hourFormat.formatSecond(date, locale: locale);
    final hourText = hourFormat.formatHour(date, locale: locale);
    const gap = '   '; // 3 spaces for visual breathing
    switch (this) {
      case TimeStampMode.off:
        return null;
      case TimeStampMode.date:
        return datePart;
      case TimeStampMode.hour:
        return '$datePart$gap$hourText';
      case TimeStampMode.minute:
        return '$datePart$gap$minuteText';
      case TimeStampMode.second:
        return '$datePart$gap$secondText';
      case TimeStampMode.timeOnly:
        return minuteText;
    }
  }
}

enum TimeHourFormat {
  h24,
  h12;

  String get title {
    switch (this) {
      case TimeHourFormat.h24:
        return '24시간';
      case TimeHourFormat.h12:
        return '12시간';
    }
  }

  String formatHour(DateTime date, {required String locale}) {
    switch (this) {
      case TimeHourFormat.h24:
        return locale == 'ko'
            ? '${DateFormat('HH').format(date)}시'
            : DateFormat('HH').format(date);
      case TimeHourFormat.h12:
        return locale == 'ko'
            ? DateFormat('a h시', 'ko').format(date)
            : DateFormat('h a', 'en').format(date);
    }
  }

  String formatMinute(DateTime date, {required String locale}) {
    switch (this) {
      case TimeHourFormat.h24:
        return DateFormat('HH:mm').format(date);
      case TimeHourFormat.h12:
        return locale == 'ko'
            ? DateFormat('a h:mm', 'ko').format(date)
            : DateFormat('h:mm a', 'en').format(date);
    }
  }

  String formatSecond(DateTime date, {required String locale}) {
    switch (this) {
      case TimeHourFormat.h24:
        return DateFormat('HH:mm:ss').format(date);
      case TimeHourFormat.h12:
        return locale == 'ko'
            ? DateFormat('a h:mm:ss', 'ko').format(date)
            : DateFormat('h:mm:ss a', 'en').format(date);
    }
  }
}

enum PlaceStampMode {
  off,
  city,
  district,
  neighborhood,
  full,
  gps;

  String get title {
    switch (this) {
      case PlaceStampMode.off:
        return 'OFF';
      case PlaceStampMode.city:
        return '도시만';
      case PlaceStampMode.district:
        return '구/군까지';
      case PlaceStampMode.neighborhood:
        return '동/읍/면까지';
      case PlaceStampMode.full:
        return '상세 주소';
      case PlaceStampMode.gps:
        return 'GPS 좌표';
    }
  }

  String? textFrom(AddressParts address, ({double lat, double lon})? coord) {
    switch (this) {
      case PlaceStampMode.off:
        return null;
      case PlaceStampMode.city:
        return address.city;
      case PlaceStampMode.district:
        return _join([address.city, address.district]);
      case PlaceStampMode.neighborhood:
        return _join([address.city, address.district, address.neighborhood]);
      case PlaceStampMode.full:
        return address.fullAddress;
      case PlaceStampMode.gps:
        if (coord == null) return null;
        return '${coord.lat.toStringAsFixed(4)}, ${coord.lon.toStringAsFixed(4)}';
    }
  }

  static String? _join(List<String?> parts) {
    final visible = parts
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return visible.isEmpty ? null : visible.join(' ');
  }
}

enum StampPosition {
  topLeft,
  topCenter,
  topRight,
  middleLeft,
  center,
  middleRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  String get title {
    switch (this) {
      case StampPosition.topLeft:
        return '좌상단';
      case StampPosition.topCenter:
        return '상단';
      case StampPosition.topRight:
        return '우상단';
      case StampPosition.middleLeft:
        return '좌중단';
      case StampPosition.center:
        return '중앙';
      case StampPosition.middleRight:
        return '우중단';
      case StampPosition.bottomLeft:
        return '좌하단';
      case StampPosition.bottomCenter:
        return '하단';
      case StampPosition.bottomRight:
        return '우하단';
    }
  }
}

enum MemoSize {
  small,
  normal,
  large;

  String get title {
    switch (this) {
      case MemoSize.small:
        return '작게';
      case MemoSize.normal:
        return '보통';
      case MemoSize.large:
        return '크게';
    }
  }

  double get scale {
    switch (this) {
      case MemoSize.small:
        return 0.82;
      case MemoSize.normal:
        return 1.0;
      case MemoSize.large:
        return 1.22;
    }
  }
}

enum MemoOutlineColor {
  black,
  red,
  white;

  String get title {
    switch (this) {
      case MemoOutlineColor.black:
        return '블랙';
      case MemoOutlineColor.red:
        return '레드';
      case MemoOutlineColor.white:
        return '화이트';
    }
  }

  Color get color {
    switch (this) {
      case MemoOutlineColor.black:
        return Colors.black;
      case MemoOutlineColor.red:
        return const Color(0xFFE53935);
      case MemoOutlineColor.white:
        return Colors.white;
    }
  }
}

enum MemoTextColor {
  white,
  black,
  cream,
  pink,
  red,
  yellow,
  green,
  blue;

  String get title {
    switch (this) {
      case MemoTextColor.white:
        return '화이트';
      case MemoTextColor.black:
        return '블랙';
      case MemoTextColor.cream:
        return '크림';
      case MemoTextColor.pink:
        return '핑크';
      case MemoTextColor.red:
        return '레드';
      case MemoTextColor.yellow:
        return '옐로';
      case MemoTextColor.green:
        return '그린';
      case MemoTextColor.blue:
        return '블루';
    }
  }

  Color get color {
    switch (this) {
      case MemoTextColor.white:
        return Colors.white;
      case MemoTextColor.black:
        return const Color(0xFF171717);
      case MemoTextColor.cream:
        return const Color(0xFFFFF5DD);
      case MemoTextColor.pink:
        return const Color(0xFFFF9BB5);
      case MemoTextColor.red:
        return const Color(0xFFFF4D5F);
      case MemoTextColor.yellow:
        return const Color(0xFFFFE75A);
      case MemoTextColor.green:
        return const Color(0xFF58D68D);
      case MemoTextColor.blue:
        return const Color(0xFF70B7FF);
    }
  }
}

enum MemoFont {
  roundTopper,
  boldTopper,
  softPop,
  handwritten,
  neat,
  serif;

  String get title {
    switch (this) {
      case MemoFont.roundTopper:
        return '라운드';
      case MemoFont.boldTopper:
        return '굵은 토퍼';
      case MemoFont.softPop:
        return '말랑';
      case MemoFont.handwritten:
        return '손글씨';
      case MemoFont.neat:
        return '깔끔';
      case MemoFont.serif:
        return '세리프';
    }
  }

  TextStyle style({double? fontSize, Color? color, double? height}) {
    switch (this) {
      case MemoFont.roundTopper:
        return GoogleFonts.jua(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.08,
          fontWeight: FontWeight.w400,
        );
      case MemoFont.boldTopper:
        return GoogleFonts.blackHanSans(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.02,
          fontWeight: FontWeight.w900,
        );
      case MemoFont.softPop:
        return GoogleFonts.gugi(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.08,
          fontWeight: FontWeight.w400,
        );
      case MemoFont.handwritten:
        return GoogleFonts.nanumPenScript(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.1,
          fontWeight: FontWeight.w400,
        );
      case MemoFont.neat:
        return GoogleFonts.gowunDodum(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.12,
          fontWeight: FontWeight.w700,
        );
      case MemoFont.serif:
        return GoogleFonts.notoSerifKr(
          fontSize: fontSize,
          color: color,
          height: height ?? 1.18,
          fontWeight: FontWeight.w800,
        );
    }
  }

  String? get fontFamily => style().fontFamily;

  FontWeight get fontWeight => style().fontWeight ?? FontWeight.w700;

  double get lineHeight => style().height ?? 1.1;
}

class AddressParts {
  final String? city;
  final String? district;
  final String? neighborhood;
  final String? fullAddress;

  const AddressParts({
    this.city,
    this.district,
    this.neighborhood,
    this.fullAddress,
  });

  static const sample = AddressParts(
    city: '서울특별시',
    district: '강남구',
    neighborhood: '역삼동',
    fullAddress: '서울특별시 강남구 테헤란로 123',
  );

  static const sampleEn = AddressParts(
    city: 'Seoul',
    district: 'Gangnam-gu',
    neighborhood: 'Yeoksam-dong',
    fullAddress: '123 Teheran-ro, Gangnam-gu, Seoul',
  );

  bool get isEmpty =>
      city == null &&
      district == null &&
      neighborhood == null &&
      fullAddress == null;
}

class LocalizedAddress {
  final AddressParts ko;
  final AddressParts en;
  const LocalizedAddress({required this.ko, required this.en});

  static const empty = LocalizedAddress(ko: AddressParts(), en: AddressParts());

  AddressParts forLocale(String locale) => locale == 'ko' ? ko : en;

  bool get isEmpty => ko.isEmpty && en.isEmpty;
}

class StampConfiguration {
  TimeStampMode timeMode;
  TimeHourFormat hourFormat;
  PlaceStampMode placeMode;
  StampPosition position;
  String memo;
  double fontScale;
  StampLanguage language;
  String styleId;
  Color? stampColor;
  MemoSize memoSize;
  MemoOutlineColor memoOutlineColor;
  MemoTextColor memoTextColor;
  MemoFont memoFont;
  bool tapToCapture;
  bool shutterSound;

  StampConfiguration({
    this.timeMode = TimeStampMode.minute,
    this.hourFormat = TimeHourFormat.h24,
    this.placeMode = PlaceStampMode.district,
    this.position = StampPosition.bottomLeft,
    this.memo = '',
    this.fontScale = 1.0,
    this.language = StampLanguage.auto,
    this.styleId = 'minimal',
    this.stampColor,
    this.memoSize = MemoSize.normal,
    this.memoOutlineColor = MemoOutlineColor.black,
    this.memoTextColor = MemoTextColor.white,
    this.memoFont = MemoFont.roundTopper,
    this.tapToCapture = true,
    this.shutterSound = true,
  });

  static const double minFontScale = 0.6;
  static const double maxFontScale = 2.0;

  String resolvedLocale(String systemLanguageCode) =>
      language.resolve(systemLanguageCode);

  /// 날짜/시간 + 장소 (메모 제외)
  List<String> infoLines(
    DateTime date,
    LocalizedAddress address,
    ({double lat, double lon})? coord, {
    required String systemLanguageCode,
  }) {
    final addressLocale = resolvedLocale(systemLanguageCode);
    final timeLocale = systemLanguageCode == 'ko' ? 'ko' : 'en';
    final addr = address.forLocale(addressLocale);
    final style = StampStyle.byId(styleId);
    final styled = _styledLines(style, date, addr, coord);
    if (styled != null) return styled;
    return [
      timeMode.textFor(date, locale: timeLocale, hourFormat: hourFormat),
      placeMode.textFrom(addr, coord),
    ].whereType<String>().toList();
  }

  List<String>? _styledLines(
    StampStyle style,
    DateTime date,
    AddressParts address,
    ({double lat, double lon})? coord,
  ) {
    final place = _placeLine(address, coord);
    String hm(String locale) => hourFormat.formatMinute(date, locale: locale);
    switch (style.template) {
      case StampTextTemplate.standard:
        return null;
      case StampTextTemplate.dietKorean:
        return [
          hm('ko'),
          DateFormat('yyyy년 M월 d일 (E)', 'ko').format(date),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.studyStack:
        return [
          DateFormat('yyyy', 'en').format(date),
          '${DateFormat('MMMM', 'en').format(date).toUpperCase()} ${_ordinal(date.day).toUpperCase()}',
          hm('en'),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.morningProof:
        return [
          '${hm('en')}, ${DateFormat('MMMM', 'en').format(date)} ${_ordinal(date.day)} ${DateFormat('yyyy', 'en').format(date)}',
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.workoutFrame:
        return [
          '${DateFormat('MMMM', 'en').format(date)}.${date.day}',
          hm('en'),
          place,
        ].whereType<String>().where((line) => line.trim().isNotEmpty).toList();
      case StampTextTemplate.koreanBigTime:
        return [
          DateFormat('yyyy년 M월 d일', 'ko').format(date),
          hm('ko'),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.englishTiny:
        return [
          DateFormat('yyyy', 'en').format(date),
          '${DateFormat('MMMM', 'en').format(date).toUpperCase()} ${_ordinal(date.day).toUpperCase()}',
          hm('en'),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.lineDivider:
        return [
          DateFormat('yyyy', 'en').format(date),
          '${DateFormat('MMMM', 'en').format(date).toUpperCase()} ${_ordinal(date.day).toUpperCase()}',
          hm('en'),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.boxedDate:
        return [
          hm('en'),
          DateFormat('yyyy MMMM d', 'en').format(date).toUpperCase(),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.splitBoxes:
        return [
          hourFormat == TimeHourFormat.h24
              ? DateFormat('HH   mm').format(date)
              : DateFormat('h   mm a', 'en').format(date),
          DateFormat('MMMM d yyyy', 'en').format(date).toUpperCase(),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.circleTime:
        return [
          hm('en'),
          DateFormat('MMMM d, yyyy', 'en').format(date).toUpperCase(),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.notebook:
        return [
          hm('en'),
          DateFormat('yyyy MMMM d', 'en').format(date),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.bottomBar:
        return [
          '${DateFormat('yy. MM. dd').format(date)}   ${hm('en')}',
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.calendarMini:
        return [
          DateFormat('yyyy', 'en').format(date),
          DateFormat('MMM d', 'en').format(date),
          hm('en'),
          place,
        ].whereType<String>().toList();
      case StampTextTemplate.digitalClock:
        return [
          hm('en'),
          DateFormat('yyyy.MM.dd', 'en').format(date),
          place,
        ].whereType<String>().toList();
    }
  }

  String? _placeLine(AddressParts address, ({double lat, double lon})? coord) {
    if (placeMode == PlaceStampMode.off) return null;
    return placeMode.textFrom(address, coord);
  }

  String? get memoText {
    final t = memo.trim();
    return t.isEmpty ? null : t;
  }
}

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}
