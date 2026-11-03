import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../library/domain/entities/verse_ref.dart';
import '../../data/datasources/ibn_kathir_asset_datasource.dart';
import '../../data/repositories/tafsir_repository_impl.dart';
import '../../domain/entities/tafsir_passage.dart';
import '../../domain/repositories/tafsir_repository.dart';

final ibnKathirDataSourceProvider = Provider<IbnKathirAssetDataSource>((ref) {
  return IbnKathirAssetDataSource();
});

final tafsirRepositoryProvider = Provider<TafsirRepository>((ref) {
  return TafsirRepositoryImpl(
    dataSource: ref.watch(ibnKathirDataSourceProvider),
  );
});

final ibnKathirInfoProvider = FutureProvider<TafsirEditionInfo>((ref) {
  return ref.watch(tafsirRepositoryProvider).getIbnKathirInfo();
});

/// Charge toute la sourate (mis en cache par le datasource).
final ibnKathirSurahProvider =
    FutureProvider.family<List<TafsirPassage>, int>((ref, surahId) {
  return ref.watch(tafsirRepositoryProvider).getIbnKathirSurah(surahId);
});

/// Passage pour un verset — déclenche le chargement lazy de la sourate.
final ibnKathirPassageProvider =
    FutureProvider.family<TafsirPassage?, VerseRef>((ref, verse) async {
  final passages = await ref.watch(ibnKathirSurahProvider(verse.surahId).future);
  for (final p in passages) {
    if (p.covers(verse.ayahNumber)) return p;
  }
  return null;
});
