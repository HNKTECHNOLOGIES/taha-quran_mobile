import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/quran_constants.dart';
import '../../../../core/integrity/asset_integrity.dart';
import '../../domain/entities/ayah_translation.dart';

class TranslationAssetDataSource {
  Future<({TranslationInfo info, Map<int, Map<int, String>> bySurah})?>
      loadFrenchOrNull() async {
    try {
      await AssetIntegrity.verifyFrenchTranslationAsset();
    } on AssetIntegrityException {
      // Pas de fichier / checksum invalide : pas de traduction (jamais inventée).
      return null;
    }

    final manifestRaw =
        await rootBundle.loadString(QuranConstants.manifestAssetPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final frMeta = manifest['translations']?['fr'] as Map<String, dynamic>?;
    if (frMeta == null) return null;

    final raw =
        await rootBundle.loadString(QuranConstants.frenchTranslationAssetPath);
    final list = jsonDecode(raw) as List<dynamic>;

    if (list.length != QuranConstants.surahCount) {
      throw AssetIntegrityException(
        'Expected ${QuranConstants.surahCount} FR surahs, got ${list.length}',
      );
    }

    final bySurah = <int, Map<int, String>>{};
    var totalNonEmpty = 0;

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
        final text = (v['text_fr'] as String?)?.trim() ?? '';
        if (number != j + 1) {
          throw AssetIntegrityException('Invalid FR ayah index $surahId:$number');
        }
        // Texte vide autorisé (= absence) — ne jamais inventer.
        if (text.isNotEmpty) {
          map[number] = text;
          totalNonEmpty++;
        }
      }
      bySurah[surahId] = map;
    }

    if (totalNonEmpty == 0) return null;

    final info = TranslationInfo(
      languageCode: 'fr',
      translator: frMeta['translator'] as String? ?? 'Inconnu',
      edition: frMeta['edition'] as String? ?? '',
      license: frMeta['license'] as String? ?? '',
      licenseUrl: frMeta['license_url'] as String? ?? '',
      attribution: frMeta['attribution'] as String? ?? '',
      sourceUrl: 'https://al-quran.fr',
    );

    return (info: info, bySurah: bySurah);
  }
}
