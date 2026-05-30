import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'stamp_settings.dart';

class LocationProvider extends ChangeNotifier {
  static const String _kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );
  LocalizedAddress _address = LocalizedAddress.empty;
  ({double lat, double lon})? _coordinate;
  double? _accuracyMeters;
  String _statusMessage = '';

  LocalizedAddress get address => _address;
  ({double lat, double lon})? get coordinate => _coordinate;
  double? get accuracyMeters => _accuracyMeters;
  String get statusMessage => _statusMessage;

  Future<void> requestAndFetch() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _statusMessage = '위치 서비스가 꺼져 있습니다.';
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _statusMessage = '위치 권한이 필요합니다.';
      notifyListeners();
      return;
    }
    await _fetchLocation();
  }

  Future<void> refresh() => requestAndFetch();

  Future<void> _fetchLocation() async {
    try {
      _statusMessage = '정확한 위치 확인 중...';
      _address = LocalizedAddress.empty;
      notifyListeners();

      final position = await _bestAvailablePosition();
      _applyPosition(position);
      await _reverseGeocodeAll(position.latitude, position.longitude);
    } catch (e) {
      _statusMessage = '위치 확인 실패: $e';
      notifyListeners();
    }
  }

  Future<Position> _bestAvailablePosition() async {
    Position? best = await Geolocator.getLastKnownPosition();
    if (best != null) {
      _applyPosition(best, geocodingPending: true, isCached: true);
    }

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (best == null || _isBetterPosition(current, best)) {
        best = current;
        _applyPosition(best, geocodingPending: true);
      }
    } catch (_) {
      if (best == null) rethrow;
      _statusMessage = '최근 위치 사용 중 · 새 GPS 신호 대기';
      notifyListeners();
    }

    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      ),
    ).timeout(const Duration(seconds: 10), onTimeout: (sink) => sink.close());

    try {
      await for (final candidate in stream) {
        if (best == null || _isBetterPosition(candidate, best)) {
          best = candidate;
          _applyPosition(best, geocodingPending: true);
        }
        if (best.accuracy <= 25) break;
      }
    } catch (_) {
      // 단발 위치 결과라도 있으면 그것을 사용한다.
    }

    if (best == null) {
      throw const LocationServiceDisabledException();
    }
    return best;
  }

  bool _isBetterPosition(Position candidate, Position current) {
    return candidate.accuracy > 0 && candidate.accuracy < current.accuracy;
  }

  void _applyPosition(
    Position position, {
    bool geocodingPending = false,
    bool isCached = false,
  }) {
    _coordinate = (lat: position.latitude, lon: position.longitude);
    _accuracyMeters = position.accuracy;
    final suffix = geocodingPending ? ' · 주소 확인 중' : '';
    final prefix = isCached ? '최근 위치' : '위치 확인';
    _statusMessage = position.accuracy > 100
        ? '$prefix · 정확도 낮음: 약 ${position.accuracy.round()}m$suffix'
        : '$prefix: 약 ${position.accuracy.round()}m$suffix';
    notifyListeners();
  }

  Future<AddressParts> _geocodeAt(
    double lat,
    double lon,
    String localeId,
  ) async {
    try {
      await setLocaleIdentifier(localeId);
      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return const AddressParts();
      return addressPartsFromPlacemark(_bestPlacemark(placemarks));
    } catch (_) {
      return const AddressParts();
    }
  }

  Future<void> _reverseGeocodeAll(double lat, double lon) async {
    final kakaoKo = await _kakaoAddressAt(lat, lon);
    final ko = kakaoKo ?? await _geocodeAt(lat, lon, 'ko_KR');
    final en = await _geocodeAt(lat, lon, 'en_US');
    _address = LocalizedAddress(ko: ko, en: en);
    notifyListeners();
  }

  Future<AddressParts?> _kakaoAddressAt(double lat, double lon) async {
    if (_kakaoRestApiKey.isEmpty) return null;
    final client = HttpClient();
    try {
      final uri = Uri.https(
        'dapi.kakao.com',
        '/v2/local/geo/coord2address.json',
        {'x': lon.toString(), 'y': lat.toString(), 'input_coord': 'WGS84'},
      );
      final request = await client.getUrl(uri);
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'KakaoAK $_kakaoRestApiKey',
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) return null;
      final body = await response.transform(utf8.decoder).join();
      final decoded = json.decode(body) as Map<String, dynamic>;
      return addressPartsFromKakaoResponse(decoded);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}

@visibleForTesting
AddressParts? addressPartsFromKakaoResponse(Map<String, dynamic> response) {
  final documents = response['documents'];
  if (documents is! List || documents.isEmpty) return null;
  final first = documents.first;
  if (first is! Map) return null;
  final road = first['road_address'];
  final jibun = first['address'];

  if (road is Map) {
    final full = _stripCountryPrefix(
      _clean(road['address_name'] as String?) ?? '',
    );
    if (full.isNotEmpty) {
      return AddressParts(
        city: _clean(road['region_1depth_name'] as String?),
        district: _clean(road['region_2depth_name'] as String?),
        neighborhood: _clean(road['region_3depth_name'] as String?),
        fullAddress: full,
      );
    }
  }

  if (jibun is Map) {
    final full = _stripCountryPrefix(
      _clean(jibun['address_name'] as String?) ?? '',
    );
    if (full.isNotEmpty) {
      return AddressParts(
        city: _clean(jibun['region_1depth_name'] as String?),
        district: _clean(jibun['region_2depth_name'] as String?),
        neighborhood: _clean(jibun['region_3depth_name'] as String?),
        fullAddress: full,
      );
    }
  }
  return null;
}

