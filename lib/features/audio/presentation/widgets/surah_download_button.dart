import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/reciter.dart';
import '../../domain/entities/surah_download.dart';
import '../providers/audio_providers.dart';
import '../providers/download_providers.dart';

/// Bouton de téléchargement / progression pour une sourate (récitateur actif).
class SurahDownloadButton extends ConsumerWidget {
  const SurahDownloadButton({
    super.key,
    required this.surahId,
    required this.verseCount,
    required this.strings,
    this.compact = false,
  });

  final int surahId;
  final int verseCount;
  final AppStrings strings;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reciter = ref.watch(selectedReciterProvider);
    final download = ref.watch(
      surahDownloadProvider((reciterId: reciter.id, surahId: surahId)),
    );
    final status = download?.status ?? SurahDownloadStatus.notDownloaded;
    final progress = download?.progress ?? 0.0;

    Future<void> start() async {
      try {
        await ref.read(downloadControllerProvider.notifier).downloadSurah(
              reciter: reciter,
              surahId: surahId,
              verseCount: verseCount,
            );
      } on DownloadException catch (e) {
        if (!context.mounted) return;
        final msg = switch (e.code) {
          DownloadErrorCode.wifiRequired => strings.wifiRequiredError,
          DownloadErrorCode.storage => strings.downloadStorageError,
          DownloadErrorCode.network => strings.downloadNetworkError,
          _ => e.message,
        };
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }

    Future<void> cancel() => ref
        .read(downloadControllerProvider.notifier)
        .cancel(reciterId: reciter.id, surahId: surahId);

    Future<void> delete() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(strings.deleteDownload),
          content: Text(strings.confirmDeleteDownload),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(strings.cancelDownload),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(strings.deleteDownload),
            ),
          ],
        ),
      );
      if (ok == true) {
        await ref
            .read(downloadControllerProvider.notifier)
            .delete(reciter: reciter, surahId: surahId);
      }
    }

    if (compact) {
      return _CompactIcon(
        status: status,
        progress: progress,
        strings: strings,
        onDownload: start,
        onCancel: cancel,
        onDelete: delete,
        onResume: start,
      );
    }

    return _BannerButton(
      status: status,
      progress: progress,
      strings: strings,
      reciter: reciter,
      onDownload: start,
      onCancel: cancel,
      onDelete: delete,
      onResume: start,
    );
  }
}

class _CompactIcon extends StatelessWidget {
  const _CompactIcon({
    required this.status,
    required this.progress,
    required this.strings,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onResume,
  });

  final SurahDownloadStatus status;
  final double progress;
  final AppStrings strings;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SurahDownloadStatus.downloaded:
        return IconButton(
          tooltip: strings.offlineAudioReady,
          onPressed: onDelete,
          icon: const Icon(Icons.download_done_rounded, color: AppColors.goldSoft),
        );
      case SurahDownloadStatus.downloading:
        return IconButton(
          tooltip: strings.cancelDownload,
          onPressed: onCancel,
          icon: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              value: progress > 0 && progress < 1 ? progress : null,
              color: AppColors.goldSoft,
            ),
          ),
        );
      case SurahDownloadStatus.paused:
      case SurahDownloadStatus.failed:
        return IconButton(
          tooltip: strings.resumeDownload,
          onPressed: onResume,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.goldSoft),
        );
      case SurahDownloadStatus.notDownloaded:
        return IconButton(
          tooltip: strings.downloadSurah,
          onPressed: onDownload,
          icon: const Icon(Icons.download_rounded),
        );
    }
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.status,
    required this.progress,
    required this.strings,
    required this.reciter,
    required this.onDownload,
    required this.onCancel,
    required this.onDelete,
    required this.onResume,
  });

  final SurahDownloadStatus status;
  final double progress;
  final AppStrings strings;
  final Reciter reciter;
  final VoidCallback onDownload;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      SurahDownloadStatus.downloaded => strings.downloadComplete,
      SurahDownloadStatus.downloading =>
        '${strings.downloading} ${(progress * 100).clamp(0, 100).toStringAsFixed(0)} %',
      SurahDownloadStatus.paused => strings.downloadPaused,
      SurahDownloadStatus.failed => strings.downloadFailed,
      SurahDownloadStatus.notDownloaded => strings.downloadSurah,
    };

    final icon = switch (status) {
      SurahDownloadStatus.downloaded => Icons.download_done_rounded,
      SurahDownloadStatus.downloading => Icons.hourglass_top_rounded,
      SurahDownloadStatus.paused => Icons.pause_circle_outline,
      SurahDownloadStatus.failed => Icons.error_outline,
      SurahDownloadStatus.notDownloaded => Icons.download_rounded,
    };

    VoidCallback? primary = switch (status) {
      SurahDownloadStatus.downloaded => onDelete,
      SurahDownloadStatus.downloading => onCancel,
      SurahDownloadStatus.paused || SurahDownloadStatus.failed => onResume,
      SurahDownloadStatus.notDownloaded => onDownload,
    };

    final actionLabel = switch (status) {
      SurahDownloadStatus.downloaded => strings.deleteDownload,
      SurahDownloadStatus.downloading => strings.cancelDownload,
      SurahDownloadStatus.paused || SurahDownloadStatus.failed =>
        strings.resumeDownload,
      SurahDownloadStatus.notDownloaded => strings.downloadSurah,
    };

    return Material(
      color: AppColors.creamDark.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.emerald, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'SourceSerif4',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.emeraldDark,
                        ),
                      ),
                      Text(
                        reciter.nameEn,
                        style: TextStyle(
                          fontFamily: 'SourceSerif4',
                          fontSize: 11,
                          color: AppColors.inkMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: primary,
                  child: Text(actionLabel),
                ),
              ],
            ),
            if (status == SurahDownloadStatus.downloading) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 && progress < 1 ? progress : null,
                  minHeight: 4,
                  backgroundColor: AppColors.creamDark,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
