import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/local_audio_source_resolver.dart';
import '../../data/repositories/audio_download_repository_impl.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_download.dart';
import '../../domain/repositories/audio_download_repository.dart';

final audioDownloadRepositoryProvider = Provider<AudioDownloadRepository>((ref) {
  final repo = AudioDownloadRepositoryImpl();
  ref.onDispose(() {
    unawaited(repo.dispose());
  });
  return repo;
});

final localAudioSourceResolverProvider = Provider<LocalAudioSourceResolver>((ref) {
  return LocalAudioSourceResolver(
    downloads: ref.watch(audioDownloadRepositoryProvider),
  );
});

final downloadsMapProvider =
    StreamProvider<Map<String, SurahDownload>>((ref) {
  return ref.watch(audioDownloadRepositoryProvider).watchDownloads();
});

final surahDownloadProvider =
    Provider.family<SurahDownload?, ({String reciterId, int surahId})>((
  ref,
  args,
) {
  final map = ref.watch(downloadsMapProvider).asData?.value;
  if (map == null) return null;
  return map[SurahDownload.keyOf(args.reciterId, args.surahId)];
});

final wifiOnlyDownloadProvider =
    NotifierProvider<WifiOnlyDownloadNotifier, bool>(
  WifiOnlyDownloadNotifier.new,
);

class WifiOnlyDownloadNotifier extends Notifier<bool> {
  static const _k = 'audio_download_wifi_only';

  @override
  bool build() {
    _load();
    return true;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool(_k) ?? true;
    } catch (_) {}
  }

  Future<void> setWifiOnly(bool value) async {
    state = value;
    await ref.read(audioDownloadRepositoryProvider).setWifiOnly(value);
  }
}

final downloadControllerProvider =
    NotifierProvider<DownloadController, DownloadControllerState>(
  DownloadController.new,
);

class DownloadControllerState {
  const DownloadControllerState({this.lastError});

  final String? lastError;

  DownloadControllerState copyWith({String? lastError, bool clearError = false}) {
    return DownloadControllerState(
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

class DownloadController extends Notifier<DownloadControllerState> {
  @override
  DownloadControllerState build() => const DownloadControllerState();

  AudioDownloadRepository get _repo =>
      ref.read(audioDownloadRepositoryProvider);

  Future<void> downloadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      await _repo.downloadSurah(
        reciter: reciter,
        surahId: surahId,
        verseCount: verseCount,
      );
    } on DownloadException catch (e) {
      state = state.copyWith(lastError: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(lastError: e.toString());
      rethrow;
    }
  }

  Future<void> cancel({
    required String reciterId,
    required int surahId,
  }) {
    return _repo.cancelDownload(reciterId: reciterId, surahId: surahId);
  }

  Future<void> delete({
    required Reciter reciter,
    required int surahId,
  }) {
    return _repo.deleteDownload(reciter: reciter, surahId: surahId);
  }
}
