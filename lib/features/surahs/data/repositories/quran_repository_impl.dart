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

  /// Traductions FR séparées du texte arabe (jamais mélangées dans les assets AR).
  Map<int, Map<int, String>> _frenchBySurah = {};
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final surahs = await assetDataSource.loadArabicQuran();
    _frenchBySurah = await assetDataSource.loadFrenchTranslations();

    final db = await database.open();

    if (db != null) {
      _local = QuranLocalDataSource(db);
      if (!await _local!.isSeeded()) {
        await _local!.seed(surahs);
      }
    } else {
      _memoryCache = surahs;
    }

    _initialized = true;
  }

  Future<void> _ensureReady() async {
    if (!_initialized) await initialize();
  }

  List<Ayah> _withFrench(int surahId, List<Ayah> ayahs) {
    final fr = _frenchBySurah[surahId] ?? const {};
    return ayahs
        .map((a) => a.copyWith(textFr: fr[a.number]))
        .toList(growable: false);
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
    final Surah base;
    if (_local != null) {
      base = await _local!.getSurah(surahId);
    } else {
      base = _memoryCache!.firstWhere((s) => s.id == surahId);
    }
    return base.copyWith(ayahs: _withFrench(surahId, base.ayahs));
  }

  @override
  Future<List<Ayah>> getAyahs(int surahId) async {
    await _ensureReady();
    final List<Ayah> ayahs;
    if (_local != null) {
      ayahs = await _local!.getAyahs(surahId);
    } else {
      ayahs = _memoryCache!.firstWhere((s) => s.id == surahId).ayahs;
    }
    return _withFrench(surahId, ayahs);
  }
}
