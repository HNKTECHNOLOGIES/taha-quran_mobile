import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../domain/entities/verse_ref.dart';
import '../../domain/repositories/user_library_repository.dart';
import '../datasources/user_library_local_datasource.dart';

class UserLibraryRepositoryImpl implements UserLibraryRepository {
  UserLibraryRepositoryImpl({required this.dataSource});

  final UserLibraryLocalDataSource dataSource;
  bool _ready = false;

  @override
  Future<void> initialize() async {
    if (_ready) return;
    await dataSource.initialize();
    _ready = true;
  }

  Future<void> bindDatabase(Database? database) async {
    await dataSource.initialize(database: database);
    _ready = true;
  }

  Future<void> _ensure() async {
    if (!_ready) await initialize();
  }

  @override
  Future<List<FavoriteEntry>> getFavorites() async {
    await _ensure();
    return dataSource.getFavorites();
  }

  @override
  Future<bool> isFavorite(VerseRef ref) async {
    await _ensure();
    return dataSource.isFavorite(ref);
  }

  @override
  Future<bool> addFavorite(VerseRef ref) async {
    await _ensure();
    return dataSource.addFavorite(ref);
  }

  @override
  Future<void> removeFavorite(VerseRef ref) async {
    await _ensure();
    await dataSource.removeFavorite(ref);
  }

  @override
  Future<void> toggleFavorite(VerseRef ref) async {
    await _ensure();
    if (await dataSource.isFavorite(ref)) {
      await dataSource.removeFavorite(ref);
    } else {
      await dataSource.addFavorite(ref);
    }
  }

  @override
  Future<ReadingPosition?> getReadingPosition() async {
    await _ensure();
    return dataSource.getReadingPosition();
  }

  @override
  Future<void> markReadingPosition(VerseRef ref) async {
    await _ensure();
    await dataSource.markReadingPosition(ref);
  }

  @override
  Future<void> clearReadingPosition() async {
    await _ensure();
    await dataSource.clearReadingPosition();
  }

  @override
  Future<List<BookmarkEntry>> getBookmarks() async {
    await _ensure();
    return dataSource.getBookmarks();
  }

  @override
  Future<BookmarkEntry> addBookmark(VerseRef ref, {String? label}) async {
    await _ensure();
    return dataSource.addBookmark(ref, label: label);
  }

  @override
  Future<void> removeBookmark(String id) async {
    await _ensure();
    await dataSource.removeBookmark(id);
  }
}
