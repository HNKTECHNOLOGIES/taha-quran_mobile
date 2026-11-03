import '../../domain/entities/tafsir_passage.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../datasources/ibn_kathir_asset_datasource.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  TafsirRepositoryImpl({required this.dataSource});

  final IbnKathirAssetDataSource dataSource;

  @override
  Future<TafsirEditionInfo> getIbnKathirInfo() => dataSource.loadInfo();

  @override
  Future<List<TafsirPassage>> getIbnKathirSurah(int surahId) =>
      dataSource.loadSurah(surahId);

  @override
  Future<TafsirPassage?> getIbnKathirPassage({
    required int surahId,
    required int ayahNumber,
  }) async {
    final passages = await dataSource.loadSurah(surahId);
    return dataSource.findPassage(passages, ayahNumber);
  }
}
