import 'reciter.dart';

/// État d’un téléchargement audio (sourate × récitateur).
enum SurahDownloadStatus {
  notDownloaded,
  downloading,
  paused,
  downloaded,
  failed,
}

class SurahDownload {
  const SurahDownload({
    required this.reciterId,
    required this.surahId,
    required this.verseCount,
    required this.status,
    this.progress = 0,
    this.downloadedBytes = 0,
    this.totalBytes,
    this.filesCompleted = 0,
    this.filesTotal = 1,
    this.errorMessage,
    this.updatedAtMs,
  });

  final String reciterId;
  final int surahId;
  final int verseCount;
  final SurahDownloadStatus status;

  /// Progression globale 0..1.
  final double progress;
  final int downloadedBytes;
  final int? totalBytes;
  final int filesCompleted;
  final int filesTotal;
  final String? errorMessage;
  final int? updatedAtMs;

  bool get isDownloaded => status == SurahDownloadStatus.downloaded;
  bool get isDownloading => status == SurahDownloadStatus.downloading;
  bool get canResume =>
      status == SurahDownloadStatus.paused ||
      status == SurahDownloadStatus.failed ||
      (status == SurahDownloadStatus.notDownloaded && filesCompleted > 0);

  SurahDownload copyWith({
    String? reciterId,
    int? surahId,
    int? verseCount,
    SurahDownloadStatus? status,
    double? progress,
    int? downloadedBytes,
    int? totalBytes,
    int? filesCompleted,
    int? filesTotal,
    String? errorMessage,
    int? updatedAtMs,
    bool clearError = false,
    bool clearTotalBytes = false,
  }) {
    return SurahDownload(
      reciterId: reciterId ?? this.reciterId,
      surahId: surahId ?? this.surahId,
      verseCount: verseCount ?? this.verseCount,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: clearTotalBytes ? null : (totalBytes ?? this.totalBytes),
      filesCompleted: filesCompleted ?? this.filesCompleted,
      filesTotal: filesTotal ?? this.filesTotal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'surahId': surahId,
        'verseCount': verseCount,
        'status': status.name,
        'progress': progress,
        'downloadedBytes': downloadedBytes,
        'totalBytes': totalBytes,
        'filesCompleted': filesCompleted,
        'filesTotal': filesTotal,
        'errorMessage': errorMessage,
        'updatedAtMs': updatedAtMs,
      };

  factory SurahDownload.fromJson(Map<String, dynamic> json) {
    return SurahDownload(
      reciterId: json['reciterId'] as String,
      surahId: json['surahId'] as int,
      verseCount: json['verseCount'] as int? ?? 1,
      status: SurahDownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SurahDownloadStatus.notDownloaded,
      ),
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      downloadedBytes: json['downloadedBytes'] as int? ?? 0,
      totalBytes: json['totalBytes'] as int?,
      filesCompleted: json['filesCompleted'] as int? ?? 0,
      filesTotal: json['filesTotal'] as int? ?? 1,
      errorMessage: json['errorMessage'] as String?,
      updatedAtMs: json['updatedAtMs'] as int?,
    );
  }

  static String keyOf(String reciterId, int surahId) => '$reciterId:$surahId';

  String get key => keyOf(reciterId, surahId);
}

class DownloadException implements Exception {
  const DownloadException(this.code, this.message);

  final DownloadErrorCode code;
  final String message;

  @override
  String toString() => message;
}

enum DownloadErrorCode {
  wifiRequired,
  network,
  incomplete,
  storage,
  cancelled,
  unknown,
}

/// Préférences liées aux téléchargements.
class DownloadSettings {
  const DownloadSettings({this.wifiOnly = true});

  final bool wifiOnly;

  DownloadSettings copyWith({bool? wifiOnly}) =>
      DownloadSettings(wifiOnly: wifiOnly ?? this.wifiOnly);
}

/// Contexte d’un téléchargement demandé.
class SurahDownloadRequest {
  const SurahDownloadRequest({
    required this.reciter,
    required this.surahId,
    required this.verseCount,
  });

  final Reciter reciter;
  final int surahId;
  final int verseCount;
}
