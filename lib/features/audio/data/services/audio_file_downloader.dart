import 'dart:io';

import 'package:dio/dio.dart';

import '../../domain/entities/surah_download.dart';
import '../audio_storage_paths.dart';

typedef DownloadProgressCallback = void Function({
  required int received,
  required int total,
});

/// Télécharge un fichier MP3 via dio, avec reprise partielle si possible.
class AudioFileDownloader {
  AudioFileDownloader({
    Dio? dio,
    AudioStoragePaths? paths,
  })  : _dio = dio ?? Dio(),
        paths = paths ?? AudioStoragePaths();

  final Dio _dio;
  final AudioStoragePaths paths;

  /// Télécharge [url] vers [target]. Reprend via Range si un `.part` existe.
  Future<void> downloadFile({
    required Uri url,
    required File target,
    required CancelToken cancelToken,
    DownloadProgressCallback? onProgress,
  }) async {
    final part = paths.partFileFor(target);
    try {
      if (await target.exists() && await target.length() > 0) {
        onProgress?.call(received: await target.length(), total: await target.length());
        return;
      }

      var start = 0;
      if (await part.exists()) {
        start = await part.length();
      }

      final headers = <String, dynamic>{};
      if (start > 0) {
        headers['Range'] = 'bytes=$start-';
      }

      Response<ResponseBody> response;
      try {
        response = await _dio.getUri<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
            followRedirects: true,
            validateStatus: (code) =>
                code != null && (code == 200 || code == 206),
            receiveTimeout: const Duration(minutes: 5),
          ),
          cancelToken: cancelToken,
        );
      } on DioException catch (e) {
        throw _mapDio(e);
      }

      final status = response.statusCode ?? 0;
      if (status == 200 && start > 0) {
        // Serveur ignore Range : on repart de zéro.
        if (await part.exists()) await part.delete();
        start = 0;
      }

      final contentLengthHeader = response.headers.value('content-length');
      final chunkLength = int.tryParse(contentLengthHeader ?? '') ?? -1;
      final totalKnown = chunkLength < 0
          ? -1
          : (status == 206 ? start + chunkLength : chunkLength);

      final sink = part.openWrite(mode: FileMode.append);
      var received = start;
      try {
        await for (final chunk in response.data!.stream) {
          if (cancelToken.isCancelled) {
            throw const DownloadException(
              DownloadErrorCode.cancelled,
              'Téléchargement annulé',
            );
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(
            received: received,
            total: totalKnown > 0 ? totalKnown : received,
          );
        }
        await sink.flush();
      } on DownloadException {
        rethrow;
      } on DioException catch (e) {
        throw _mapDio(e);
      } on FileSystemException catch (e) {
        throw DownloadException(
          DownloadErrorCode.storage,
          'Stockage insuffisant ou inaccessible: ${e.message}',
        );
      } finally {
        await sink.close();
      }

      if (cancelToken.isCancelled) {
        throw const DownloadException(
          DownloadErrorCode.cancelled,
          'Téléchargement annulé',
        );
      }

      final partLen = await part.length();
      if (partLen <= 0) {
        throw const DownloadException(
          DownloadErrorCode.incomplete,
          'Fichier téléchargé vide',
        );
      }
      if (totalKnown > 0 && partLen < totalKnown) {
        throw DownloadException(
          DownloadErrorCode.incomplete,
          'Téléchargement incomplet ($partLen / $totalKnown octets)',
        );
      }

      if (await target.exists()) {
        await target.delete();
      }
      await part.rename(target.path);
    } on DownloadException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDio(e);
    } on FileSystemException catch (e) {
      throw DownloadException(
        DownloadErrorCode.storage,
        'Stockage insuffisant ou inaccessible: ${e.message}',
      );
    } catch (e) {
      if (e is DownloadException) rethrow;
      throw DownloadException(DownloadErrorCode.unknown, e.toString());
    }
  }

  DownloadException _mapDio(DioException e) {
    if (CancelToken.isCancel(e) || e.type == DioExceptionType.cancel) {
      return const DownloadException(
        DownloadErrorCode.cancelled,
        'Téléchargement annulé',
      );
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return DownloadException(
          DownloadErrorCode.network,
          'Erreur réseau: ${e.message ?? e.type.name}',
        );
      case DioExceptionType.badResponse:
        return DownloadException(
          DownloadErrorCode.network,
          'Réponse HTTP ${e.response?.statusCode}',
        );
      case DioExceptionType.unknown:
        final err = e.error;
        if (err is FileSystemException) {
          return DownloadException(
            DownloadErrorCode.storage,
            'Stockage insuffisant ou inaccessible: ${err.message}',
          );
        }
        return DownloadException(
          DownloadErrorCode.network,
          e.message ?? 'Erreur réseau',
        );
      case DioExceptionType.badCertificate:
        return DownloadException(
          DownloadErrorCode.network,
          'Certificat invalide',
        );
      case DioExceptionType.cancel:
        return const DownloadException(
          DownloadErrorCode.cancelled,
          'Téléchargement annulé',
        );
      case DioExceptionType.transformTimeout:
        return DownloadException(
          DownloadErrorCode.network,
          'Timeout de transformation: ${e.message ?? e.type.name}',
        );
    }
  }
}
