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

  /// Charge la traduction FR (Hamidullah) : map[surahId][ayahNumber] -> texte.
  Future<Map<int, Map<int, String>>> loadFrenchTranslations() async {
    await AssetIntegrity.verifyFrenchTranslationAsset();

    final raw =
        await rootBundle.loadString(QuranConstants.frenchTranslationAssetPath);
    final list = jsonDecode(raw) as List<dynamic>;

    if (list.length != QuranConstants.surahCount) {
      throw AssetIntegrityException(
        'Expected ${QuranConstants.surahCount} FR surahs, got ${list.length}',
      );
    }

    final result = <int, Map<int, String>>{};
    var total = 0;

    for (var i = 0; i < list.length; i++) {
      final item = list[i] as Map<String, dynamic>;
      final surahId = item['id'] as int;
      if (surahId != i + 1) {
        throw AssetIntegrityException('FR surah order mismatch at $i');
      }
      final verses = item['verses'] as List<dynamic>;
      final expected = QuranConstants.versesPerSurah[i];
      if (verses.length != expected) {
        throw AssetIntegrityException(
          'FR surah $surahId count ${verses.length} != $expected',
        );
      }
      final map = <int, String>{};
      for (var j = 0; j < verses.length; j++) {
        final v = verses[j] as Map<String, dynamic>;
        final number = v['number'] as int;
        final text = (v['text_fr'] as String).trim();
        if (number != j + 1 || text.isEmpty) {
          throw AssetIntegrityException('Invalid FR ayah $surahId:$number');
        }
        map[number] = text;
      }
      result[surahId] = map;
      total += map.length;
    }

    if (total != QuranConstants.verseCount) {
      throw AssetIntegrityException(
        'Expected ${QuranConstants.verseCount} FR verses, got $total',
      );
    }
    return result;
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
