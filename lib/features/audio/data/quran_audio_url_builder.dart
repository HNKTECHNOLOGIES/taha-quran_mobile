import '../domain/entities/reciter.dart';

/// Construit des URLs everyayah.com **par verset** (pas de sourate complète).
class QuranAudioUrlBuilder {
  const QuranAudioUrlBuilder();

  static const baseUrl = 'https://everyayah.com/data';

  /// `https://everyayah.com/data/{folder}/{SSS}{AAA}.mp3`
  Uri verseUri({
    required Reciter reciter,
    required int surahId,
    required int ayahNumber,
  }) {
    if (surahId < 1 || surahId > 114) {
      throw ArgumentError.value(surahId, 'surahId');
    }
    if (ayahNumber < 1) {
      throw ArgumentError.value(ayahNumber, 'ayahNumber');
    }
    final sss = surahId.toString().padLeft(3, '0');
    final aaa = ayahNumber.toString().padLeft(3, '0');
    return Uri.parse(
      '$baseUrl/${reciter.everyAyahFolder}/$sss$aaa.mp3',
    );
  }

  List<Uri> surahPlaylist({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) {
    return [
      for (var a = 1; a <= verseCount; a++)
        verseUri(reciter: reciter, surahId: surahId, ayahNumber: a),
    ];
  }
}
