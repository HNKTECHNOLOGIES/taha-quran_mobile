import '../entities/reciter.dart';
import '../entities/surah_download.dart';

/// Contrat du module de téléchargement audio hors-ligne.
abstract class AudioDownloadRepository {
  Stream<Map<String, SurahDownload>> watchDownloads();

  Future<Map<String, SurahDownload>> getDownloads();

  Future<SurahDownload?> getDownload({
    required String reciterId,
    required int surahId,
  });

  /// True si tous les fichiers locaux de la sourate sont présents.
  Future<bool> isSurahDownloaded({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  });

  /// Chemins locaux (playlist) si complets, sinon liste vide.
  Future<List<Uri>> localPlaylistUris({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  });

  Future<void> downloadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  });

  Future<void> cancelDownload({
    required String reciterId,
    required int surahId,
  });

  Future<void> deleteDownload({
    required Reciter reciter,
    required int surahId,
  });

  Future<bool> getWifiOnly();

  Future<void> setWifiOnly(bool value);

  Future<bool> isWifiConnected();
}
