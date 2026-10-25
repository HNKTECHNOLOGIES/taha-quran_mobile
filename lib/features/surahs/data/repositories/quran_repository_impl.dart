import '../../../../core/database/app_database.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_asset_datasource.dart';
import '../datasources/quran_local_datasource.dart';
import '../models/surah_model.dart';

class QuranRepositoryImpl implements QuranRepository {
  QuranRepositoryImpl({
    required this.database,
    required this.assetDataSource,
  });

  final AppDatabase database;
  final QuranAssetDataSource assetDataSource;

  QuranLocalDataSource? _local;
  List<SurahModel>? _memoryCache;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final surahs = await assetDataSource.loadArabicQuran();
    final db = await database.open();

    if (db != null) {
      _local = QuranLocalDataSource(db);
      if (!await _local!.isSeeded()) {
        await _local!.seed(surahs);
      }
    } else {
      // Web / environnement sans SQLite : cache mémoire hors ligne.
      _memoryCache = surahs;
    }

    _initialized = true;
  }

  Future<void> _ensureReady() async {
    if (!_initialized) await initialize();
  }

  @override
  Future<List<Surah>> getSurahs() async {
    await _ensureReady();
    if (_local != null) {
      final list = await _local!.getSurahs();
      return list
          .map(
            (s) => Surah(
              id: s.id,
              nameAr: s.nameAr,
              transliteration: s.transliteration,
              revelationType: s.revelationType,
              versesCount: s.versesCount,
            ),
          )
          .toList();
    }
    return _memoryCache!
        .map(
          (s) => Surah(
            id: s.id,
            nameAr: s.nameAr,
            transliteration: s.transliteration,
            revelationType: s.revelationType,
            versesCount: s.versesCount,
          ),
        )
        .toList();
  }

  @override
  Future<Surah> getSurah(int surahId) async {
    await _ensureReady();
    if (_local != null) {
      return _local!.getSurah(surahId);
    }
    return _memoryCache!.firstWhere((s) => s.id == surahId);
  }

  @override
  Future<List<Ayah>> getAyahs(int surahId) async {
    await _ensureReady();
    if (_local != null) {
      return _local!.getAyahs(surahId);
    }
    return _memoryCache!.firstWhere((s) => s.id == surahId).ayahs;
  }
}
