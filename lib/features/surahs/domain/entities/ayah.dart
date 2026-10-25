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

  /// Traduction FR locale si disponible ; `null` si absente (jamais inventée).
  final String? textFr;

  Ayah copyWith({String? textFr, bool clearTextFr = false}) {
    return Ayah(
      surahId: surahId,
      number: number,
      textAr: textAr,
      textFr: clearTextFr ? null : (textFr ?? this.textFr),
    );
  }
}
