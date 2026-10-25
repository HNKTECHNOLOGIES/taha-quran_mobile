import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/app/app.dart';
import 'package:quran_mobile/app/providers/reading_settings_provider.dart';
import 'package:quran_mobile/core/database/app_database.dart';
import 'package:quran_mobile/features/surahs/data/datasources/quran_asset_datasource.dart';
import 'package:quran_mobile/features/surahs/data/repositories/quran_repository_impl.dart';
import 'package:quran_mobile/features/surahs/domain/entities/surah.dart';
import 'package:quran_mobile/features/surahs/presentation/providers/quran_providers.dart';
import 'package:quran_mobile/features/translations/data/datasources/translation_asset_datasource.dart';
import 'package:quran_mobile/features/translations/data/repositories/translation_repository_impl.dart';
import 'package:quran_mobile/features/translations/presentation/providers/translation_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('navigation + affichage/masquage traduction FR', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    late List<Surah> surahs;
    late Surah fatiha;
    late Surah baqarah;
    late TranslationRepositoryImpl translationRepo;

    await tester.runAsync(() async {
      translationRepo = TranslationRepositoryImpl(
        assetDataSource: TranslationAssetDataSource(),
      );
      final repository = QuranRepositoryImpl(
        database: AppDatabase(),
        assetDataSource: QuranAssetDataSource(),
        translationRepository: translationRepo,
      );
      await repository.initialize();
      surahs = await repository.getSurahs();
      fatiha = await repository.getSurah(1);
      baqarah = await repository.getSurah(2);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          translationRepositoryProvider.overrideWithValue(translationRepo),
          surahListProvider.overrideWith((ref) async => surahs),
          surahDetailProvider.overrideWith((ref, id) async {
            if (id == 1) return fatiha;
            if (id == 2) return baqarah;
            throw StateError('Unexpected surah $id in test');
          }),
          readingSettingsProvider.overrideWith(ReadingSettingsNotifier.new),
        ],
        child: const QuranApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lire le Coran'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الفاتحة'));
    await tester.pumpAndSettle();

    expect(find.text('الفاتحة'), findsWidgets);
    expect(find.textContaining('Al-Fatihah'), findsWidgets);
    expect(find.textContaining('بِسۡمِ'), findsWidgets);
    expect(find.textContaining('Dieu'), findsWidgets);
    expect(find.textContaining('al-quran.fr'), findsWidgets);

    await tester.tap(find.byTooltip('Masquer la traduction'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Dieu'), findsNothing);
  });
}
