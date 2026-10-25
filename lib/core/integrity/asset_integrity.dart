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
    final manifestRaw =
        await rootBundle.loadString(QuranConstants.manifestAssetPath);
    final manifest = jsonDecode(manifestRaw) as Map<String, dynamic>;
    final expected = manifest['sha256'] as String;

    final bytes =
        (await rootBundle.load(QuranConstants.arabicAssetPath)).buffer.asUint8List();
    final actual = sha256.convert(bytes).toString();

    if (actual != expected) {
      throw AssetIntegrityException(
        'Checksum mismatch for quran_ar.json (expected $expected, got $actual)',
      );
    }

    if (manifest['surahs'] != QuranConstants.surahCount ||
        manifest['verses'] != QuranConstants.verseCount) {
      throw AssetIntegrityException('Manifest counts do not match constants');
    }
  }
}
