import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/features/audio/data/fake_quran_audio_service.dart';
import 'package:quran_mobile/features/audio/data/quran_audio_url_builder.dart';
import 'package:quran_mobile/features/audio/data/reciter_catalog.dart';
import 'package:quran_mobile/features/audio/domain/entities/audio_playback_state.dart';
import 'package:quran_mobile/features/audio/presentation/providers/audio_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeQuranAudioService fake;
  late ProviderContainer container;
  var containerDisposed = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    containerDisposed = false;
    fake = FakeQuranAudioService(
      verseDuration: const Duration(milliseconds: 500),
    );
    container = ProviderContainer(
      overrides: [
        quranAudioServiceProvider.overrideWith((ref) {
          ref.onDispose(() {
            unawaited(fake.dispose());
          });
          return fake;
        }),
      ],
    );
  });

  tearDown(() {
    if (!containerDisposed) {
      container.dispose();
      containerDisposed = true;
    }
  });

  group('QuranAudioUrlBuilder', () {
    test('construit l’URL verse-par-verset everyayah', () {
      const builder = QuranAudioUrlBuilder();
      final uri = builder.verseUri(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        ayahNumber: 1,
      );
      expect(
        uri.toString(),
        'https://everyayah.com/data/Alafasy_128kbps/001001.mp3',
      );
    });

    test('playlist a un fichier par verset', () {
      const builder = QuranAudioUrlBuilder();
      final list = builder.surahPlaylist(
        reciter: ReciterCatalog.maher,
        surahId: 112,
        verseCount: 4,
      );
      expect(list.length, 4);
      expect(list.last.pathSegments.last, '112004.mp3');
      expect(list.first.toString(), contains('MaherAlMuaiqly128kbps'));
    });
  });

  group('ReciterCatalog', () {
    test('contient les 3 récitateurs demandés', () {
      expect(ReciterCatalog.all.length, 3);
      expect(
        ReciterCatalog.all.map((r) => r.nameEn).toList(),
        containsAll([
          'Mishary Rashid Alafasy',
          'Abdul Basit Abdus Samad',
          'Maher Al-Muaiqly',
        ]),
      );
    });
  });

  group('AudioController UC12', () {
    test('lecture, pause et reprise', () async {
      final notifier = container.read(audioControllerProvider.notifier);

      await notifier.playSurah(surahId: 1, verseCount: 7, startAyah: 1);
      await pumpEventQueue();

      expect(fake.lastSurahId, 1);
      expect(fake.isPlaying, isTrue);
      expect(
        container.read(audioControllerProvider).status,
        AudioStatus.playing,
      );
      expect(container.read(audioControllerProvider).ayahNumber, 1);

      await notifier.pause();
      await pumpEventQueue();
      expect(fake.isPlaying, isFalse);
      expect(
        container.read(audioControllerProvider).status,
        AudioStatus.paused,
      );

      await notifier.resume();
      await pumpEventQueue();
      expect(fake.isPlaying, isTrue);
      expect(
        container.read(audioControllerProvider).status,
        AudioStatus.playing,
      );
    });

    test('verset précédent et suivant', () async {
      final notifier = container.read(audioControllerProvider.notifier);
      await notifier.playSurah(surahId: 1, verseCount: 7, startAyah: 2);
      await pumpEventQueue();
      expect(container.read(audioControllerProvider).ayahNumber, 2);

      await notifier.next();
      await pumpEventQueue();
      expect(fake.currentIndex, 2);
      expect(container.read(audioControllerProvider).ayahNumber, 3);

      await notifier.previous();
      await pumpEventQueue();
      expect(fake.currentIndex, 1);
      expect(container.read(audioControllerProvider).ayahNumber, 2);
    });

    test('gestion des erreurs réseau', () async {
      fake.failNextLoad = true;
      final notifier = container.read(audioControllerProvider.notifier);

      await notifier.playSurah(surahId: 2, verseCount: 5);
      await pumpEventQueue();

      final state = container.read(audioControllerProvider);
      expect(state.status, AudioStatus.error);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage!.toLowerCase(), contains('network'));
    });

    test('changement de récitateur', () async {
      final notifier = container.read(audioControllerProvider.notifier);
      await notifier.playSurah(surahId: 1, verseCount: 7, startAyah: 3);
      await pumpEventQueue();
      expect(fake.lastReciter?.id, ReciterCatalog.alafasy.id);

      await notifier.pause();
      await pumpEventQueue();

      await notifier.changeReciter(ReciterCatalog.abdulBasit);
      await pumpEventQueue();

      expect(fake.lastReciter?.id, ReciterCatalog.abdulBasit.id);
      expect(fake.loadCount, greaterThanOrEqualTo(2));
      expect(
        container.read(selectedReciterProvider).id,
        ReciterCatalog.abdulBasit.id,
      );
      expect(container.read(audioControllerProvider).ayahNumber, 3);
      expect(
        container.read(audioControllerProvider).reciter.id,
        ReciterCatalog.abdulBasit.id,
      );
    });

    test('nettoyage des ressources', () async {
      final notifier = container.read(audioControllerProvider.notifier);
      await notifier.playSurah(surahId: 112, verseCount: 4);
      await pumpEventQueue();
      expect(fake.isDisposed, isFalse);

      container.dispose();
      containerDisposed = true;
      expect(fake.isDisposed, isTrue);
    });

    test('progression audio exposée', () async {
      final notifier = container.read(audioControllerProvider.notifier);
      await notifier.playSurah(surahId: 1, verseCount: 7);
      await pumpEventQueue();

      // Avance artificielle via le tick du fake
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await pumpEventQueue();

      final state = container.read(audioControllerProvider);
      expect(state.duration, greaterThan(Duration.zero));
      expect(state.progress, greaterThan(0));
      expect(state.progress, lessThanOrEqualTo(1));
    });
  });
}
