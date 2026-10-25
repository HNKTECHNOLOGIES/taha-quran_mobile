import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../constants/quran_constants.dart';

class AssetIntegrityException implements Exception {
  AssetIntegrityException(this.message);
  final String message;

  @override
  String toString() => 'AssetIntegrityException: $message';
}

class AssetIntegrity {
  /// Vérifie le SHA-256 de [QuranConstants.arabicAssetPath] contre le manifeste.
  static Future<void> verifyArabicAsset() async {
    final manifest = await _manifest();
    final expected = manifest['sha256'] as String;
    await _verifyFile(QuranConstants.arabicAssetPath, expected);

    if (manifest['surahs'] != QuranConstants.surahCount ||
        manifest['verses'] != QuranConstants.verseCount) {
      throw AssetIntegrityException('Manifest counts do not match constants');
    }
  }

  /// Vérifie le fichier de traduction française (asset séparé).
  static Future<void> verifyFrenchTranslationAsset() async {
    final manifest = await _manifest();
    final fr = manifest['translations']?['fr'] as Map<String, dynamic>?;
    if (fr == null) {
      throw AssetIntegrityException('Missing French translation in manifest');
    }
    await _verifyFile(
      QuranConstants.frenchTranslationAssetPath,
      fr['sha256'] as String,
    );
    if (fr['surahs'] != QuranConstants.surahCount ||
        fr['verses'] != QuranConstants.verseCount) {
      throw AssetIntegrityException('French translation counts mismatch');
    }
  }

  static Future<Map<String, dynamic>> _manifest() async {
    final raw = await rootBundle.loadString(QuranConstants.manifestAssetPath);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> _verifyFile(String assetPath, String expectedSha) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    final actual = sha256.convert(bytes).toString();
    if (actual != expectedSha) {
      throw AssetIntegrityException(
        'Checksum mismatch for $assetPath (expected $expectedSha, got $actual)',
      );
    }
  }
}
