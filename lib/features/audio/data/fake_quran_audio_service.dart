import 'dart:async';

import '../domain/entities/reciter.dart';
import '../domain/services/quran_audio_service.dart';

/// Service audio simulé pour les tests unitaires (sans plugin natif).
class FakeQuranAudioService implements QuranAudioService {
  FakeQuranAudioService({
    this.failNextLoad = false,
    this.loadDelay = Duration.zero,
    this.verseDuration = const Duration(seconds: 2),
  });

  bool failNextLoad;
  Duration loadDelay;
  Duration verseDuration;

  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _eventController =
      StreamController<QuranAudioPlayerEvent>.broadcast();

  int _verseCount = 0;
  int _currentIndex = 0;
  bool _playing = false;
  bool _disposed = false;
  Duration _position = Duration.zero;
  Timer? _tick;

  Reciter? lastReciter;
  int? lastSurahId;
  int loadCount = 0;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration?> get durationStream => _durationController.stream;

  @override
  Stream<int?> get currentIndexStream => _indexController.stream;

  @override
  Stream<QuranAudioPlayerEvent> get playerEventStream =>
      _eventController.stream;

  int get currentIndex => _currentIndex;
  bool get isPlaying => _playing;
  bool get isDisposed => _disposed;

  @override
  Future<void> loadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
    int startAyah = 1,
  }) async {
    _ensureNotDisposed();
    loadCount++;
    lastReciter = reciter;
    lastSurahId = surahId;
    _verseCount = verseCount;
    _currentIndex = (startAyah.clamp(1, verseCount)) - 1;
    _position = Duration.zero;
    _playing = false;
    _stopTick();

    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.loading),
    );

    if (loadDelay > Duration.zero) {
      await Future<void>.delayed(loadDelay);
    }

    if (failNextLoad) {
      failNextLoad = false;
      const message = 'Network error: failed to load audio';
      _eventController.add(
        const QuranAudioPlayerEvent(
          QuranAudioPlayerEventKind.error,
          message: message,
        ),
      );
      throw Exception(message);
    }

    _indexController.add(_currentIndex);
    _durationController.add(verseDuration);
    _positionController.add(_position);
    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.ready),
    );
  }

  @override
  Future<void> play() async {
    _ensureNotDisposed();
    if (_verseCount < 1) return;
    _playing = true;
    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.playing),
    );
    _startTick();
  }

  @override
  Future<void> pause() async {
    _ensureNotDisposed();
    _playing = false;
    _stopTick();
    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.paused),
    );
  }

  @override
  Future<void> stop() async {
    _ensureNotDisposed();
    _playing = false;
    _stopTick();
    _currentIndex = 0;
    _position = Duration.zero;
    _indexController.add(_currentIndex);
    _positionController.add(_position);
    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.paused),
    );
  }

  @override
  Future<void> seekToVerse(int ayahNumber) async {
    _ensureNotDisposed();
    if (_verseCount < 1) return;
    _currentIndex = (ayahNumber.clamp(1, _verseCount)) - 1;
    _position = Duration.zero;
    _indexController.add(_currentIndex);
    _positionController.add(_position);
    _durationController.add(verseDuration);
  }

  @override
  Future<void> next() async {
    _ensureNotDisposed();
    if (_currentIndex >= _verseCount - 1) {
      _playing = false;
      _stopTick();
      _eventController.add(
        const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.completed),
      );
      return;
    }
    _currentIndex++;
    _position = Duration.zero;
    _indexController.add(_currentIndex);
    _positionController.add(_position);
    _durationController.add(verseDuration);
  }

  @override
  Future<void> previous() async {
    _ensureNotDisposed();
    if (_currentIndex <= 0) {
      _position = Duration.zero;
      _positionController.add(_position);
      return;
    }
    _currentIndex--;
    _position = Duration.zero;
    _indexController.add(_currentIndex);
    _positionController.add(_position);
    _durationController.add(verseDuration);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopTick();
    await _positionController.close();
    await _durationController.close();
    await _indexController.close();
    await _eventController.close();
  }

  void _startTick() {
    _stopTick();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_playing || _disposed) return;
      _position += const Duration(milliseconds: 100);
      _positionController.add(_position);
      if (_position >= verseDuration) {
        if (_currentIndex >= _verseCount - 1) {
          _playing = false;
          _stopTick();
          _eventController.add(
            const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.completed),
          );
        } else {
          _currentIndex++;
          _position = Duration.zero;
          _indexController.add(_currentIndex);
          _positionController.add(_position);
          _durationController.add(verseDuration);
        }
      }
    });
  }

  void _stopTick() {
    _tick?.cancel();
    _tick = null;
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('FakeQuranAudioService already disposed');
    }
  }
}
