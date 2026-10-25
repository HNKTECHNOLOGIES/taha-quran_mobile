/// Récitateur configurable (fichiers audio par verset).
class Reciter {
  const Reciter({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.everyAyahFolder,
    required this.bitrateLabel,
    required this.sourceAttribution,
  });

  final String id;
  final String nameEn;
  final String nameAr;

  /// Dossier vérifié sur everyayah.com/data/
  final String everyAyahFolder;
  final String bitrateLabel;
  final String sourceAttribution;
}
