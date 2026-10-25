import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/entities/verse_ref.dart';

/// Persistance locale : SQLite si disponible, sinon SharedPreferences.
class UserLibraryLocalDataSource {
  UserLibraryLocalDataSource();

  Database? _db;
  SharedPreferences? _prefs;

  static const _kFavorites = 'user_favorites_v1';
  static const _kBookmarks = 'user_bookmarks_v1';
  static const _kResume = 'user_resume_v1';

  Future<void> initialize({Database? database}) async {
    _db = database;
    _prefs = await SharedPreferences.getInstance();
    if (_db != null) {
      await _ensureSqliteTables(_db!);
      await _migratePrefsToSqliteIfNeeded();
    }
  }

  Future<void> _ensureSqliteTables(Database db) async {
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

  Future<void> _migratePrefsToSqliteIfNeeded() async {
    final db = _db;
    final prefs = _prefs;
    if (db == null || prefs == null) return;

    final favCount = (await db.rawQuery('SELECT COUNT(*) AS c FROM favorites'))
            .first['c'] as int? ??
        0;
    if (favCount == 0) {
      for (final e in await _prefsFavorites()) {
        await db.insert(
          'favorites',
          {
            'surah_id': e.ref.surahId,
            'ayah_number': e.ref.ayahNumber,
            'created_at_ms': e.createdAtMs,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }

    final bmCount = (await db.rawQuery('SELECT COUNT(*) AS c FROM bookmarks'))
            .first['c'] as int? ??
        0;
    if (bmCount == 0) {
      for (final e in await _prefsBookmarks()) {
        await db.insert('bookmarks', {
          'id': e.id,
          'surah_id': e.ref.surahId,
          'ayah_number': e.ref.ayahNumber,
          'created_at_ms': e.createdAtMs,
          'label': e.label,
        });
      }
    }

    final posRows = await db.query('reading_position', limit: 1);
    if (posRows.isEmpty) {
      final pos = await _prefsResume();
      if (pos != null) {
        await db.insert('reading_position', {
          'id': 1,
          'surah_id': pos.ref.surahId,
          'ayah_number': pos.ref.ayahNumber,
          'updated_at_ms': pos.updatedAtMs,
        });
      }
    }
  }

  // ---------- Favoris ----------

  Future<List<FavoriteEntry>> getFavorites() async {
    if (_db != null) {
      final rows = await _db!.query('favorites', orderBy: 'created_at_ms DESC');
      return rows
          .map(
            (r) => FavoriteEntry(
              ref: VerseRef(
                surahId: r['surah_id'] as int,
                ayahNumber: r['ayah_number'] as int,
              ),
              createdAtMs: r['created_at_ms'] as int,
            ),
          )
          .toList();
    }
    return _prefsFavorites();
  }

  Future<bool> isFavorite(VerseRef ref) async {
    if (_db != null) {
      final rows = await _db!.query(
        'favorites',
        where: 'surah_id = ? AND ayah_number = ?',
        whereArgs: [ref.surahId, ref.ayahNumber],
        limit: 1,
      );
      return rows.isNotEmpty;
    }
    final list = await _prefsFavorites();
    return list.any((e) => e.ref == ref);
  }

  Future<bool> addFavorite(VerseRef ref) async {
    if (await isFavorite(ref)) return false;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_db != null) {
      await _db!.insert(
        'favorites',
        {
          'surah_id': ref.surahId,
          'ayah_number': ref.ayahNumber,
          'created_at_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    final list = await _prefsFavorites();
    if (list.any((e) => e.ref == ref)) return false;
    list.insert(0, FavoriteEntry(ref: ref, createdAtMs: now));
    await _savePrefsFavorites(list);
    return true;
  }

  Future<void> removeFavorite(VerseRef ref) async {
    if (_db != null) {
      await _db!.delete(
        'favorites',
        where: 'surah_id = ? AND ayah_number = ?',
        whereArgs: [ref.surahId, ref.ayahNumber],
      );
    }
    final list = await _prefsFavorites();
    list.removeWhere((e) => e.ref == ref);
    await _savePrefsFavorites(list);
  }

  // ---------- Resume ----------

  Future<ReadingPosition?> getReadingPosition() async {
    if (_db != null) {
      final rows = await _db!.query('reading_position', limit: 1);
      if (rows.isEmpty) return _prefsResume();
      final r = rows.first;
      return ReadingPosition(
        ref: VerseRef(
          surahId: r['surah_id'] as int,
          ayahNumber: r['ayah_number'] as int,
        ),
        updatedAtMs: r['updated_at_ms'] as int,
      );
    }
    return _prefsResume();
  }

  Future<void> markReadingPosition(VerseRef ref) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_db != null) {
      await _db!.insert(
        'reading_position',
        {
          'id': 1,
          'surah_id': ref.surahId,
          'ayah_number': ref.ayahNumber,
          'updated_at_ms': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await _prefs?.setString(
      _kResume,
      jsonEncode({
        'surah_id': ref.surahId,
        'ayah_number': ref.ayahNumber,
        'updated_at_ms': now,
      }),
    );
  }

  Future<void> clearReadingPosition() async {
    if (_db != null) {
      await _db!.delete('reading_position');
    }
    await _prefs?.remove(_kResume);
  }

  // ---------- Bookmarks ----------

  Future<List<BookmarkEntry>> getBookmarks() async {
    if (_db != null) {
      final rows = await _db!.query('bookmarks', orderBy: 'created_at_ms DESC');
      if (rows.isNotEmpty) {
        return rows
            .map(
              (r) => BookmarkEntry(
                id: r['id'] as String,
                ref: VerseRef(
                  surahId: r['surah_id'] as int,
                  ayahNumber: r['ayah_number'] as int,
                ),
                createdAtMs: r['created_at_ms'] as int,
                label: r['label'] as String?,
              ),
            )
            .toList();
      }
    }
    return _prefsBookmarks();
  }

  Future<BookmarkEntry> addBookmark(VerseRef ref, {String? label}) async {
    final entry = BookmarkEntry(
      id: '${ref.key}-${DateTime.now().microsecondsSinceEpoch}',
      ref: ref,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      label: label,
    );
    if (_db != null) {
      await _db!.insert('bookmarks', {
        'id': entry.id,
        'surah_id': ref.surahId,
        'ayah_number': ref.ayahNumber,
        'created_at_ms': entry.createdAtMs,
        'label': label,
      });
    }
    final list = await _prefsBookmarks();
    list.insert(0, entry);
    await _savePrefsBookmarks(list);
    return entry;
  }

  Future<void> removeBookmark(String id) async {
    if (_db != null) {
      await _db!.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    }
    final list = await _prefsBookmarks();
    list.removeWhere((e) => e.id == id);
    await _savePrefsBookmarks(list);
  }

  // ---------- Prefs helpers ----------

  Future<List<FavoriteEntry>> _prefsFavorites() async {
    final raw = _prefs?.getString(_kFavorites);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => FavoriteEntry(
            ref: VerseRef(
              surahId: e['surah_id'] as int,
              ayahNumber: e['ayah_number'] as int,
            ),
            createdAtMs: e['created_at_ms'] as int,
          ),
        )
        .toList();
  }

  Future<void> _savePrefsFavorites(List<FavoriteEntry> list) async {
    await _prefs?.setString(
      _kFavorites,
      jsonEncode([
        for (final e in list)
          {
            'surah_id': e.ref.surahId,
            'ayah_number': e.ref.ayahNumber,
            'created_at_ms': e.createdAtMs,
          },
      ]),
    );
  }

  Future<List<BookmarkEntry>> _prefsBookmarks() async {
    final raw = _prefs?.getString(_kBookmarks);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map(
          (e) => BookmarkEntry(
            id: e['id'] as String,
            ref: VerseRef(
              surahId: e['surah_id'] as int,
              ayahNumber: e['ayah_number'] as int,
            ),
            createdAtMs: e['created_at_ms'] as int,
            label: e['label'] as String?,
          ),
        )
        .toList();
  }

  Future<void> _savePrefsBookmarks(List<BookmarkEntry> list) async {
    await _prefs?.setString(
      _kBookmarks,
      jsonEncode([
        for (final e in list)
          {
            'id': e.id,
            'surah_id': e.ref.surahId,
            'ayah_number': e.ref.ayahNumber,
            'created_at_ms': e.createdAtMs,
            'label': e.label,
          },
      ]),
    );
  }

  Future<ReadingPosition?> _prefsResume() async {
    final raw = _prefs?.getString(_kResume);
    if (raw == null || raw.isEmpty) return null;
    final e = jsonDecode(raw) as Map<String, dynamic>;
    return ReadingPosition(
      ref: VerseRef(
        surahId: e['surah_id'] as int,
        ayahNumber: e['ayah_number'] as int,
      ),
      updatedAtMs: e['updated_at_ms'] as int,
    );
  }
}
