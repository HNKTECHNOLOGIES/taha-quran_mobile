import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_download.dart';
import '../../domain/repositories/audio_download_repository.dart';
import '../audio_storage_paths.dart';
import '../datasources/audio_download_index_store.dart';
import '../quran_audio_url_builder.dart';
import '../services/audio_file_downloader.dart';

const _kWifiOnly = 'audio_download_wifi_only';

class AudioDownloadRepositoryImpl implements AudioDownloadRepository {
  AudioDownloadRepositoryImpl._({
    required this.paths,
    required this.store,
    required this.downloader,
    required this.urlBuilder,
    required this._connectivity,
    SharedPreferences? prefs,
    this._wifiConnectedCheck,
  }) : _prefsOverride = prefs;

  factory AudioDownloadRepositoryImpl({
    AudioStoragePaths? paths,
    AudioDownloadIndexStore? store,
    AudioFileDownloader? downloader,
    QuranAudioUrlBuilder urlBuilder = const QuranAudioUrlBuilder(),
    Connectivity? connectivity,
    SharedPreferences? prefs,
    Future<bool> Function()? wifiConnectedCheck,
  }) {
    final resolvedPaths = paths ?? AudioStoragePaths();
    return AudioDownloadRepositoryImpl._(
      paths: resolvedPaths,
      store: store ?? AudioDownloadIndexStore(paths: resolvedPaths),
      downloader: downloader ?? AudioFileDownloader(paths: resolvedPaths),
      urlBuilder: urlBuilder,
      connectivity: connectivity ?? Connectivity(),
      prefs: prefs,
      wifiConnectedCheck: wifiConnectedCheck,
    );
  }

  final AudioStoragePaths paths;
  final AudioDownloadIndexStore store;
  final AudioFileDownloader downloader;
  final QuranAudioUrlBuilder urlBuilder;
  final Connectivity _connectivity;
  final SharedPreferences? _prefsOverride;
  final Future<bool> Function()? _wifiConnectedCheck;

  final _controller =
      StreamController<Map<String, SurahDownload>>.broadcast();
  final Map<String, CancelToken> _tokens = {};
  Map<String, SurahDownload>? _cache;
  bool _loaded = false;

  Future<SharedPreferences> _prefs() async =>
      _prefsOverride ?? SharedPreferences.getInstance();

  Future<Map<String, SurahDownload>> _ensureLoaded() async {
    if (_loaded && _cache != null) return _cache!;
    _cache = await store.load();
    _loaded = true;
    return _cache!;
  }

  Future<void> _emit() async {
    final all = await _ensureLoaded();
    if (!_controller.isClosed) {
      _controller.add(Map<String, SurahDownload>.from(all));
    }
  }

  Future<void> _upsert(SurahDownload download) async {
    final all = await _ensureLoaded();
    all[download.key] = download;
    await store.save(all);
    await _emit();
  }

  @override
  Stream<Map<String, SurahDownload>> watchDownloads() async* {
    yield await _ensureLoaded();
    yield* _controller.stream;
  }

  @override
  Future<Map<String, SurahDownload>> getDownloads() => _ensureLoaded();

  @override
  Future<SurahDownload?> getDownload({
    required String reciterId,
    required int surahId,
  }) async {
    final all = await _ensureLoaded();
    return all[SurahDownload.keyOf(reciterId, surahId)];
  }

