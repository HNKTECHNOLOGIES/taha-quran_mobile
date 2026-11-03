import '../domain/entities/reciter.dart';

/// Catalogue configurable — sources audio vérifiées (HTTP 200).
class ReciterCatalog {
  ReciterCatalog._();

  static const everyAyahAttribution = 'Audio : everyayah.com';
  static const mp3QuranAttribution = 'Audio : mp3quran.net';

  /// Alias d’attribution historique (lecteur compact / paramètres).
  static const attribution = everyAyahAttribution;

  static const Reciter alafasy = Reciter(
    id: 'alafasy',
    nameEn: 'Mishary Rashid Alafasy',
    nameAr: 'مشاري راشد العفاسي',
    mode: ReciterAudioMode.verseByVerse,
    everyAyahFolder: 'Alafasy_128kbps',
    bitrateLabel: '128 kbps',
    sourceAttribution: everyAyahAttribution,
  );

  static const Reciter abdulBasit = Reciter(
    id: 'abdul_basit_murattal',
    nameEn: 'Abdul Basit Abdus Samad',
    nameAr: 'عبد الباسط عبد الصمد',
    mode: ReciterAudioMode.verseByVerse,
    everyAyahFolder: 'Abdul_Basit_Murattal_192kbps',
    bitrateLabel: '192 kbps',
    sourceAttribution: everyAyahAttribution,
  );

  static const Reciter maher = Reciter(
    id: 'maher_almuaiqly',
    nameEn: 'Maher Al-Muaiqly',
    nameAr: 'ماهر المعيقلي',
    mode: ReciterAudioMode.verseByVerse,
    everyAyahFolder: 'MaherAlMuaiqly128kbps',
    bitrateLabel: '128 kbps',
    sourceAttribution: everyAyahAttribution,
  );

  /// Badr Touarique (Badr bin Mohammad Al-Turki) — sourates complètes mp3quran.
  /// Pas de fichiers verse-par-verset confirmés sur everyayah.com.
  static const Reciter badrTouarique = Reciter(
    id: 'badr_touarique',
    nameEn: 'Badr Touarique',
    nameAr: 'بدر بن محمد التركي',
    mode: ReciterAudioMode.fullSurah,
    surahServerBaseUrl: 'https://cdn.mp3quran.net/audio/badr-turki/r1/',
    bitrateLabel: 'sourate',
    sourceAttribution: mp3QuranAttribution,
  );

  static const List<Reciter> all = [
    alafasy,
    abdulBasit,
    maher,
    badrTouarique,
  ];

  static Reciter byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => alafasy);
}
