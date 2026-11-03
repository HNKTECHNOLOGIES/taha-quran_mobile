import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/core/constants/quran_constants.dart';
import 'package:quran_mobile/features/tafsir/data/datasources/ibn_kathir_asset_datasource.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IbnKathirAssetDataSource ds;

  setUp(() {
    ds = IbnKathirAssetDataSource();
  });

  test('manifest Ibn Kathir — métadonnées et couverture', () async {
    final info = await ds.loadInfo();
    expect(info.id, 'ibn_kathir_ar');
    expect(info.commentatorAr, contains('ابن كثير'));
    expect(info.workAr, contains('تفسير'));
    expect(info.license, 'public-domain');
    expect(info.sourceCommit, isNotEmpty);
  });

  test('Al-Fatiha — 7 plages, une par ayah, texte non vide', () async {
    final passages = await ds.loadSurah(1);
    expect(passages.length, 7);
    for (var a = 1; a <= 7; a++) {
      final p = ds.findPassage(passages, a);
      expect(p, isNotNull, reason: 'missing tafsir for 1:$a');
      expect(p!.startAyah, a);
      expect(p.endAyah, a);
      expect(p.textAr.trim(), isNotEmpty);
      expect(p.commentatorAr, contains('ابن كثير'));
    }
  });

  test('Al-Baqara — plage multi-ayah 8–9 non découpée', () async {
    final passages = await ds.loadSurah(2);
    expect(
      passages.length,
      lessThan(QuranConstants.versesPerSurah[1]),
      reason: 'des plages multi-ayah sont attendues',
    );

    final p8 = ds.findPassage(passages, 8);
    final p9 = ds.findPassage(passages, 9);
    expect(p8, isNotNull);
    expect(p9, isNotNull);
    expect(identical(p8, p9) || p8!.textAr == p9!.textAr, isTrue);
    expect(p8!.startAyah, 8);
    expect(p8.endAyah, 9);
    expect(p8.isMultiAyah, isTrue);
    expect(p8.verseRefLabel, '2:8–9');

    // Le verset 2 a son propre commentaire (pas celui de 8–9).
    final p2 = ds.findPassage(passages, 2);
    expect(p2, isNotNull);
    expect(p2!.textAr, isNot(p8.textAr));
  });

  test('Al-Ikhlas — commentaire unique couvrant 1–4', () async {
    final passages = await ds.loadSurah(112);
    expect(passages.length, 1);
    final p = passages.single;
    expect(p.startAyah, 1);
    expect(p.endAyah, 4);
    for (var a = 1; a <= 4; a++) {
      expect(ds.findPassage(passages, a), same(p));
    }
  });

  test('114 sourates chargent sans erreur et couvrent tous les ayahs', () async {
    var covered = 0;
    for (var s = 1; s <= QuranConstants.surahCount; s++) {
      final passages = await ds.loadSurah(s);
      final expected = QuranConstants.versesPerSurah[s - 1];
      var ayahs = 0;
      for (final p in passages) {
        expect(p.surahId, s);
        expect(p.endAyah >= p.startAyah, isTrue);
        expect(p.textAr.trim(), isNotEmpty);
        ayahs += p.endAyah - p.startAyah + 1;
      }
      expect(ayahs, expected, reason: 'surah $s coverage');
      covered += ayahs;
    }
    expect(covered, QuranConstants.verseCount);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
