import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_mobile/features/audio/data/audio_storage_paths.dart';
import 'package:quran_mobile/features/audio/data/datasources/audio_download_index_store.dart';
import 'package:quran_mobile/features/audio/data/local_audio_source_resolver.dart';
import 'package:quran_mobile/features/audio/data/reciter_catalog.dart';
import 'package:quran_mobile/features/audio/data/repositories/audio_download_repository_impl.dart';
import 'package:quran_mobile/features/audio/data/services/audio_file_downloader.dart';
import 'package:quran_mobile/features/audio/domain/entities/surah_download.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.bodies);

  /// Clé = path segment final (ex. `001001.mp3`), valeur = bytes.
  final Map<String, List<int>> bodies;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final name = options.uri.pathSegments.isEmpty
        ? ''
        : options.uri.pathSegments.last;
    final bytes = bodies[name];
    if (bytes == null) {
      return ResponseBody.fromString('missing', 404);
    }

    final range = options.headers['Range']?.toString();
    if (range != null && range.startsWith('bytes=')) {
      final start = int.parse(range.substring(6).split('-').first);
      final slice = bytes.sublist(start);
      return ResponseBody.fromBytes(
        slice,
        206,
        headers: {
          Headers.contentLengthHeader: [slice.length.toString()],
          'content-range': ['bytes $start-${bytes.length - 1}/${bytes.length}'],
        },
      );
    }

    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentLengthHeader: [bytes.length.toString()],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AudioStoragePaths paths;
  late Dio dio;
  late _FakeAdapter adapter;
  late AudioDownloadRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'audio_download_wifi_only': false});
    tempDir = await Directory.systemTemp.createTemp('taha_audio_test_');
    paths = AudioStoragePaths(rootOverride: tempDir);
    dio = Dio();
    adapter = _FakeAdapter({
      '001001.mp3': utf8.encode('ayah1-audio'),
      '001002.mp3': utf8.encode('ayah2-audio-data'),
      '001003.mp3': utf8.encode('ayah3'),
      '001004.mp3': utf8.encode('ayah4-bytes'),
      '001005.mp3': utf8.encode('ayah5-content'),
      '001006.mp3': utf8.encode('ayah6'),
      '001007.mp3': utf8.encode('ayah7-file'),
      '001.mp3': utf8.encode('full-surah-badr'),
    });
    dio.httpClientAdapter = adapter;

    final prefs = await SharedPreferences.getInstance();
    repo = AudioDownloadRepositoryImpl(
      paths: paths,
      store: AudioDownloadIndexStore(paths: paths),
      downloader: AudioFileDownloader(dio: dio, paths: paths),
      prefs: prefs,
    );
  });

  tearDown(() async {
    await repo.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AudioStoragePaths', () {
    test('construit les chemins verse et sourate', () async {
      final verse = await paths.verseFile(
        reciterId: 'alafasy',
        surahId: 1,
        ayahNumber: 1,
      );
      expect(verse.path, contains('alafasy'));
      expect(verse.path, endsWith('001001.mp3'));

      final full = await paths.fullSurahFile(
        reciterId: 'badr_touarique',
        surahId: 1,
      );
      expect(full.path, endsWith('001.mp3'));
    });
  });

  group('AudioDownloadIndexStore', () {
    test('persiste et recharge un statut', () async {
      final store = AudioDownloadIndexStore(paths: paths);
      await store.upsert(
        const SurahDownload(
          reciterId: 'alafasy',
          surahId: 1,
          verseCount: 7,
          status: SurahDownloadStatus.downloaded,
          progress: 1,
          filesCompleted: 7,
          filesTotal: 7,
        ),
      );
      final loaded = await store.load();
      expect(loaded['alafasy:1']?.status, SurahDownloadStatus.downloaded);
      expect(loaded['alafasy:1']?.filesTotal, 7);
    });
  });

  group('AudioDownloadRepositoryImpl', () {
    test('télécharge Al-Fatiha verse-par-verset et marque downloaded', () async {
      await repo.downloadSurah(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );

      final ok = await repo.isSurahDownloaded(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );
      expect(ok, isTrue);
      expect(adapter.requests.length, 7);

      final status = await repo.getDownload(reciterId: 'alafasy', surahId: 1);
      expect(status?.status, SurahDownloadStatus.downloaded);
      expect(status?.progress, 1);
    });

    test('reprise : saute les fichiers déjà présents', () async {
      final first = await paths.verseFile(
        reciterId: 'alafasy',
        surahId: 1,
        ayahNumber: 1,
      );
      await first.parent.create(recursive: true);
      await first.writeAsString('already');

      await repo.downloadSurah(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );

      expect(adapter.requests.length, 6);
      expect(
        await repo.isSurahDownloaded(
          reciter: ReciterCatalog.alafasy,
          surahId: 1,
          verseCount: 7,
        ),
        isTrue,
      );
    });

    test('télécharge Badr (sourate complète) en un fichier', () async {
      await repo.downloadSurah(
        reciter: ReciterCatalog.badrTouarique,
        surahId: 1,
        verseCount: 7,
      );
      expect(adapter.requests.length, 1);
      expect(adapter.requests.first.uri.pathSegments.last, '001.mp3');
      expect(
        await repo.isSurahDownloaded(
          reciter: ReciterCatalog.badrTouarique,
          surahId: 1,
          verseCount: 7,
        ),
        isTrue,
      );
    });

    test('suppression efface les fichiers et l’index', () async {
      await repo.downloadSurah(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );
      await repo.deleteDownload(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
      );
      expect(
        await repo.isSurahDownloaded(
          reciter: ReciterCatalog.alafasy,
          surahId: 1,
          verseCount: 7,
        ),
        isFalse,
      );
      expect(await repo.getDownload(reciterId: 'alafasy', surahId: 1), isNull);
    });

    test('Wi-Fi only bloque sans Wi-Fi', () async {
      final prefs = await SharedPreferences.getInstance();
      final blocked = AudioDownloadRepositoryImpl(
        paths: paths,
        store: AudioDownloadIndexStore(paths: paths),
        downloader: AudioFileDownloader(dio: dio, paths: paths),
        prefs: prefs,
        wifiConnectedCheck: () async => false,
      );
      await blocked.setWifiOnly(true);
      expect(
        () => blocked.downloadSurah(
          reciter: ReciterCatalog.alafasy,
          surahId: 1,
          verseCount: 7,
        ),
        throwsA(
          isA<DownloadException>().having(
            (e) => e.code,
            'code',
            DownloadErrorCode.wifiRequired,
          ),
        ),
      );
      await blocked.dispose();
    });
  });

  group('LocalAudioSourceResolver', () {
    test('renvoie file:// si téléchargé, sinon https', () async {
      final resolver = LocalAudioSourceResolver(downloads: repo);
      final remote = await resolver.resolvePlaylist(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );
      expect(remote.every((u) => u.scheme == 'https'), isTrue);

      await repo.downloadSurah(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );
      final local = await resolver.resolvePlaylist(
        reciter: ReciterCatalog.alafasy,
        surahId: 1,
        verseCount: 7,
      );
      expect(local.length, 7);
      expect(local.every((u) => u.scheme == 'file'), isTrue);
    });
  });

  group('AudioFileDownloader resume Range', () {
    test('reprend un .part existant', () async {
      final target = await paths.verseFile(
        reciterId: 'alafasy',
        surahId: 1,
        ayahNumber: 1,
      );
      await target.parent.create(recursive: true);
      final part = paths.partFileFor(target);
      await part.writeAsBytes(utf8.encode('ayah'));

      final downloader = AudioFileDownloader(dio: dio, paths: paths);
      await downloader.downloadFile(
        url: Uri.parse('https://example.test/001001.mp3'),
        target: target,
        cancelToken: CancelToken(),
      );

      expect(await target.readAsString(), 'ayah1-audio');
      expect(await part.exists(), isFalse);
      final rangeReq = adapter.requests.where(
        (r) => r.headers['Range'] != null,
      );
      expect(rangeReq, isNotEmpty);
    });
  });
}
