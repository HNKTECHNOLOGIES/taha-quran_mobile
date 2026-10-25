import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/app/app.dart';
import 'package:quran_mobile/core/database/app_database.dart';
import 'package:quran_mobile/features/surahs/data/datasources/quran_asset_datasource.dart';
import 'package:quran_mobile/features/surahs/data/repositories/quran_repository_impl.dart';
import 'package:quran_mobile/features/surahs/domain/entities/surah.dart';
import 'package:quran_mobile/features/surahs/presentation/providers/quran_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navigation Accueil → Liste → Lecture (Al-Fatiha)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Chargement réel hors FakeAsync (assets / crypto).
    late List<Surah> surahs;
    late Surah fatiha;
    await tester.runAsync(() async {
      final repository = QuranRepositoryImpl(
        database: AppDatabase(),
        assetDataSource: QuranAssetDataSource(),
      );
      await repository.initialize();
      surahs = await repository.getSurahs();
      fatiha = await repository.getSurah(1);
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          surahListProvider.overrideWith((ref) async => surahs),
          surahDetailProvider.overrideWith((ref, id) async {
            if (id == 1) return fatiha;
            throw StateError('Unexpected surah $id in test');
          }),
        ],
        child: const QuranApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('القرآن الكريم'), findsWidgets);

    await tester.tap(find.text('Parcourir les sourates'));
    await tester.pumpAndSettle();

    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('Sourates'), findsWidgets);

    await tester.tap(find.text('الفاتحة'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Al-Fatihah'), findsWidgets);
    expect(find.textContaining('بِسۡمِ'), findsWidgets);
  });
}
