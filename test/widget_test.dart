import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_mobile/app/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('affiche l’accueil avec le titre coranique', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: QuranApp()));
    await tester.pump();

    expect(find.text('القرآن الكريم'), findsWidgets);
    expect(find.text('Parcourir les sourates'), findsOneWidget);
  });
}
