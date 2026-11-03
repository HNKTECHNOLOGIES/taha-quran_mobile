import 'dart:convert';

import 'package:flutter/services.dart';

import '../../../../core/constants/quran_constants.dart';
import '../../domain/entities/tafsir_passage.dart';

class IbnKathirAssetDataSource {
  final Map<int, List<TafsirPassage>> _surahCache = {};
  TafsirEditionInfo? _info;

  Future<TafsirEditionInfo> loadInfo() async {
    if (_info != null) return _info!;
    final raw = await rootBundle.loadString(
      QuranConstants.ibnKathirManifestAssetPath,
    );
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _info = TafsirEditionInfo(
      id: map['id'] as String? ?? 'ibn_kathir_ar',
      commentatorAr: map['commentator_ar'] as String? ?? 'ابن كثير',
      commentatorEn:
          map['commentator_en'] as String? ?? 'Ibn Kathir',
      workAr: map['work_ar'] as String? ?? 'تفسير القرآن العظيم',
      attribution: map['attribution'] as String? ?? '',
      license: map['license'] as String? ?? 'public-domain',
      sourceCommit: map['source_commit'] as String? ?? '',
    );
    return _info!;
  }

  Future<List<TafsirPassage>> loadSurah(int surahId) async {
    if (surahId < 1 || surahId > QuranConstants.surahCount) {
      throw ArgumentError.value(surahId, 'surahId');
    }
    final cached = _surahCache[surahId];
    if (cached != null) return cached;

    final info = await loadInfo();
    final path =
        '${QuranConstants.ibnKathirAssetDir}/${surahId.toString().padLeft(3, '0')}.json';
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final fileSurah = map['surah'] as int;
    if (fileSurah != surahId) {
      throw StateError('Tafsir file surah mismatch: $fileSurah != $surahId');
    }

    final entries = map['entries'] as List<dynamic>;
    final passages = <TafsirPassage>[];
    for (final e in entries) {
      final item = e as Map<String, dynamic>;
      final start = item['start'] as int;
      final end = item['end'] as int;
      final text = (item['text'] as String?)?.trim() ?? '';
      if (text.isEmpty) continue;
      if (end < start) {
        throw StateError('Invalid tafsir range $surahId:$start-$end');
      }
      passages.add(
        TafsirPassage(
          surahId: surahId,
          startAyah: start,
          endAyah: end,
          textAr: text,
          commentatorAr:
              map['commentator_ar'] as String? ?? info.commentatorAr,
          workAr: map['work_ar'] as String? ?? info.workAr,
        ),
      );
    }

    _surahCache[surahId] = passages;
    return passages;
  }

  TafsirPassage? findPassage(List<TafsirPassage> passages, int ayahNumber) {
    for (final p in passages) {
      if (p.covers(ayahNumber)) return p;
    }
    return null;
  }
}
