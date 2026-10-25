import '../entities/surah.dart';
import '../repositories/quran_repository.dart';

class GetSurahs {
  const GetSurahs(this._repository);

  final QuranRepository _repository;

  Future<List<Surah>> call() => _repository.getSurahs();
}
