import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'capture_record.dart';

class CaptureDb {
  static Database? _db;

  static Future<Database> _open() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'captures.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE captures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            captured_at INTEGER NOT NULL,
            saved_at INTEGER NOT NULL,
            thumbnail_path TEXT NOT NULL,
            original_path TEXT,
            stamped_path TEXT,
            folder_id INTEGER,
            category_id TEXT,
            memo TEXT,
            style_id TEXT,
            address TEXT,
            latitude REAL,
            longitude REAL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_captured_at ON captures(captured_at DESC)',
        );
        await db.execute('''
          CREATE TABLE folders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE captures ADD COLUMN original_path TEXT',
          );
          await db.execute('ALTER TABLE captures ADD COLUMN stamped_path TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE captures ADD COLUMN folder_id INTEGER');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS folders (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              created_at INTEGER NOT NULL
            )
          ''');
        }
      },
    );
    return _db!;
  }

  static Future<int> insert(CaptureRecord r) async {
    final db = await _open();
    final m = Map<String, Object?>.from(r.toMap())..remove('id');
    return db.insert('captures', m);
  }

  static Future<void> delete(int id) async {
    final db = await _open();
    await db.delete('captures', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> updateFolder(int captureId, int? folderId) async {
    final db = await _open();
    await db.update(
      'captures',
      {'folder_id': folderId},
      where: 'id = ?',
      whereArgs: [captureId],
    );
  }

  static Future<List<CaptureRecord>> query({
    String? categoryId,
    TimeOfDayBucket? timeBucket,
    int? folderId,
    String? memoQuery,
    CaptureSortBy sort = CaptureSortBy.capturedDesc,
  }) async {
    final db = await _open();
    final where = <String>[];
    final args = <Object?>[];
    if (folderId != null) {
      where.add('folder_id = ?');
      args.add(folderId);
    }
    if (memoQuery != null && memoQuery.trim().isNotEmpty) {
      where.add('memo LIKE ?');
      args.add('%${memoQuery.trim()}%');
    }
    final orderBy = switch (sort) {
      CaptureSortBy.capturedDesc => 'captured_at DESC',
      CaptureSortBy.capturedAsc => 'captured_at ASC',
      CaptureSortBy.savedDesc => 'saved_at DESC',
      CaptureSortBy.savedAsc => 'saved_at ASC',
    };
    final rows = await db.query(
      'captures',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: orderBy,
    );
    var list = rows.map(CaptureRecord.fromMap).toList();
    if (categoryId != null) {
      list = list.where((r) => r.category?.name == categoryId).toList();
    }
    if (timeBucket != null) {
      list = list.where((r) => r.timeBucket == timeBucket).toList();
    }
    return list;
  }

  static Future<int> count() async {
    final db = await _open();
    final r = await db.rawQuery('SELECT COUNT(*) AS c FROM captures');
    return (r.first['c'] as int?) ?? 0;
  }

  static Future<List<CaptureFolder>> folders() async {
    final db = await _open();
    final rows = await db.query('folders', orderBy: 'created_at DESC');
    return rows.map(CaptureFolder.fromMap).toList();
  }

  static Future<int> createFolder(String name) async {
    final db = await _open();
    return db.insert(
      'folders',
      CaptureFolder(name: name, createdAt: DateTime.now()).toMap()
        ..remove('id'),
    );
  }

  static Future<void> deleteFolder(int id) async {
    final db = await _open();
    await db.update(
      'captures',
      {'folder_id': null},
      where: 'folder_id = ?',
      whereArgs: [id],
    );
    await db.delete('folders', where: 'id = ?', whereArgs: [id]);
  }
}

class CaptureFiles {
  static Future<String> saveOriginal(Uint8List bytes) =>
      _save(bytes, 'originals', 'jpg');

  static Future<String> saveStamped(Uint8List bytes) =>
      _save(bytes, 'stamped', 'png');

  static Future<String> saveForShare(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final shareDir = Directory(p.join(dir.path, 'share'));
    if (!await shareDir.exists()) {
      await shareDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final out = p.join(shareDir.path, 'timeplace_$ts.png');
    await File(out).writeAsBytes(bytes, flush: true);
    return out;
  }

  static Future<String> _save(
    Uint8List bytes,
    String dirName,
    String extension,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final capturesDir = Directory(p.join(dir.path, 'captures', dirName));
    if (!await capturesDir.exists()) {
      await capturesDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    final out = p.join(capturesDir.path, '$ts.$extension');
    await File(out).writeAsBytes(bytes, flush: true);
    return out;
  }
}

class CaptureThumbnail {
  static Future<String> save(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final thumbsDir = Directory(p.join(dir.path, 'thumbnails'));
    if (!await thumbsDir.exists()) await thumbsDir.create(recursive: true);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final out = p.join(thumbsDir.path, '$ts.jpg');
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // 실패 시 원본을 그대로 (작더라도) 저장
      await File(out).writeAsBytes(bytes, flush: true);
      return out;
    }
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? 360 : null,
      height: decoded.height > decoded.width ? 360 : null,
    );
    await File(
      out,
    ).writeAsBytes(img.encodeJpg(resized, quality: 80), flush: true);
    return out;
  }
}
