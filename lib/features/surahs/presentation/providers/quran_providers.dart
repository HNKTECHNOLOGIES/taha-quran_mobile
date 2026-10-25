import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/datasources/quran_asset_datasource.dart';
import '../../data/repositories/quran_repository_impl.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../../domain/usecases/get_surah_with_ayahs.dart';
import '../../domain/usecases/get_surahs.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final quranAssetDataSourceProvider = Provider<QuranAssetDataSource>((ref) {
  return QuranAssetDataSource();
});

final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    assetDataSource: ref.watch(quranAssetDataSourceProvider),
  );
});

final surahListProvider = FutureProvider<List<Surah>>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  await repository.initialize();
  return GetSurahs(repository)();
});

final surahDetailProvider =
    FutureProvider.family<Surah, int>((ref, surahId) async {
  final repository = ref.watch(quranRepositoryProvider);
  await repository.initialize();
  return GetSurahWithAyahs(repository)(surahId);
});
