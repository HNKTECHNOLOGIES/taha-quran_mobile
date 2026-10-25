class Ayah {
  const Ayah({
    required this.surahId,
    required this.number,
    required this.textAr,
    this.textFr,
  });

  final int surahId;
  final int number;
  final String textAr;

  /// Traduction française (Hamidullah), séparée du texte arabe.
  final String? textFr;

  Ayah copyWith({String? textFr}) {
    return Ayah(
      surahId: surahId,
      number: number,
      textAr: textAr,
      textFr: textFr ?? this.textFr,
    );
  }
}
