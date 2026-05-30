import '../topper_template.dart';

/// 앱 내 라이브러리에서 다루는 촬영 기록 한 건.
class CaptureRecord {
  final int? id;
  final DateTime capturedAt; // 카메라 셔터를 누른 순간
  final DateTime savedAt; // 갤러리에 저장된 순간(스탬프 확정 시각)
  final String thumbnailPath;
  final String? originalPath;
  final String? stampedPath;
  final int? folderId;
  final String? categoryId; // TopperCategory.name
  final String memo;
  final String styleId;
  final String? address;
  final double? latitude;
  final double? longitude;

  const CaptureRecord({
    this.id,
    required this.capturedAt,
    required this.savedAt,
    required this.thumbnailPath,
    this.originalPath,
    this.stampedPath,
    this.folderId,
    required this.categoryId,
    required this.memo,
    required this.styleId,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  TopperCategory? get category {
    final id = categoryId ?? inferCategoryId(memo);
    if (id == null) return null;
    for (final c in TopperCategory.values) {
      if (c.name == id) return c;
    }
    return null;
  }

  /// 시간대 라벨 (촬영 시각 기준)
  TimeOfDayBucket get timeBucket {
    final h = capturedAt.hour;
    if (h < 6) return TimeOfDayBucket.night;
    if (h < 12) return TimeOfDayBucket.morning;
    if (h < 18) return TimeOfDayBucket.afternoon;
    return TimeOfDayBucket.evening;
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'captured_at': capturedAt.millisecondsSinceEpoch,
    'saved_at': savedAt.millisecondsSinceEpoch,
    'thumbnail_path': thumbnailPath,
    'original_path': originalPath,
    'stamped_path': stampedPath,
    'folder_id': folderId,
    'category_id': categoryId,
    'memo': memo,
    'style_id': styleId,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };

  static CaptureRecord fromMap(Map<String, Object?> m) => CaptureRecord(
    id: m['id'] as int?,
    capturedAt: DateTime.fromMillisecondsSinceEpoch(m['captured_at'] as int),
    savedAt: DateTime.fromMillisecondsSinceEpoch(m['saved_at'] as int),
    thumbnailPath: m['thumbnail_path'] as String,
    originalPath: m['original_path'] as String?,
    stampedPath: m['stamped_path'] as String?,
    folderId: m['folder_id'] as int?,
    categoryId: m['category_id'] as String?,
    memo: (m['memo'] as String?) ?? '',
    styleId: (m['style_id'] as String?) ?? 'minimal',
    address: m['address'] as String?,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
  );
}

class CaptureFolder {
  final int? id;
  final String name;
  final DateTime createdAt;

  const CaptureFolder({this.id, required this.name, required this.createdAt});

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  static CaptureFolder fromMap(Map<String, Object?> m) => CaptureFolder(
    id: m['id'] as int?,
    name: m['name'] as String,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
  );
}

enum TimeOfDayBucket {
  morning,
  afternoon,
  evening,
  night;

  String get title {
    switch (this) {
      case TimeOfDayBucket.morning:
        return '아침';
      case TimeOfDayBucket.afternoon:
        return '점심';
      case TimeOfDayBucket.evening:
        return '저녁';
      case TimeOfDayBucket.night:
        return '야간';
    }
  }

  String get emoji {
    switch (this) {
      case TimeOfDayBucket.morning:
        return '🌅';
      case TimeOfDayBucket.afternoon:
        return '☀️';
      case TimeOfDayBucket.evening:
        return '🌆';
      case TimeOfDayBucket.night:
        return '🌙';
    }
  }
}

enum CaptureSortBy {
  capturedDesc,
  capturedAsc,
  savedDesc,
  savedAsc;

  String get title {
    switch (this) {
      case CaptureSortBy.capturedDesc:
        return '최근 촬영';
      case CaptureSortBy.capturedAsc:
        return '오래된 촬영';
      case CaptureSortBy.savedDesc:
        return '최근 저장';
      case CaptureSortBy.savedAsc:
        return '오래된 저장';
    }
  }
}

/// 메모 텍스트가 토퍼 템플릿과 정확히 일치하면 카테고리 id 반환.
String? inferCategoryId(String memo) {
  final trimmed = memo.trim();
  if (trimmed.isEmpty) return null;
  for (final t in TopperTemplates.all) {
    if (t.text == trimmed) return t.category.name;
  }
  return null;
}
