import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/core/constants/quran_constants.dart';
import 'package:quran_mobile/core/database/app_database.dart';
import 'package:quran_mobile/features/surahs/data/datasources/quran_asset_datasource.dart';
import 'package:quran_mobile/features/surahs/data/repositories/quran_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late QuranRepositoryImpl repository;

  setUp(() async {
    repository = QuranRepositoryImpl(
      database: AppDatabase(),
      assetDataSource: QuranAssetDataSource(),
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

  test('intégrité — total 6236 versets', () async {
    final surahs = await repository.getSurahs();
    var total = 0;
    for (final s in surahs) {
      final detail = await repository.getSurah(s.id);
      total += detail.ayahs.length;
    }
    expect(total, QuranConstants.verseCount);
  });
}
