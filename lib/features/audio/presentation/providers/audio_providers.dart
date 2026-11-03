import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/just_audio_quran_audio_service.dart';
import '../../data/reciter_catalog.dart';
import '../../domain/entities/audio_playback_state.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/services/quran_audio_service.dart';
import 'download_providers.dart';

const _kReciterId = 'audio_selected_reciter_id';

final quranAudioServiceProvider = Provider<QuranAudioService>((ref) {
  final resolver = ref.watch(localAudioSourceResolverProvider);
  final service = JustAudioQuranAudioService(localResolver: resolver);
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

final selectedReciterProvider =
    NotifierProvider<SelectedReciterNotifier, Reciter>(
  SelectedReciterNotifier.new,
);

class SelectedReciterNotifier extends Notifier<Reciter> {
  @override
  Reciter build() {
    _load();
    return ReciterCatalog.alafasy;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_kReciterId);
      if (id != null) {
        state = ReciterCatalog.byId(id);
      }
    } catch (_) {}
  }

  Future<void> select(Reciter reciter) async {
    state = reciter;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kReciterId, reciter.id);
    } catch (_) {}
  }

  Future<void> selectById(String id) => select(ReciterCatalog.byId(id));
}

final audioControllerProvider =
    NotifierProvider<AudioController, AudioPlaybackState>(
  AudioController.new,
);

class AudioController extends Notifier<AudioPlaybackState> {
  QuranAudioService get _service => ref.read(quranAudioServiceProvider);

  final List<StreamSubscription<dynamic>> _subs = [];
  bool _listening = false;

  @override
  AudioPlaybackState build() {
    ref.onDispose(_cancelSubs);
    // Ne pas `watch` le récitateur ici : un changement de préférence
    // ne doit pas réinitialiser l'état de lecture (voir [changeReciter]).
    return AudioPlaybackState(reciter: ReciterCatalog.alafasy);
  }

  void _ensureListening() {
    if (_listening) return;
    _listening = true;
    final service = _service;

    _subs.add(
      service.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );
    _subs.add(
      service.durationStream.listen((dur) {
        if (dur != null) {
          state = state.copyWith(duration: dur);
        }
      }),
    );
    _subs.add(
      service.currentIndexStream.listen((index) {
        // Pas de sync verset pour les fichiers « sourate complète ».
        if (!state.reciter.supportsVerseSync) return;
        if (index == null || state.verseCount == null) return;
        final ayah = index + 1;
        state = state.copyWith(ayahNumber: ayah);
      }),
    );
    _subs.add(
      service.playerEventStream.listen(_onPlayerEvent),
    );
  }

  void _onPlayerEvent(QuranAudioPlayerEvent event) {
    switch (event.kind) {
      case QuranAudioPlayerEventKind.loading:
        state = state.copyWith(
          status: AudioStatus.loading,
          clearError: true,
        );
      case QuranAudioPlayerEventKind.ready:
        if (state.status == AudioStatus.loading) {
          state = state.copyWith(status: AudioStatus.paused, clearError: true);
        }
      case QuranAudioPlayerEventKind.playing:
        state = state.copyWith(status: AudioStatus.playing, clearError: true);
      case QuranAudioPlayerEventKind.paused:
        if (state.status != AudioStatus.completed) {
          state = state.copyWith(status: AudioStatus.paused);
        }
      case QuranAudioPlayerEventKind.completed:
        state = state.copyWith(
          status: AudioStatus.completed,
          position: state.duration,
        );
      case QuranAudioPlayerEventKind.error:
        state = state.copyWith(
          status: AudioStatus.error,
          errorMessage: event.message ?? 'Erreur audio',
        );
    }
  }

  Future<void> playSurah({
    required int surahId,
    required int verseCount,
    int startAyah = 1,
    Reciter? reciter,
  }) async {
    _ensureListening();
    final Reciter chosen = reciter ?? ref.read(selectedReciterProvider);
    if (reciter != null) {
      await ref.read(selectedReciterProvider.notifier).select(chosen);
    }

    state = state.copyWith(
      status: AudioStatus.loading,
      surahId: surahId,
      ayahNumber:
          chosen.supportsVerseSync ? startAyah.clamp(1, verseCount) : null,
      verseCount: verseCount,
      reciter: chosen,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
      clearAyah: !chosen.supportsVerseSync,
    );

    try {
      await _service.loadSurah(
        reciter: chosen,
        surahId: surahId,
        verseCount: verseCount,
        startAyah: startAyah,
      );
      await _service.play();
    } catch (e) {
      state = state.copyWith(
        status: AudioStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> togglePlayPause({
    required int surahId,
    required int verseCount,
    int startAyah = 1,
  }) async {
    if (state.status == AudioStatus.playing && state.surahId == surahId) {
      await pause();
      return;
    }
    if (state.status == AudioStatus.paused &&
        state.surahId == surahId &&
        state.verseCount != null) {
      await resume();
      return;
    }
    await playSurah(
      surahId: surahId,
      verseCount: verseCount,
      startAyah: startAyah,
    );
  }

  Future<void> pause() async {
    _ensureListening();
    await _service.pause();
  }

  Future<void> resume() async {
    _ensureListening();
    await _service.play();
  }

  Future<void> stop() async {
    _ensureListening();
    await _service.stop();
    state = state.copyWith(
      status: AudioStatus.idle,
      clearSurah: true,
      position: Duration.zero,
      duration: Duration.zero,
      clearError: true,
    );
  }

  Future<void> next() async {
    if (!state.isActive && state.status != AudioStatus.completed) return;
    _ensureListening();
    await _service.next();
  }

  Future<void> previous() async {
    if (!state.isActive && state.status != AudioStatus.completed) return;
    _ensureListening();
    await _service.previous();
  }

  Future<void> seekToVerse(int ayahNumber) async {
    if (state.verseCount == null) return;
    _ensureListening();
    await _service.seekToVerse(ayahNumber);
  }

  /// Change de récitateur : recharge la sourate en cours si active.
  Future<void> changeReciter(Reciter reciter) async {
    await ref.read(selectedReciterProvider.notifier).select(reciter);
    final surahId = state.surahId;
    final verseCount = state.verseCount;
    final ayah = state.ayahNumber ?? 1;
    final wasPlaying = state.status == AudioStatus.playing;

    if (surahId == null || verseCount == null) {
      state = state.copyWith(
        reciter: reciter,
        clearAyah: !reciter.supportsVerseSync,
      );
      return;
    }

    state = state.copyWith(
      reciter: reciter,
      status: AudioStatus.loading,
      ayahNumber: reciter.supportsVerseSync ? ayah : null,
      clearAyah: !reciter.supportsVerseSync,
    );
    try {
      await _service.loadSurah(
        reciter: reciter,
        surahId: surahId,
        verseCount: verseCount,
        startAyah: ayah,
      );
      if (wasPlaying) {
        await _service.play();
      } else {
        state = state.copyWith(status: AudioStatus.paused, clearError: true);
      }
    } catch (e) {
      state = state.copyWith(
        status: AudioStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _cancelSubs() {
    for (final sub in _subs) {
      unawaited(sub.cancel());
    }
    _subs.clear();
    _listening = false;
  }
}
