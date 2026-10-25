import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetSurahWithAyahs {
  const GetSurahWithAyahs(this._repository);

  final QuranRepository _repository;

  Future<Surah> call(int surahId) => _repository.getSurah(surahId);
}
