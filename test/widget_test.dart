import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran_mobile/app/app.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('affiche l’accueil moderne Salam + actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: QuranApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('السلام عليكم'), findsOneWidget);
    expect(find.text('TAHA — طه'), findsOneWidget);
    expect(find.text('TAHA'), findsWidgets);
    expect(find.text('Lire le Coran'), findsOneWidget);
    expect(find.text('Écouter une récitation'), findsOneWidget);
    expect(find.text('Mes téléchargements'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Marque-pages'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Mes favoris'), findsOneWidget);
    expect(find.text('Marque-pages'), findsWidgets);
  });
}