@visibleForTesting
AddressParts addressPartsFromPlacemark(Placemark p) {
  final admin = _clean(p.administrativeArea);
  final subAdmin = _clean(p.subAdministrativeArea);
  final locality = _clean(p.locality);
  final useSubAdminAsCity = _isKoreanProvince(p, admin) && subAdmin != null;

  final city = useSubAdminAsCity
      ? subAdmin
      : _firstNonEmpty([
          p.administrativeArea,
          p.locality,
          p.subAdministrativeArea,
        ]);
  final district = _firstDistinct(
    [
      if (useSubAdminAsCity) locality,
      p.subAdministrativeArea,
      p.locality,
      p.subLocality,
    ],
    [city],
  );
  final neighborhood = _firstDistinct(
    [p.subLocality, p.thoroughfare, p.name],
    [city, district],
  );

  return AddressParts(
    city: city,
    district: district,
    neighborhood: neighborhood,
    fullAddress: _fullAddress(p),
  );
}

Placemark _bestPlacemark(List<Placemark> placemarks) {
  return placemarks.reduce((best, current) {
    return _placemarkScore(current) > _placemarkScore(best) ? current : best;
  });
}

int _placemarkScore(Placemark p) {
  final roadBonus = _roadAddressLine(p) == null ? 0 : 4;
  return roadBonus +
      [
        p.administrativeArea,
        p.subAdministrativeArea,
        p.locality,
        p.subLocality,
        p.street,
        p.thoroughfare,
        p.subThoroughfare,
      ].where((s) => _clean(s) != null).length;
}

String? _fullAddress(Placemark p) {
  final roadLine = _roadAddressLine(p);
  if (roadLine != null) {
    final normalizedRoad = _normalize(roadLine);
    final areaParts = [
      p.administrativeArea,
      p.subAdministrativeArea,
      p.locality,
      p.subLocality,
    ].map(_clean).whereType<String>().toList();
    final alreadyContainsArea = areaParts
        .map(_normalize)
        .where((part) => part.isNotEmpty)
        .any(normalizedRoad.contains);
    if (alreadyContainsArea) {
      return _stripCountryPrefix(roadLine);
    }
    return _joinDistinct([
      p.administrativeArea,
      p.subAdministrativeArea,
      p.locality,
      p.subLocality,
      roadLine,
    ]);
  }
  return _joinDistinct([
    p.administrativeArea,
    p.subAdministrativeArea,
    p.locality,
    p.subLocality,
    p.thoroughfare,
    p.subThoroughfare,
  ]);
}

String? _roadAddressLine(Placemark p) {
  final street = _clean(p.street);
  if (street != null && _looksLikeRoadAddress(street)) return street;

  final roadName = _clean(p.thoroughfare);
  if (roadName == null || !_looksLikeRoadName(roadName)) return null;
  final buildingNo = _clean(p.subThoroughfare);
  return _joinDistinct([roadName, buildingNo]);
}

String _stripCountryPrefix(String value) {
  var result = value.trim();
  for (final country in const [
    '대한민국',
    '한국',
    'Republic of Korea',
    'South Korea',
    'Korea',
  ]) {
    final pattern = RegExp(
      '^${RegExp.escape(country)}\\s+',
      caseSensitive: false,
    );
    result = result.replaceFirst(pattern, '');
  }
  return result;
}

bool _looksLikeRoadAddress(String value) {
  final normalized = _normalize(value);
  return RegExp(
    r'(대로|로|길|beon-gil|daero|ro|gil|-daero|-ro|-gil)',
    caseSensitive: false,
  ).hasMatch(normalized);
}

bool _looksLikeRoadName(String value) {
  final normalized = _normalize(value);
  return RegExp(
    r'(대로|로|길|beon-gil|daero|ro|gil|-daero|-ro|-gil)$',
    caseSensitive: false,
  ).hasMatch(normalized);
}

String? _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final cleaned = _clean(value);
    if (cleaned != null) return cleaned;
  }
  return null;
}

String? _firstDistinct(List<String?> values, List<String?> existing) {
  final normalizedExisting = existing
      .map(_clean)
      .whereType<String>()
      .map(_normalize)
      .toSet();
  for (final value in values) {
    final cleaned = _clean(value);
    if (cleaned != null && !normalizedExisting.contains(_normalize(cleaned))) {
      return cleaned;
    }
  }
  return null;
}

String? _joinDistinct(List<String?> values) {
  final parts = <String>[];
  final seen = <String>{};
  for (final value in values) {
    final cleaned = _clean(value);
    if (cleaned == null) continue;
    final normalized = _normalize(cleaned);
    if (seen.add(normalized)) parts.add(cleaned);
  }
  return parts.isEmpty ? null : parts.join(' ');
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

String _normalize(String value) =>
    value.replaceAll(RegExp(r'\s+'), '').toLowerCase();

bool _isKoreanProvince(Placemark p, String? admin) {
  final countryCode = _clean(p.isoCountryCode)?.toUpperCase();
  return countryCode == 'KR' || (admin?.endsWith('도') ?? false);
}
