import 'package:flutter/material.dart';

enum AppLanguage { french, arabic }

class AppStrings {
  const AppStrings._(this.language);

  final AppLanguage language;

  static const AppStrings fr = AppStrings._(AppLanguage.french);
  static const AppStrings ar = AppStrings._(AppLanguage.arabic);

  bool get isRtl => language == AppLanguage.arabic;
  Locale get locale =>
      language == AppLanguage.arabic ? const Locale('ar') : const Locale('fr');

  String get appName =>
      language == AppLanguage.arabic ? 'القرآن الكريم' : 'Le Saint Coran';

  String get home => language == AppLanguage.arabic ? 'الرئيسية' : 'Accueil';
  String get surahs =>
      language == AppLanguage.arabic ? 'السور' : 'Sourates';
  String get favorites =>
      language == AppLanguage.arabic ? 'المفضلة' : 'Favoris';
  String get search =>
      language == AppLanguage.arabic ? 'بحث' : 'Recherche';
  String get audio => language == AppLanguage.arabic ? 'تلاوة' : 'Audio';
  String get settings =>
      language == AppLanguage.arabic ? 'الإعدادات' : 'Paramètres';

  String get welcomeTitle =>
      language == AppLanguage.arabic ? 'القرآن الكريم' : 'Le Saint Coran';

  String get welcomeSubtitle => language == AppLanguage.arabic
      ? 'اقرأ القرآن دون اتصال'
      : 'Lisez le Coran hors connexion';

  String get browseSurahs => language == AppLanguage.arabic
      ? 'تصفح السور'
      : 'Parcourir les sourates';

  String get continueReading => language == AppLanguage.arabic
      ? 'متابعة القراءة'
      : 'Continuer ma lecture';

  String get continueReadingHint => language == AppLanguage.arabic
      ? 'ستتوفر قريباً'
      : 'Bientôt disponible';

  String get verses => language == AppLanguage.arabic ? 'آيات' : 'versets';

  String get meccan =>
      language == AppLanguage.arabic ? 'مكية' : 'Mecquoise';
  String get medinan =>
      language == AppLanguage.arabic ? 'مدنية' : 'Médinoise';

  String get loading =>
      language == AppLanguage.arabic ? 'جاري التحميل…' : 'Chargement…';

  String get errorTitle =>
      language == AppLanguage.arabic ? 'خطأ' : 'Erreur';

  String get retry =>
      language == AppLanguage.arabic ? 'إعادة المحاولة' : 'Réessayer';

  String get comingSoon =>
      language == AppLanguage.arabic ? 'قريباً' : 'Bientôt disponible';

  String get offlineBadge => language == AppLanguage.arabic
      ? 'متاح دون اتصال'
      : 'Disponible hors ligne';

  String get showTranslation => language == AppLanguage.arabic
      ? 'إظهار الترجمة'
      : 'Afficher la traduction';

  String get hideTranslation => language == AppLanguage.arabic
      ? 'إخفاء الترجمة'
      : 'Masquer la traduction';

  String get previousSurah =>
      language == AppLanguage.arabic ? 'السابقة' : 'Précédente';

  String get nextSurah =>
      language == AppLanguage.arabic ? 'التالية' : 'Suivante';

  String get translationCredit => language == AppLanguage.arabic
      ? 'ترجمة al-quran.fr'
      : 'Traduction al-quran.fr';

  String get translationSection =>
      language == AppLanguage.arabic ? 'الترجمة' : 'Traduction';

  String get translationVisible => language == AppLanguage.arabic
      ? 'الترجمة ظاهرة تحت الآيات'
      : 'Traduction visible sous les versets';

  String get translationHidden => language == AppLanguage.arabic
      ? 'الترجمة مخفية'
      : 'Traduction masquée';

  String get translationFontSize => language == AppLanguage.arabic
      ? 'حجم نص الترجمة'
      : 'Taille de la traduction';

  String get aboutTranslation => language == AppLanguage.arabic
      ? 'حول الترجمة'
      : 'À propos de la traduction';

  String get editionLabel =>
      language == AppLanguage.arabic ? 'الطبعة' : 'Édition';

  String get licenseLabel =>
      language == AppLanguage.arabic ? 'الرخصة' : 'Licence';

  String get noTranslationInstalled => language == AppLanguage.arabic
      ? 'لا توجد ترجمة محلية مثبتة'
      : 'Aucune traduction locale installée';

  String revelationLabel(String type) {
    final t = type.toLowerCase();
    if (t.contains('medin')) return medinan;
    return meccan;
  }

  String verseCountLabel(int count) => '$count $verses';
}
