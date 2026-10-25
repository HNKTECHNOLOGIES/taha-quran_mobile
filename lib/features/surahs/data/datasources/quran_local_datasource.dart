import 'package:sqflite/sqflite.dart';

import '../../domain/entities/ayah.dart';
import '../models/surah_model.dart';

class QuranLocalDataSource {
  QuranLocalDataSource(this._db);

  final Database _db;

  Future<bool> isSeeded() async {
    final rows = await _db.query(
      'meta',
      where: 'key = ?',
      whereArgs: ['seeded'],
      limit: 1,
    );
    return rows.isNotEmpty && rows.first['value'] == '1';
  }

  Future<void> seed(List<SurahModel> surahs) async {
    final batch = _db.batch();
    for (final surah in surahs) {
      batch.insert(
        'surahs',
        surah.toSurahRow(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      for (final row in surah.toAyahRows()) {
        batch.insert(
          'ayahs',
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
    batch.insert(
      'meta',
      {'key': 'seeded', 'value': '1'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await batch.commit(noResult: true);
  }

  Future<List<SurahModel>> getSurahs() async {
    final rows = await _db.query('surahs', orderBy: 'id ASC');
    return rows.map(SurahModel.fromRow).toList();
  }

  Future<SurahModel> getSurah(int surahId) async {
    final rows = await _db.query(
      'surahs',
      where: 'id = ?',
      whereArgs: [surahId],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Surah $surahId not found');
    }
    final ayahs = await getAyahs(surahId);
    return SurahModel.fromRow(rows.first, ayahs: ayahs);
  }

  Future<List<Ayah>> getAyahs(int surahId) async {
    final rows = await _db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'number ASC',
    );
    return rows
        .map(
          (r) => Ayah(
            surahId: r['surah_id'] as int,
            number: r['number'] as int,
            textAr: r['text_ar'] as String,
          ),
        )
        .toList();
  }
}
