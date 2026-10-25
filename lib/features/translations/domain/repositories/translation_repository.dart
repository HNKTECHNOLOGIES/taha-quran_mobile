import '../entities/ayah_translation.dart';

abstract class TranslationRepository {
  Future<void> initialize();

  /// `true` si un fichier de traduction FR local valide est disponible.
  bool get hasFrenchTranslation;

  TranslationInfo? get frenchInfo;

  /// Retourne la traduction, ou `null` si absente — jamais de texte inventé.
  Future<AyahTranslation?> getFrenchTranslation({
    required int surahId,
    required int ayahNumber,
  });

  /// Toutes les traductions FR d'une sourate (trous possibles = absentes).
  Future<Map<int, AyahTranslation>> getFrenchForSurah(int surahId);
}
