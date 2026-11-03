/// Passage de tafsir associé à une plage d’ayahs (éventuellement 1 seul).
class TafsirPassage {
  const TafsirPassage({
    required this.surahId,
    required this.startAyah,
    required this.endAyah,
    required this.textAr,
    required this.commentatorAr,
    required this.workAr,
  });

  final int surahId;
  final int startAyah;
  final int endAyah;
  final String textAr;
  final String commentatorAr;
  final String workAr;

  bool get isMultiAyah => endAyah > startAyah;

  String get verseRefLabel {
    if (isMultiAyah) return '$surahId:$startAyah–$endAyah';
    return '$surahId:$startAyah';
  }

  bool covers(int ayahNumber) =>
      ayahNumber >= startAyah && ayahNumber <= endAyah;
}

class TafsirEditionInfo {
  const TafsirEditionInfo({
    required this.id,
    required this.commentatorAr,
    required this.commentatorEn,
    required this.workAr,
    required this.attribution,
    required this.license,
    required this.sourceCommit,
  });

  final String id;
  final String commentatorAr;
  final String commentatorEn;
  final String workAr;
  final String attribution;
  final String license;
  final String sourceCommit;
}
