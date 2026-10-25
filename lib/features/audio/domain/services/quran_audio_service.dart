import '../entities/reciter.dart';

/// Abstraction du lecteur (testable sans `just_audio` natif).
abstract class QuranAudioService {
  Stream<Duration> get positionStream;
  Stream<Duration?> get durationStream;
  Stream<int?> get currentIndexStream;
  Stream<QuranAudioPlayerEvent> get playerEventStream;

  Future<void> loadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
    int startAyah = 1,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> seekToVerse(int ayahNumber);
  Future<void> next();
  Future<void> previous();
  Future<void> dispose();
}

enum QuranAudioPlayerEventKind {
  loading,
  ready,
  playing,
  paused,
  completed,
  error,
}

class QuranAudioPlayerEvent {
  const QuranAudioPlayerEvent(this.kind, {this.message});

  final QuranAudioPlayerEventKind kind;
  final String? message;
}
