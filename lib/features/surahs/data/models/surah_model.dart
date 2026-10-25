import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';

class SurahModel extends Surah {
  const SurahModel({
    required super.id,
    required super.nameAr,
    required super.transliteration,
    required super.revelationType,
    required super.versesCount,
    super.ayahs,
  });

  factory SurahModel.fromJson(Map<String, dynamic> json) {
    final versesJson = json['verses'] as List<dynamic>? ?? const [];
    final ayahs = versesJson
        .map(
          (v) => Ayah(
            surahId: json['id'] as int,
            number: v['number'] as int,
            textAr: v['text_ar'] as String,
          ),
        )
        .toList();

    return SurahModel(
      id: json['id'] as int,
      nameAr: json['name_ar'] as String,
      transliteration: json['transliteration'] as String,
      revelationType: json['revelation_type'] as String,
      versesCount: json['verses_count'] as int,
      ayahs: ayahs,
    );
  }

  Map<String, dynamic> toSurahRow() => {
        'id': id,
        'name_ar': nameAr,
        'transliteration': transliteration,
        'revelation_type': revelationType,
        'verses_count': versesCount,
      };

  List<Map<String, dynamic>> toAyahRows() => ayahs
      .map(
        (a) => {
          'surah_id': a.surahId,
          'number': a.number,
          'text_ar': a.textAr,
        },
      )
      .toList();

  factory SurahModel.fromRow(Map<String, dynamic> row, {List<Ayah> ayahs = const []}) {
    return SurahModel(
      id: row['id'] as int,
      nameAr: row['name_ar'] as String,
      transliteration: row['transliteration'] as String,
      revelationType: row['revelation_type'] as String,
      versesCount: row['verses_count'] as int,
      ayahs: ayahs,
    );
  }
}
