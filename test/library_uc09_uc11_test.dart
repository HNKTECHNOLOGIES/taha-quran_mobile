import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/features/library/data/datasources/user_library_local_datasource.dart';
import 'package:quran_mobile/features/library/data/repositories/user_library_repository_impl.dart';
import 'package:quran_mobile/features/library/domain/entities/verse_ref.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late UserLibraryRepositoryImpl library;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    library = UserLibraryRepositoryImpl(
      dataSource: UserLibraryLocalDataSource(),
    );
    await library.initialize();
  });

  test('UC09 — ajouter / supprimer favori sans doublon', () async {
    const verse = VerseRef(surahId: 1, ayahNumber: 2);

    expect(await library.isFavorite(verse), isFalse);
    expect(await library.addFavorite(verse), isTrue);
    expect(await library.addFavorite(verse), isFalse); // doublon
    expect(await library.isFavorite(verse), isTrue);

    final favorites = await library.getFavorites();
    expect(favorites.length, 1);
    expect(favorites.first.ref, verse);

    await library.removeFavorite(verse);
    expect(await library.isFavorite(verse), isFalse);
    expect(await library.getFavorites(), isEmpty);
  });

  test('UC10 — marquer et restaurer la position de lecture', () async {
    expect(await library.getReadingPosition(), isNull);

    const pos = VerseRef(surahId: 2, ayahNumber: 255);
    await library.markReadingPosition(pos);

    final saved = await library.getReadingPosition();
    expect(saved, isNotNull);
    expect(saved!.ref.surahId, 2);
    expect(saved.ref.ayahNumber, 255);

    // Nouvelle instance = redémarrage (même SharedPreferences mock)
    final library2 = UserLibraryRepositoryImpl(
      dataSource: UserLibraryLocalDataSource(),
    );
    await library2.initialize();
    final restored = await library2.getReadingPosition();
    expect(restored?.ref, pos);
  });

  test('UC11 — créer et supprimer plusieurs marque-pages', () async {
    const a = VerseRef(surahId: 36, ayahNumber: 1);
    const b = VerseRef(surahId: 67, ayahNumber: 1);

    final bm1 = await library.addBookmark(a);
    final bm2 = await library.addBookmark(b);
    expect(bm1.id, isNot(bm2.id));

    var list = await library.getBookmarks();
    expect(list.length, 2);

    await library.removeBookmark(bm1.id);
    list = await library.getBookmarks();
    expect(list.length, 1);
    expect(list.first.ref, b);
  });

  test('toggle favori', () async {
    const verse = VerseRef(surahId: 112, ayahNumber: 1);
    await library.toggleFavorite(verse);
    expect(await library.isFavorite(verse), isTrue);
    await library.toggleFavorite(verse);
    expect(await library.isFavorite(verse), isFalse);
  });
}
