import '../domain/entities/reciter.dart';
import '../domain/repositories/audio_download_repository.dart';
import 'quran_audio_url_builder.dart';

/// Résout une playlist : fichiers locaux si complets, sinon URLs réseau.
class LocalAudioSourceResolver {
  const LocalAudioSourceResolver({
    required this.downloads,
    this.urlBuilder = const QuranAudioUrlBuilder(),
  });

  final AudioDownloadRepository downloads;
  final QuranAudioUrlBuilder urlBuilder;

  Future<List<Uri>> resolvePlaylist({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    final local = await downloads.localPlaylistUris(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    );
    if (local.isNotEmpty) return local;
    return urlBuilder.surahPlaylist(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    );
  }
}
