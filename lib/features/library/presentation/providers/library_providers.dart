import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../surahs/domain/entities/ayah.dart';
import '../../../surahs/domain/entities/surah.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../../data/datasources/user_library_local_datasource.dart';
import '../../data/repositories/user_library_repository_impl.dart';
import '../../domain/entities/verse_ref.dart';
import '../../domain/repositories/user_library_repository.dart';

final userLibraryDataSourceProvider = Provider<UserLibraryLocalDataSource>((ref) {
  return UserLibraryLocalDataSource();
});

final userLibraryRepositoryProvider = Provider<UserLibraryRepository>((ref) {
  final repo = UserLibraryRepositoryImpl(
    dataSource: ref.watch(userLibraryDataSourceProvider),
  );
  return repo;
});

final userLibraryBootstrapProvider = FutureProvider<UserLibraryRepository>((ref) async {
  final repo = ref.watch(userLibraryRepositoryProvider) as UserLibraryRepositoryImpl;
  final db = await ref.watch(appDatabaseProvider).open();
  await repo.bindDatabase(db);
  return repo;
});

final favoritesProvider = FutureProvider<List<FavoriteEntry>>((ref) async {
  final repo = await ref.watch(userLibraryBootstrapProvider.future);
  return repo.getFavorites();
});

final bookmarksProvider = FutureProvider<List<BookmarkEntry>>((ref) async {
  final repo = await ref.watch(userLibraryBootstrapProvider.future);
  return repo.getBookmarks();
});

final readingPositionProvider = FutureProvider<ReadingPosition?>((ref) async {
  final repo = await ref.watch(userLibraryBootstrapProvider.future);
  return repo.getReadingPosition();
});

final isFavoriteProvider =
    FutureProvider.family<bool, VerseRef>((ref, verse) async {
  final repo = await ref.watch(userLibraryBootstrapProvider.future);
  return repo.isFavorite(verse);
});

/// Favori enrichi avec métadonnées sourate + texte (chargé à la volée).
class FavoriteDisplay {
  const FavoriteDisplay({
    required this.entry,
    required this.surah,
    required this.ayah,
  });

  final FavoriteEntry entry;
  final Surah surah;
  final Ayah ayah;
}

final favoriteDisplaysProvider =
    FutureProvider<List<FavoriteDisplay>>((ref) async {
  final favorites = await ref.watch(favoritesProvider.future);
  final quran = ref.watch(quranRepositoryProvider);
  await quran.initialize();

  final result = <FavoriteDisplay>[];
  for (final fav in favorites) {
    final surah = await quran.getSurah(fav.ref.surahId);
    final ayah = surah.ayahs.firstWhere((a) => a.number == fav.ref.ayahNumber);
    result.add(
      FavoriteDisplay(
        entry: fav,
        surah: Surah(
          id: surah.id,
          nameAr: surah.nameAr,
          transliteration: surah.transliteration,
          revelationType: surah.revelationType,
          versesCount: surah.versesCount,
        ),
        ayah: ayah,
      ),
    );
  }
  return result;
});

class BookmarkDisplay {
  const BookmarkDisplay({
    required this.entry,
    required this.surah,
    required this.ayah,
  });

  final BookmarkEntry entry;
  final Surah surah;
  final Ayah ayah;
}

final bookmarkDisplaysProvider =
    FutureProvider<List<BookmarkDisplay>>((ref) async {
  final bookmarks = await ref.watch(bookmarksProvider.future);
  final quran = ref.watch(quranRepositoryProvider);
  await quran.initialize();

  final result = <BookmarkDisplay>[];
  for (final bm in bookmarks) {
    final surah = await quran.getSurah(bm.ref.surahId);
    final ayah = surah.ayahs.firstWhere((a) => a.number == bm.ref.ayahNumber);
    result.add(
      BookmarkDisplay(
        entry: bm,
        surah: Surah(
          id: surah.id,
          nameAr: surah.nameAr,
          transliteration: surah.transliteration,
          revelationType: surah.revelationType,
          versesCount: surah.versesCount,
        ),
        ayah: ayah,
      ),
    );
  }
  return result;
});

final libraryActionsProvider = Provider<LibraryActions>((ref) {
  return LibraryActions(ref);
});

class LibraryActions {
  LibraryActions(this._ref);

  final Ref _ref;

  UserLibraryRepository get _repo => _ref.read(userLibraryRepositoryProvider);

  Future<void> _ready() async {
    await _ref.read(userLibraryBootstrapProvider.future);
  }

  Future<void> toggleFavorite(VerseRef ref) async {
    await _ready();
    await _repo.toggleFavorite(ref);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(favoriteDisplaysProvider);
    _ref.invalidate(isFavoriteProvider(ref));
  }

  Future<void> addBookmark(VerseRef ref, {String? label}) async {
    await _ready();
    await _repo.addBookmark(ref, label: label);
    _ref.invalidate(bookmarksProvider);
    _ref.invalidate(bookmarkDisplaysProvider);
  }

  Future<void> removeBookmark(String id) async {
    await _ready();
    await _repo.removeBookmark(id);
    _ref.invalidate(bookmarksProvider);
    _ref.invalidate(bookmarkDisplaysProvider);
  }

  Future<void> removeFavorite(VerseRef ref) async {
    await _ready();
    await _repo.removeFavorite(ref);
    _ref.invalidate(favoritesProvider);
    _ref.invalidate(favoriteDisplaysProvider);
    _ref.invalidate(isFavoriteProvider(ref));
  }

  Future<void> markReadingPosition(VerseRef ref) async {
    await _ready();
    await _repo.markReadingPosition(ref);
    _ref.invalidate(readingPositionProvider);
  }
}
