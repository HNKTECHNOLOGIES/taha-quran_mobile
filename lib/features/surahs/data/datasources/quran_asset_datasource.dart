import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/quran_constants.dart';
import '../../../../core/integrity/asset_integrity.dart';
import '../models/surah_model.dart';

class QuranAssetDataSource {
  Future<List<SurahModel>> loadArabicQuran() async {
    await AssetIntegrity.verifyArabicAsset();

    final raw = await rootBundle.loadString(QuranConstants.arabicAssetPath);
    final list = jsonDecode(raw) as List<dynamic>;
    final surahs = list
        .map((e) => SurahModel.fromJson(e as Map<String, dynamic>))
        .toList();

    _validateArabic(surahs);
    return surahs;
  }

  void _validateArabic(List<SurahModel> surahs) {
    if (surahs.length != QuranConstants.surahCount) {
      throw AssetIntegrityException(
        'Expected ${QuranConstants.surahCount} surahs, got ${surahs.length}',
      );
    }

    var totalVerses = 0;
    for (var i = 0; i < surahs.length; i++) {
      final surah = surahs[i];
      final expectedId = i + 1;
      if (surah.id != expectedId) {
        throw AssetIntegrityException(
          'Surah order mismatch at index $i (id=${surah.id})',
        );
      }
      final expectedCount = QuranConstants.versesPerSurah[i];
      if (surah.versesCount != expectedCount ||
          surah.ayahs.length != expectedCount) {
        throw AssetIntegrityException(
          'Surah ${surah.id} verse count mismatch '
          '(meta=${surah.versesCount}, ayahs=${surah.ayahs.length}, '
          'expected=$expectedCount)',
        );
      }
      for (var j = 0; j < surah.ayahs.length; j++) {
        final ayah = surah.ayahs[j];
        if (ayah.number != j + 1 || ayah.textAr.trim().isEmpty) {
          throw AssetIntegrityException(
            'Invalid ayah ${surah.id}:${ayah.number}',
          );
        }
      }
      totalVerses += surah.ayahs.length;
    }

    if (totalVerses != QuranConstants.verseCount) {
      throw AssetIntegrityException(
        'Expected ${QuranConstants.verseCount} verses, got $totalVerses',
      );
    }
  }
}
