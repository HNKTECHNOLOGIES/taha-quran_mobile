import '../../domain/entities/ayah_translation.dart';
import '../../domain/repositories/translation_repository.dart';
import '../datasources/translation_asset_datasource.dart';

class TranslationRepositoryImpl implements TranslationRepository {
  TranslationRepositoryImpl({required this.assetDataSource});

  final TranslationAssetDataSource assetDataSource;

  TranslationInfo? _frenchInfo;
  Map<int, Map<int, String>> _frenchBySurah = {};
  bool _initialized = false;

  @override
  bool get hasFrenchTranslation => _frenchInfo != null && _frenchBySurah.isNotEmpty;

  @override
  TranslationInfo? get frenchInfo => _frenchInfo;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    final loaded = await assetDataSource.loadFrenchOrNull();
    if (loaded != null) {
      _frenchInfo = loaded.info;
      _frenchBySurah = loaded.bySurah;
    } else {
      _frenchInfo = null;
      _frenchBySurah = {};
    }
    _initialized = true;
  }

  Future<void> _ensureReady() async {
    if (!_initialized) await initialize();
  }

  @override
  Future<AyahTranslation?> getFrenchTranslation({
    required int surahId,
    required int ayahNumber,
  }) async {
    await _ensureReady();
    final text = _frenchBySurah[surahId]?[ayahNumber];
    if (text == null || text.isEmpty) return null;
    return AyahTranslation(
      surahId: surahId,
      ayahNumber: ayahNumber,
      text: text,
      languageCode: 'fr',
    );
  }

  @override
  Future<Map<int, AyahTranslation>> getFrenchForSurah(int surahId) async {
    await _ensureReady();
    final map = _frenchBySurah[surahId] ?? const {};
    return {
      for (final e in map.entries)
        if (e.value.isNotEmpty)
          e.key: AyahTranslation(
            surahId: surahId,
            ayahNumber: e.key,
            text: e.value,
            languageCode: 'fr',
          ),
    };
  }
}
