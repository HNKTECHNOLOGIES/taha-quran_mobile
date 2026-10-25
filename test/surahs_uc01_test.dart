import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/core/constants/quran_constants.dart';
import 'package:quran_mobile/core/database/app_database.dart';
import 'package:quran_mobile/features/surahs/data/datasources/quran_asset_datasource.dart';
import 'package:quran_mobile/features/surahs/data/repositories/quran_repository_impl.dart';
import 'package:quran_mobile/features/translations/data/datasources/translation_asset_datasource.dart';
import 'package:quran_mobile/features/translations/data/repositories/translation_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepositoryImpl repository;
  late TranslationRepositoryImpl translations;

  setUp(() async {
    translations = TranslationRepositoryImpl(
      assetDataSource: TranslationAssetDataSource(),
    );
    repository = QuranRepositoryImpl(
      database: AppDatabase(),
      assetDataSource: QuranAssetDataSource(),
      translationRepository: translations,
    );
    await repository.initialize();
  });

  test('UC01 — 114 sourates dans l’ordre canonique', () async {
    final surahs = await repository.getSurahs();

    expect(surahs.length, QuranConstants.surahCount);
    expect(surahs.first.id, 1);
    expect(surahs.first.nameAr, 'الفاتحة');
    expect(surahs.first.transliteration, 'Al-Fatihah');
    expect(surahs.first.versesCount, 7);
    expect(surahs.last.id, 114);
    expect(surahs.last.nameAr, 'الناس');

    for (var i = 0; i < surahs.length; i++) {
      expect(surahs[i].id, i + 1);
      expect(surahs[i].versesCount, QuranConstants.versesPerSurah[i]);
      expect(surahs[i].nameAr.trim(), isNotEmpty);
      expect(surahs[i].transliteration.trim(), isNotEmpty);
    }
  });

  test('UC02 — lecture hors ligne des versets d’une sourate', () async {
    final fatiha = await repository.getSurah(1);
    expect(fatiha.ayahs.length, 7);
    expect(fatiha.ayahs.first.number, 1);
    expect(fatiha.ayahs.first.textAr, contains('ٱللَّهِ'));
    expect(fatiha.ayahs.last.number, 7);

    final ikhlas = await repository.getSurah(112);
    expect(ikhlas.ayahs.length, 4);
    expect(ikhlas.ayahs.map((a) => a.number).toList(), [1, 2, 3, 4]);
    for (final ayah in ikhlas.ayahs) {
      expect(ayah.textAr.trim(), isNotEmpty);
    }
  });

  test('UC03 — correspondance AR/FR locale (al-quran.fr CC BY 4.0)', () async {
    expect(translations.hasFrenchTranslation, isTrue);
    expect(translations.frenchInfo?.translator, 'al-quran.fr');
    expect(translations.frenchInfo?.license, contains('CC BY'));

    final fatiha = await repository.getSurah(1);
    expect(fatiha.ayahs.first.textFr, isNotNull);
    expect(fatiha.ayahs.first.textFr, contains('Dieu'));
    // Texte arabe non modifié / non remplacé
    expect(fatiha.ayahs.first.textAr, isNot(contains('Dieu')));

    for (final ayah in fatiha.ayahs) {
      expect(ayah.textFr?.trim(), isNotEmpty);
    }
  });

  test('intégrité — 6236 versets arabes + FR alignés, hors ligne', () async {
    final surahs = await repository.getSurahs();
    var totalAr = 0;
    var totalFr = 0;
    for (final s in surahs) {
      final detail = await repository.getSurah(s.id);
      expect(detail.ayahs.length, s.versesCount);
      totalAr += detail.ayahs.length;
      for (final a in detail.ayahs) {
        expect(a.textAr.trim(), isNotEmpty);
        if ((a.textFr ?? '').isNotEmpty) totalFr++;
      }
    }
    expect(totalAr, QuranConstants.verseCount);
    expect(totalFr, QuranConstants.verseCount);
  });

  test('traduction absente → null, jamais inventée', () async {
    final missing = await translations.getFrenchTranslation(
      surahId: 1,
      ayahNumber: 999,
    );
    expect(missing, isNull);
  });
}
