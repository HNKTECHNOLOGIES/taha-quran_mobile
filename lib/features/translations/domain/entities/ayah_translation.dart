/// Traduction d'un verset, distincte du texte arabe.
class AyahTranslation {
  const AyahTranslation({
    required this.surahId,
    required this.ayahNumber,
    required this.text,
    required this.languageCode,
  });

  final int surahId;
  final int ayahNumber;
  final String text;
  final String languageCode;
}

/// Métadonnées de la traduction installée (attribution / licence).
class TranslationInfo {
  const TranslationInfo({
    required this.languageCode,
    required this.translator,
    required this.edition,
    required this.license,
    required this.licenseUrl,
    required this.attribution,
    required this.sourceUrl,
  });

  final String languageCode;
  final String translator;
  final String edition;
  final String license;
  final String licenseUrl;
  final String attribution;
  final String sourceUrl;
}
