import '../domain/entities/reciter.dart';

/// Catalogue configurable — dossiers everyayah.com vérifiés (HTTP 200).
class ReciterCatalog {
  ReciterCatalog._();

  static const attribution = 'Audio : everyayah.com';

  static const Reciter alafasy = Reciter(
    id: 'alafasy',
    nameEn: 'Mishary Rashid Alafasy',
    nameAr: 'مشاري راشد العفاسي',
    everyAyahFolder: 'Alafasy_128kbps',
    bitrateLabel: '128 kbps',
    sourceAttribution: attribution,
  );

  static const Reciter abdulBasit = Reciter(
    id: 'abdul_basit_murattal',
    nameEn: 'Abdul Basit Abdus Samad',
    nameAr: 'عبد الباسط عبد الصمد',
    everyAyahFolder: 'Abdul_Basit_Murattal_192kbps',
    bitrateLabel: '192 kbps',
    sourceAttribution: attribution,
  );

  static const Reciter maher = Reciter(
    id: 'maher_almuaiqly',
    nameEn: 'Maher Al-Muaiqly',
    nameAr: 'ماهر المعيقلي',
    everyAyahFolder: 'MaherAlMuaiqly128kbps',
    bitrateLabel: '128 kbps',
    sourceAttribution: attribution,
  );

  static const List<Reciter> all = [alafasy, abdulBasit, maher];

  static Reciter byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => alafasy);
}
