import 'ayah.dart';

class Surah {
  const Surah({
    required this.id,
    required this.nameAr,
    required this.transliteration,
    required this.revelationType,
    required this.versesCount,
    this.ayahs = const [],
  });

  final int id;
  final String nameAr;
  final String transliteration;
  final String revelationType;
  final int versesCount;
  final List<Ayah> ayahs;

  Surah copyWith({List<Ayah>? ayahs}) {
    return Surah(
      id: id,
      nameAr: nameAr,
      transliteration: transliteration,
      revelationType: revelationType,
      versesCount: versesCount,
      ayahs: ayahs ?? this.ayahs,
    );
  }
}
