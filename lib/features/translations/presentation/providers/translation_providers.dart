import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/translation_asset_datasource.dart';
import '../../data/repositories/translation_repository_impl.dart';
import '../../domain/entities/ayah_translation.dart';
import '../../domain/repositories/translation_repository.dart';

final translationAssetDataSourceProvider =
    Provider<TranslationAssetDataSource>((ref) {
  return TranslationAssetDataSource();
});

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return TranslationRepositoryImpl(
    assetDataSource: ref.watch(translationAssetDataSourceProvider),
  );
});

final frenchTranslationInfoProvider =
    FutureProvider<TranslationInfo?>((ref) async {
  final repo = ref.watch(translationRepositoryProvider);
  await repo.initialize();
  return repo.frenchInfo;
});
