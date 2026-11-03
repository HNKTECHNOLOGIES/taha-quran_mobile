import '../entities/tafsir_passage.dart';

abstract class TafsirRepository {
  Future<TafsirEditionInfo> getIbnKathirInfo();

  /// Charge (et met en cache) le tafsir Ibn Kathir pour une sourate.
  Future<List<TafsirPassage>> getIbnKathirSurah(int surahId);

  /// Passage couvrant [ayahNumber], ou `null` si indisponible.
  Future<TafsirPassage?> getIbnKathirPassage({
    required int surahId,
    required int ayahNumber,
  });
}
