import '../domain/entities/reciter.dart';

/// Construit des URLs audio vérifiées (verset ou sourate complète).
class QuranAudioUrlBuilder {
  const QuranAudioUrlBuilder();

  static const everyAyahBaseUrl = 'https://everyayah.com/data';

  /// `https://everyayah.com/data/{folder}/{SSS}{AAA}.mp3`
  Uri verseUri({
    required Reciter reciter,
    required int surahId,
    required int ayahNumber,
  }) {
    if (reciter.mode != ReciterAudioMode.verseByVerse) {
      throw StateError(
        'verseUri réservé au mode verseByVerse (${reciter.id})',
      );
    }
    final folder = reciter.everyAyahFolder!;
    if (surahId < 1 || surahId > 114) {
      throw ArgumentError.value(surahId, 'surahId');
    }
    if (ayahNumber < 1) {
      throw ArgumentError.value(ayahNumber, 'ayahNumber');
    }
    final sss = surahId.toString().padLeft(3, '0');
    final aaa = ayahNumber.toString().padLeft(3, '0');
    return Uri.parse('$everyAyahBaseUrl/$folder/$sss$aaa.mp3');
  }

  /// `https://cdn.mp3quran.net/audio/.../r1/{SSS}.mp3`
  Uri surahUri({
    required Reciter reciter,
    required int surahId,
  }) {
    if (reciter.mode != ReciterAudioMode.fullSurah) {
      throw StateError(
        'surahUri réservé au mode fullSurah (${reciter.id})',
      );
    }
    if (surahId < 1 || surahId > 114) {
      throw ArgumentError.value(surahId, 'surahId');
    }
    final base = reciter.surahServerBaseUrl!;
    final normalized = base.endsWith('/') ? base : '$base/';
    final sss = surahId.toString().padLeft(3, '0');
    return Uri.parse('$normalized$sss.mp3');
  }

  /// Playlist chargée par le lecteur : N fichiers (versets) ou 1 fichier (sourate).
  List<Uri> surahPlaylist({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) {
    if (reciter.mode == ReciterAudioMode.fullSurah) {
      return [surahUri(reciter: reciter, surahId: surahId)];
    }
    return [
      for (var a = 1; a <= verseCount; a++)
        verseUri(reciter: reciter, surahId: surahId, ayahNumber: a),
    ];
  }
}
