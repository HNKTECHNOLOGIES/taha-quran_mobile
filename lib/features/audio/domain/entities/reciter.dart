/// Mode d’accès aux fichiers audio du récitateur.
enum ReciterAudioMode {
  /// Un fichier MP3 par verset (everyayah.com) — sync verset exacte.
  verseByVerse,

  /// Un fichier MP3 par sourate (ex. mp3quran.net) — pas de sync verset
  /// sans données de minutage.
  fullSurah,
}

/// Récitateur configurable.
class Reciter {
  const Reciter({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.mode,
    required this.bitrateLabel,
    required this.sourceAttribution,
    this.everyAyahFolder,
    this.surahServerBaseUrl,
  }) : assert(
          mode == ReciterAudioMode.verseByVerse
              ? everyAyahFolder != null
              : surahServerBaseUrl != null,
          'Source audio manquante pour le mode du récitateur',
        );

  final String id;
  final String nameEn;
  final String nameAr;
  final ReciterAudioMode mode;

  /// Dossier vérifié sur everyayah.com/data/ (mode [ReciterAudioMode.verseByVerse]).
  final String? everyAyahFolder;

  /// Base URL mp3quran (mode [ReciterAudioMode.fullSurah]), ex.
  /// `https://cdn.mp3quran.net/audio/badr-turki/r1/`
  final String? surahServerBaseUrl;

  final String bitrateLabel;
  final String sourceAttribution;

  bool get supportsVerseSync => mode == ReciterAudioMode.verseByVerse;
}