  @override
  Future<bool> isSurahDownloaded({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    final files = await paths.expectedFiles(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    );
    for (final f in files) {
      if (!await f.exists() || await f.length() <= 0) return false;
    }
    return files.isNotEmpty;
  }

  @override
  Future<List<Uri>> localPlaylistUris({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    if (!await isSurahDownloaded(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    )) {
      return const [];
    }
    final files = await paths.expectedFiles(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    );
    return [for (final f in files) Uri.file(f.path)];
  }

  @override
  Future<bool> getWifiOnly() async {
    final prefs = await _prefs();
    return prefs.getBool(_kWifiOnly) ?? true;
  }

  @override
  Future<void> setWifiOnly(bool value) async {
    final prefs = await _prefs();
    await prefs.setBool(_kWifiOnly, value);
  }

  @override
  Future<bool> isWifiConnected() async {
    final override = _wifiConnectedCheck;
    if (override != null) {
      return override();
    }
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isEmpty) return false;
      return results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );
    } catch (_) {
      // Plateformes / tests sans plugin : ne pas bloquer.
      return true;
    }
  }

  Future<void> _assertNetworkAllowed() async {
    final wifiOnly = await getWifiOnly();
    if (!wifiOnly) return;
    if (!await isWifiConnected()) {
      throw const DownloadException(
        DownloadErrorCode.wifiRequired,
        'Wi-Fi requis pour télécharger',
      );
    }
  }

  @override
  Future<void> downloadSurah({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
  }) async {
    final key = SurahDownload.keyOf(reciter.id, surahId);
    final existingToken = _tokens[key];
    if (existingToken != null && !existingToken.isCancelled) {
      return;
    }

    await _assertNetworkAllowed();

    final files = await paths.expectedFiles(
      reciter: reciter,
      surahId: surahId,
      verseCount: verseCount,
    );
    final filesTotal = files.length;
    var filesCompleted = 0;
    for (final f in files) {
      if (await f.exists() && await f.length() > 0) filesCompleted++;
    }

    if (filesCompleted == filesTotal) {
      await _upsert(
        SurahDownload(
          reciterId: reciter.id,
          surahId: surahId,
          verseCount: verseCount,
          status: SurahDownloadStatus.downloaded,
          progress: 1,
          filesCompleted: filesTotal,
          filesTotal: filesTotal,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      return;
    }

    final token = CancelToken();
    _tokens[key] = token;

    var overallReceived = 0;
    final fileSizes = List<int>.filled(filesTotal, 0);

    await _upsert(
      SurahDownload(
        reciterId: reciter.id,
        surahId: surahId,
        verseCount: verseCount,
        status: SurahDownloadStatus.downloading,
        progress: filesTotal == 0 ? 0 : filesCompleted / filesTotal,
        filesCompleted: filesCompleted,
        filesTotal: filesTotal,
        errorMessage: null,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    try {
      for (var i = 0; i < files.length; i++) {
        if (token.isCancelled) {
          throw const DownloadException(
            DownloadErrorCode.cancelled,
            'Téléchargement annulé',
          );
        }
        final file = files[i];
        if (await file.exists() && await file.length() > 0) {
          fileSizes[i] = await file.length();
          continue;
        }

        final url = _remoteUri(
          reciter: reciter,
          surahId: surahId,
          verseCount: verseCount,
          fileIndex: i,
        );

        await downloader.downloadFile(
          url: url,
          target: file,
          cancelToken: token,
          onProgress: ({required int received, required int total}) {
            fileSizes[i] = total > 0 ? total : received;
            overallReceived = 0;
            for (var j = 0; j < filesTotal; j++) {
              if (j < i) {
                overallReceived += fileSizes[j];
              } else if (j == i) {
                overallReceived += received;
              }
            }
            final overallTotal = fileSizes.fold<int>(0, (a, b) => a + b);
            final fileProgress = filesTotal == 0
                ? 0.0
                : (i + (total > 0 ? received / total : 0)) / filesTotal;
            unawaited(
              _upsert(
                SurahDownload(
                  reciterId: reciter.id,
                  surahId: surahId,
                  verseCount: verseCount,
                  status: SurahDownloadStatus.downloading,
                  progress: fileProgress.clamp(0.0, 0.999),
                  downloadedBytes: overallReceived,
                  totalBytes: overallTotal > 0 ? overallTotal : null,
                  filesCompleted: i,
                  filesTotal: filesTotal,
                  updatedAtMs: DateTime.now().millisecondsSinceEpoch,
                ),
              ),
            );
          },
        );
        filesCompleted = i + 1;
      }

      if (!await isSurahDownloaded(
        reciter: reciter,
        surahId: surahId,
        verseCount: verseCount,
      )) {
        throw const DownloadException(
          DownloadErrorCode.incomplete,
          'Téléchargement incomplet',
        );
      }

      await _upsert(
        SurahDownload(
          reciterId: reciter.id,
          surahId: surahId,
          verseCount: verseCount,
          status: SurahDownloadStatus.downloaded,
          progress: 1,
          downloadedBytes: overallReceived,
          filesCompleted: filesTotal,
          filesTotal: filesTotal,
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } on DownloadException catch (e) {
      if (e.code == DownloadErrorCode.cancelled) {
        await _upsert(
          SurahDownload(
            reciterId: reciter.id,
            surahId: surahId,
            verseCount: verseCount,
            status: SurahDownloadStatus.paused,
            progress: filesTotal == 0 ? 0 : filesCompleted / filesTotal,
            filesCompleted: filesCompleted,
            filesTotal: filesTotal,
            errorMessage: e.message,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        await _upsert(
          SurahDownload(
            reciterId: reciter.id,
            surahId: surahId,
            verseCount: verseCount,
            status: SurahDownloadStatus.failed,
            progress: filesTotal == 0 ? 0 : filesCompleted / filesTotal,
            filesCompleted: filesCompleted,
            filesTotal: filesTotal,
            errorMessage: e.message,
            updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        rethrow;
      }
    } catch (e) {
      await _upsert(
        SurahDownload(
          reciterId: reciter.id,
          surahId: surahId,
          verseCount: verseCount,
          status: SurahDownloadStatus.failed,
          progress: filesTotal == 0 ? 0 : filesCompleted / filesTotal,
          filesCompleted: filesCompleted,
          filesTotal: filesTotal,
          errorMessage: e.toString(),
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      rethrow;
    } finally {
      _tokens.remove(key);
    }
  }

  Uri _remoteUri({
    required Reciter reciter,
    required int surahId,
    required int verseCount,
    required int fileIndex,
  }) {
    if (reciter.mode == ReciterAudioMode.fullSurah) {
      return urlBuilder.surahUri(reciter: reciter, surahId: surahId);
    }
    final ayah = fileIndex + 1;
    return urlBuilder.verseUri(
      reciter: reciter,
      surahId: surahId,
      ayahNumber: ayah,
    );
  }

  @override
  Future<void> cancelDownload({
    required String reciterId,
    required int surahId,
  }) async {
    final key = SurahDownload.keyOf(reciterId, surahId);
    final token = _tokens[key];
    if (token != null && !token.isCancelled) {
      token.cancel('Annulé par l’utilisateur');
    }
  }

  @override
  Future<void> deleteDownload({
    required Reciter reciter,
    required int surahId,
  }) async {
    await cancelDownload(reciterId: reciter.id, surahId: surahId);
    final dir = await paths.surahDir(reciterId: reciter.id, surahId: surahId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final all = await _ensureLoaded();
    all.remove(SurahDownload.keyOf(reciter.id, surahId));
    await store.save(all);
    await _emit();
  }

  Future<void> dispose() async {
    for (final t in _tokens.values) {
      if (!t.isCancelled) t.cancel();
    }
    _tokens.clear();
    await _controller.close();
  }
}
