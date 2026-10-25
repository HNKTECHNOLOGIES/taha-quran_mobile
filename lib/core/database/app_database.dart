import 'package:flutter/foundation.dart';
import 'platform_io.dart' if (dart.library.html) 'platform_stub.dart' as platform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Accès SQLite unique de l'application.
///
/// Sur le web, [open] retourne `null` : le repository utilise alors
/// un cache mémoire issu des assets (lecture hors ligne toujours possible).
class AppDatabase {
  Database? _db;

  Database? get db => _db;

  bool get isReady => _db != null;

  Future<Database?> open() async {
    if (_db != null) return _db;
    if (kIsWeb) return null;
    // `flutter test` définit FLUTTER_TEST ; éviter les method channels natifs.
    if (platform.isFlutterTest) {
      return null;
    }

    try {
      if (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path = p.join(dir.path, 'quran_mobile.db');

      _db = await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE surahs (
              id INTEGER PRIMARY KEY,
              name_ar TEXT NOT NULL,
              transliteration TEXT NOT NULL,
              revelation_type TEXT NOT NULL,
              verses_count INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE ayahs (
              surah_id INTEGER NOT NULL,
              number INTEGER NOT NULL,
              text_ar TEXT NOT NULL,
              PRIMARY KEY (surah_id, number),
              FOREIGN KEY (surah_id) REFERENCES surahs(id)
            )
          ''');
          await db.execute('''
            CREATE TABLE meta (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL
            )
          ''');
        },
      );
      return _db;
    } catch (_) {
      // Tests / environnements sans plugin natif : fallback mémoire.
      return null;
    }
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
