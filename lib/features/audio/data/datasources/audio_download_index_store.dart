import 'dart:convert';
import 'dart:io';

import '../../domain/entities/surah_download.dart';
import '../audio_storage_paths.dart';

/// Persistance JSON de l’index des téléchargements (hors fichiers MP3).
class AudioDownloadIndexStore {
  AudioDownloadIndexStore({AudioStoragePaths? paths})
      : paths = paths ?? AudioStoragePaths();

  final AudioStoragePaths paths;

  Future<Map<String, SurahDownload>> load() async {
    final file = await paths.statusIndexFile();
    if (!await file.exists()) return {};
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final out = <String, SurahDownload>{};
      for (final entry in decoded.entries) {
        final value = entry.value;
        if (value is Map) {
          final map = Map<String, dynamic>.from(value);
          final item = SurahDownload.fromJson(map);
          out[item.key] = item;
        }
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, SurahDownload> downloads) async {
    final file = await paths.statusIndexFile();
    final encoded = {
      for (final e in downloads.entries) e.key: e.value.toJson(),
    };
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(const JsonEncoder.withIndent('  ').convert(encoded));
    if (await file.exists()) {
      await file.delete();
    }
    await tmp.rename(file.path);
  }

  Future<void> upsert(SurahDownload download) async {
    final all = await load();
    all[download.key] = download;
    await save(all);
  }

  Future<void> remove(String key) async {
    final all = await load();
    if (all.remove(key) != null) {
      await save(all);
    }
  }
}
