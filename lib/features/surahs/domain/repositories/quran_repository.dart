import '../entities/ayah.dart';
import '../entities/surah.dart';

abstract class QuranRepository {
  /// Initialise le stockage local et vérifie l'intégrité des assets.
  Future<void> initialize();

  Future<List<Surah>> getSurahs();

  Future<Surah> getSurah(int surahId);

  Future<List<Ayah>> getAyahs(int surahId);
}
