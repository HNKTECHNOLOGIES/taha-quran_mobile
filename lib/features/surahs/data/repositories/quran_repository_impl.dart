import '../../../../core/database/app_database.dart';
import '../../../translations/domain/repositories/translation_repository.dart';
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
    required this.translationRepository,
  });

  final AppDatabase database;
  final QuranAssetDataSource assetDataSource;
  final TranslationRepository translationRepository;

  QuranLocalDataSource? _local;
  List<SurahModel>? _memoryCache;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    final surahs = await assetDataSource.loadArabicQuran();
    await translationRepository.initialize();

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

  Future<List<Ayah>> _withFrench(int surahId, List<Ayah> ayahs) async {
    final fr = await translationRepository.getFrenchForSurah(surahId);
    return ayahs
        .map(
          (a) => Ayah(
            surahId: a.surahId,
            number: a.number,
            textAr: a.textAr,
            // Absente → null, jamais de texte inventé.
            textFr: fr[a.number]?.text,
          ),
        )
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
    return base.copyWith(ayahs: await _withFrench(surahId, base.ayahs));
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
