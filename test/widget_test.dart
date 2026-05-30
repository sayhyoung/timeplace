import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeplace_flutter/location_provider.dart';
import 'package:timeplace_flutter/stamp_settings.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko');
    await initializeDateFormatting('en');
  });

  test('TimeStampMode.minute formats correctly in Korean', () {
    final date = DateTime(2026, 5, 1, 14, 30, 0);
    expect(
      TimeStampMode.minute.textFor(date, locale: 'ko'),
      '2026.05.01   14:30',
    );
  });

  test('TimeStampMode.minute formats correctly in English', () {
    final date = DateTime(2026, 5, 1, 14, 30, 0);
    expect(
      TimeStampMode.minute.textFor(date, locale: 'en'),
      'May 1, 2026   14:30',
    );
  });

  test('TimeStampMode.minute can use 12-hour format', () {
    final date = DateTime(2026, 5, 1, 14, 30, 0);
    expect(
      TimeStampMode.minute.textFor(
        date,
        locale: 'ko',
        hourFormat: TimeHourFormat.h12,
      ),
      '2026.05.01   오후 2:30',
    );
  });

  test('infoLines excludes memo', () {
    final config = StampConfiguration(
      timeMode: TimeStampMode.date,
      placeMode: PlaceStampMode.off,
      memo: 'hello',
    );
    const addr = LocalizedAddress(
      ko: AddressParts.sample,
      en: AddressParts.sampleEn,
    );
    final lines = config.infoLines(
      DateTime(2026, 5, 1),
      addr,
      null,
      systemLanguageCode: 'ko',
    );
    expect(lines.length, 1);
    expect(lines.first, '2026.05.01');
    expect(config.memoText, 'hello');
  });

  test('infoLines does not show sample address when address is empty', () {
    final config = StampConfiguration(
      timeMode: TimeStampMode.minute,
      placeMode: PlaceStampMode.district,
    );

    final lines = config.infoLines(
      DateTime(2026, 5, 1, 14, 30),
      LocalizedAddress.empty,
      (lat: 37.5665, lon: 126.9780),
      systemLanguageCode: 'ko',
    );

    expect(lines, ['2026.05.01   14:30']);
  });

  test('diet poster style formats large Korean time stamp lines', () {
    final config = StampConfiguration(
      styleId: 'diet_poster',
      placeMode: PlaceStampMode.full,
    );

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 7, 20),
      LocalizedAddress.empty,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['07:20', '2026년 5월 4일 (월)']);
  });

  test('template styles include place line when place stamp is enabled', () {
    final config = StampConfiguration(
      styleId: 'diet_poster',
      placeMode: PlaceStampMode.neighborhood,
    );
    const addr = LocalizedAddress(
      ko: AddressParts.sample,
      en: AddressParts.sampleEn,
    );

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 7, 20),
      addr,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['07:20', '2026년 5월 4일 (월)', '서울특별시 강남구 역삼동']);
  });

  test('study poster style formats stacked English proof lines', () {
    final config = StampConfiguration(styleId: 'study_poster');

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 8, 32),
      LocalizedAddress.empty,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['2026', 'MAY 4TH', '08:32']);
  });

  test('digital style formats clock and numeric date lines', () {
    final config = StampConfiguration(styleId: 'digital_large');

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 18, 20),
      LocalizedAddress.empty,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['18:20', '2026.05.04']);
  });

  test('circle style keeps time on one line', () {
    final config = StampConfiguration(styleId: 'circle_time');

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 18, 20),
      LocalizedAddress.empty,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['18:20', 'MAY 4, 2026']);
  });

  test('address language changes address without changing standard time', () {
    final config = StampConfiguration(
      language: StampLanguage.en,
      placeMode: PlaceStampMode.district,
    );
    const addr = LocalizedAddress(
      ko: AddressParts.sample,
      en: AddressParts.sampleEn,
    );

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 18, 20),
      addr,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['2026.05.04   18:20', 'Seoul Gangnam-gu']);
  });

  test('bottom band style formats compact caption line', () {
    final config = StampConfiguration(styleId: 'bottom_band');

    final lines = config.infoLines(
      DateTime(2026, 5, 4, 18, 20),
      LocalizedAddress.empty,
      null,
      systemLanguageCode: 'ko',
    );

    expect(lines, ['26. 05. 04   18:20']);
  });

  test(
    'addressPartsFromPlacemark maps Korean address fields without duplicates',
    () {
      const placemark = Placemark(
        administrativeArea: '서울특별시',
        locality: '서울특별시',
        subLocality: '강남구',
        thoroughfare: '역삼동',
        subThoroughfare: '123',
      );

      final address = addressPartsFromPlacemark(placemark);

      expect(address.city, '서울특별시');
      expect(address.district, '강남구');
      expect(address.neighborhood, '역삼동');
      expect(address.fullAddress, '서울특별시 강남구 역삼동 123');
    },
  );

  test(
    'addressPartsFromPlacemark prefers road name address when available',
    () {
      const placemark = Placemark(
        administrativeArea: '서울특별시',
        subLocality: '강남구',
        thoroughfare: '테헤란로',
        subThoroughfare: '123',
      );

      final address = addressPartsFromPlacemark(placemark);

      expect(address.fullAddress, '서울특별시 강남구 테헤란로 123');
    },
  );

  test('addressPartsFromPlacemark avoids duplicated full road address', () {
    const placemark = Placemark(
      administrativeArea: '경기도',
      subAdministrativeArea: '남양주시',
      street: '대한민국 경기도 남양주시 다산순환로 111',
      thoroughfare: '다산순환로',
      subThoroughfare: '111',
    );

    final address = addressPartsFromPlacemark(placemark);

    expect(address.fullAddress, '경기도 남양주시 다산순환로 111');
  });

  test('addressPartsFromKakaoResponse prefers road address', () {
    final address = addressPartsFromKakaoResponse({
      'documents': [
        {
          'road_address': {
            'address_name': '경기도 남양주시 다산순환로 111',
            'region_1depth_name': '경기도',
            'region_2depth_name': '남양주시',
            'region_3depth_name': '다산동',
          },
          'address': {
            'address_name': '경기도 남양주시 다산동 123',
            'region_1depth_name': '경기도',
            'region_2depth_name': '남양주시',
            'region_3depth_name': '다산동',
          },
        },
      ],
    });

    expect(address?.fullAddress, '경기도 남양주시 다산순환로 111');
    expect(address?.neighborhood, '다산동');
  });

  test(
    'addressPartsFromPlacemark prefers subAdministrativeArea for district',
    () {
      const placemark = Placemark(
        isoCountryCode: 'KR',
        administrativeArea: '경기도',
        subAdministrativeArea: '성남시',
        locality: '분당구',
        subLocality: '정자동',
      );

      final address = addressPartsFromPlacemark(placemark);

      expect(address.city, '성남시');
      expect(address.district, '분당구');
      expect(address.neighborhood, '정자동');
      expect(address.fullAddress, '경기도 성남시 분당구 정자동');
    },
  );
}
