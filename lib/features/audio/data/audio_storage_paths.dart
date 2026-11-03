import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/reciter.dart';

/// Chemins locaux des fichiers audio téléchargés.
///
/// Structure : `{docs}/taha_audio/{reciterId}/{SSS}/001001.mp3` (versets)
/// ou `{docs}/taha_audio/{reciterId}/{SSS}/{SSS}.mp3` (sourate complète).
class AudioStoragePaths {
  AudioStoragePaths({this.rootOverride});

  final Directory? rootOverride;
  Directory? _cachedRoot;

  Future<Directory> rootDir() async {
    final override = rootOverride;
    if (override != null) return override;
    if (_cachedRoot != null) return _cachedRoot!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'taha_audio'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _cachedRoot = dir;
    return dir;
  }

  Future<Directory> surahDir({
    required String reciterId,
    required int surahId,
  }) async {
    final root = await rootDir();
    final sss = surahId.toString().padLeft(3, '0');
    final dir = Directory(p.join(root.path, reciterId, sss));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> verseFile({
    required String reciterId,
    required int surahId,
    required int ayahNumber,
  }) async {
    final dir = await surahDir(reciterId: reciterId, surahId: surahId);
    final sss = surahId.toString().padLeft(3, '0');
    final aaa = ayahNumber.toString().padLeft(3, '0');
    return File(p.join(dir.path, '$sss$aaa.mp3'));
  }

  Future<File> fullSurahFile({
    required String reciterId,
    required int surahId,
  }) async {
    final dir = await surahDir(reciterId: reciterId, surahId: surahId);
    final sss = surahId.toString().padLeft(3, '0');
    return File(p.join(dir.path, '$sss.mp3'));
  }

  Future<File> statusIndexFile() async {
    final root = await rootDir();
    return File(p.join(root.path, 'downloads_index.json'));
  }

  Future<List<File>> expectedFiles({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    if (reciter.mode == ReciterAudioMode.fullSurah) {
      return [await fullSurahFile(reciterId: reciter.id, surahId: surahId)];
    }
    return [
      for (var a = 1; a <= verseCount; a++)
        await verseFile(
          reciterId: reciter.id,
          surahId: surahId,
          ayahNumber: a,
        ),
    ];
  }

  /// Fichier temporaire pendant le téléchargement (`.part`).
  File partFileFor(File target) => File('${target.path}.part');
}
