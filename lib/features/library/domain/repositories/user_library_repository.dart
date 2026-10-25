import '../entities/verse_ref.dart';

abstract class UserLibraryRepository {
  Future<void> initialize();

  // --- Favoris ---
  Future<List<FavoriteEntry>> getFavorites();
  Future<bool> isFavorite(VerseRef ref);
  /// Retourne `true` si ajouté, `false` si déjà présent (pas de doublon).
  Future<bool> addFavorite(VerseRef ref);
  Future<void> removeFavorite(VerseRef ref);
  Future<void> toggleFavorite(VerseRef ref);

  // --- Reprise de lecture (position explicite) ---
  Future<ReadingPosition?> getReadingPosition();
  Future<void> markReadingPosition(VerseRef ref);
  Future<void> clearReadingPosition();

  // --- Marque-pages ---
  Future<List<BookmarkEntry>> getBookmarks();
  Future<BookmarkEntry> addBookmark(VerseRef ref, {String? label});
  Future<void> removeBookmark(String id);
}
