import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../stamp_settings.dart';

class ConfigStorage {
  static const _kKey = 'stamp_config_v1';
  static const _kOnboardingSeenKey = 'onboarding_seen_v1';

  /// 저장된 StampConfiguration을 불러온다. 없거나 손상되면 기본값.
  static Future<StampConfiguration> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kKey);
      if (raw == null) return StampConfiguration();
      final map = json.decode(raw) as Map<String, dynamic>;
      return StampConfiguration(
        timeMode:
            _enumByName(TimeStampMode.values, map['timeMode']) ??
            TimeStampMode.minute,
        hourFormat:
            _enumByName(TimeHourFormat.values, map['hourFormat']) ??
            TimeHourFormat.h24,
        placeMode:
            _enumByName(PlaceStampMode.values, map['placeMode']) ??
            PlaceStampMode.district,
        position:
            _enumByName(StampPosition.values, map['position']) ??
            StampPosition.bottomLeft,
        memo: (map['memo'] as String?) ?? '',
        fontScale: (map['fontScale'] as num?)?.toDouble() ?? 1.0,
        language:
            _enumByName(StampLanguage.values, map['language']) ??
            StampLanguage.auto,
        styleId: (map['styleId'] as String?) ?? 'minimal',
        stampColor: _colorFromJson(map['stampColor']),
        memoSize:
            _enumByName(MemoSize.values, map['memoSize']) ?? MemoSize.normal,
        memoOutlineColor:
            _enumByName(MemoOutlineColor.values, map['memoOutlineColor']) ??
            MemoOutlineColor.black,
        memoTextColor:
            _enumByName(MemoTextColor.values, map['memoTextColor']) ??
            MemoTextColor.white,
        memoFont:
            _enumByName(MemoFont.values, map['memoFont']) ??
            MemoFont.roundTopper,
        tapToCapture: (map['tapToCapture'] as bool?) ?? true,
        shutterSound: (map['shutterSound'] as bool?) ?? true,
      );
    } catch (_) {
      return StampConfiguration();
    }
  }

  /// 변경된 설정을 즉시 디스크에 영속화한다.
  static Future<void> save(StampConfiguration config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'timeMode': config.timeMode.name,
        'hourFormat': config.hourFormat.name,
        'placeMode': config.placeMode.name,
        'position': config.position.name,
        'memo': config.memo,
        'fontScale': config.fontScale,
        'language': config.language.name,
        'styleId': config.styleId,
        'stampColor': config.stampColor?.toARGB32(),
        'memoSize': config.memoSize.name,
        'memoOutlineColor': config.memoOutlineColor.name,
        'memoTextColor': config.memoTextColor.name,
        'memoFont': config.memoFont.name,
        'tapToCapture': config.tapToCapture,
        'shutterSound': config.shutterSound,
      };
      await prefs.setString(_kKey, json.encode(map));
    } catch (_) {
      // 저장 실패는 조용히 무시 — 다음 변경 때 다시 시도
    }
  }

  static T? _enumByName<T extends Enum>(List<T> values, dynamic name) {
    if (name is! String) return null;
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  static Color? _colorFromJson(dynamic value) {
    if (value is int) return Color(value);
    return null;
  }

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_kOnboardingSeenKey) ?? false);
  }

  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingSeenKey, true);
  }
}
