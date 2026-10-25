import 'package:flutter/foundation.dart';
import 'platform_io.dart' if (dart.library.html) 'platform_stub.dart' as platform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Accès SQLite unique de l'application.
///
/// Sur le web / tests, [open] retourne `null` : les données Coran restent
/// en assets/mémoire, et la bibliothèque utilisateur bascule sur SharedPreferences.
class AppDatabase {
  Database? _db;

  Database? get db => _db;

  bool get isReady => _db != null;

  Future<Database?> open() async {
    if (_db != null) return _db;
    if (kIsWeb) return null;
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
        version: 2,
        onCreate: (db, version) async {
          await _createQuranTables(db);
          await _createUserLibraryTables(db);
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _createUserLibraryTables(db);
          }
        },
      );
      return _db;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _createQuranTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS surahs (
        id INTEGER PRIMARY KEY,
        name_ar TEXT NOT NULL,
        transliteration TEXT NOT NULL,
        revelation_type TEXT NOT NULL,
        verses_count INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ayahs (
        surah_id INTEGER NOT NULL,
        number INTEGER NOT NULL,
        text_ar TEXT NOT NULL,
        PRIMARY KEY (surah_id, number),
        FOREIGN KEY (surah_id) REFERENCES surahs(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  static Future<void> _createUserLibraryTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at_ms INTEGER NOT NULL,
        PRIMARY KEY (surah_id, ayah_number)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bookmarks (
        id TEXT PRIMARY KEY,
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        created_at_ms INTEGER NOT NULL,
        label TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS reading_position (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        surah_id INTEGER NOT NULL,
        ayah_number INTEGER NOT NULL,
        updated_at_ms INTEGER NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
