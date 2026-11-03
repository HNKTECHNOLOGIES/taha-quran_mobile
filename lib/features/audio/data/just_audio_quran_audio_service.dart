import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/entities/reciter.dart';
import '../domain/services/quran_audio_service.dart';
import 'quran_audio_url_builder.dart';

/// Implémentation [QuranAudioService] basée sur `just_audio`.
class JustAudioQuranAudioService implements QuranAudioService {
  JustAudioQuranAudioService({
    AudioPlayer? player,
    this.urlBuilder = const QuranAudioUrlBuilder(),
    this.configureSession = true,
  }) : _player = player ?? AudioPlayer() {
    _playerStateSub = _player.playerStateStream.listen(_onPlayerState);
  }

  final AudioPlayer _player;
  final QuranAudioUrlBuilder urlBuilder;
  final bool configureSession;

  final _eventController =
      StreamController<QuranAudioPlayerEvent>.broadcast();

  StreamSubscription<PlayerState>? _playerStateSub;
  bool _disposed = false;
  bool _sessionReady = false;
  int _verseCount = 0;
  bool _verseSync = true;

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<Duration?> get durationStream => _player.durationStream;

  @override
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  @override
  Stream<QuranAudioPlayerEvent> get playerEventStream =>
      _eventController.stream;

  Future<void> _ensureSession() async {
    if (!configureSession || _sessionReady) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _sessionReady = true;
    } catch (_) {
      // Plateformes sans audio_session natif (tests / web partiel).
    }
  }

  void _onPlayerState(PlayerState state) {
    if (_disposed || _eventController.isClosed) return;
    switch (state.processingState) {
      case ProcessingState.loading:
      case ProcessingState.buffering:
        _eventController.add(
          const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.loading),
        );
      case ProcessingState.ready:
        if (state.playing) {
          _eventController.add(
            const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.playing),
          );
        } else {
          _eventController.add(
            const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.paused),
          );
        }
      case ProcessingState.completed:
        _eventController.add(
          const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.completed),
        );
      case ProcessingState.idle:
        break;
    }
  }

  @override
  Future<void> loadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
    int startAyah = 1,
  }) async {
    _ensureNotDisposed();
    if (verseCount < 1) {
      throw ArgumentError.value(verseCount, 'verseCount');
    }
    final start = startAyah.clamp(1, verseCount);
    _verseCount = verseCount;
    _verseSync = reciter.supportsVerseSync;

    _eventController.add(
      const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.loading),
    );

    try {
      await _ensureSession();
      final uris = urlBuilder.surahPlaylist(
        reciter: reciter,
        surahId: surahId,
        verseCount: verseCount,
      );
      final sources = [
        for (final uri in uris) AudioSource.uri(uri),
      ];
      // Sourate complète = 1 piste : pas de seek verset sans minutage.
      final initialIndex =
          _verseSync ? (start - 1).clamp(0, sources.length - 1) : 0;
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        preload: true,
      );
      _eventController.add(
        const QuranAudioPlayerEvent(QuranAudioPlayerEventKind.ready),
      );
    } catch (e) {
      final message = e.toString();
      _eventController.add(
        QuranAudioPlayerEvent(
          QuranAudioPlayerEventKind.error,
          message: message,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    _ensureNotDisposed();
    await _player.play();
  }

  @override
  Future<void> pause() async {
    _ensureNotDisposed();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _ensureNotDisposed();
    await _player.stop();
    if (_verseCount > 0) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  @override
  Future<void> seekToVerse(int ayahNumber) async {
    _ensureNotDisposed();
    if (!_verseSync || _verseCount < 1) return;
    final index = (ayahNumber.clamp(1, _verseCount)) - 1;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> next() async {
    _ensureNotDisposed();
    if (!_verseSync) return;
    await _player.seekToNext();
  }

  @override
  Future<void> previous() async {
    _ensureNotDisposed();
    if (!_verseSync) return;
    await _player.seekToPrevious();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _playerStateSub?.cancel();
    _playerStateSub = null;
    await _player.dispose();
    await _eventController.close();
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('QuranAudioService already disposed');
    }
  }
}
