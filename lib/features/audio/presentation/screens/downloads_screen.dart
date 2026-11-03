import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../../data/reciter_catalog.dart';
import '../../domain/entities/surah_download.dart';
import '../providers/download_providers.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final asyncDownloads = ref.watch(downloadsMapProvider);
    final surahsAsync = ref.watch(surahListProvider);

    return Scaffold(
      backgroundColor: AppColors.mushafCream,
      appBar: AppBar(
        title: Text(s.myDownloads),
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
      ),
      body: asyncDownloads.when(
        loading: () => LoadingView(message: s.loading),
        error: (e, _) => Center(child: Text('${s.errorTitle}: $e')),
        data: (map) {
          final items = map.values
              .where(
                (d) =>
                    d.status == SurahDownloadStatus.downloaded ||
                    d.status == SurahDownloadStatus.downloading ||
                    d.status == SurahDownloadStatus.paused ||
                    d.status == SurahDownloadStatus.failed,
              )
              .toList()
            ..sort((a, b) {
              final ta = a.updatedAtMs ?? 0;
              final tb = b.updatedAtMs ?? 0;
              return tb.compareTo(ta);
            });

          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.download_for_offline_outlined,
                      size: 56,
                      color: AppColors.emerald.withValues(alpha: 0.55),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      s.noDownloadsYet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'SourceSerif4',
                        fontSize: 16,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                      ),
                      onPressed: () => context.go('/surahs'),
                      child: Text(s.browseSurahs),
                    ),
                  ],
                ),
              ),
            );
          }

          final surahs = surahsAsync.asData?.value ?? const [];

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = items[index];
              final surah = surahs.where((x) => x.id == d.surahId).firstOrNull;
              final reciter = ReciterCatalog.byId(d.reciterId);
              final title = surah?.nameAr ?? 'سورة ${d.surahId}';
              final subtitle =
                  '${surah?.transliteration ?? 'Sourate ${d.surahId}'} · ${reciter.nameEn}';

              final statusLabel = switch (d.status) {
                SurahDownloadStatus.downloaded => s.downloadComplete,
                SurahDownloadStatus.downloading =>
                  '${s.downloading} ${(d.progress * 100).toStringAsFixed(0)} %',
                SurahDownloadStatus.paused => s.downloadPaused,
                SurahDownloadStatus.failed => s.downloadFailed,
                SurahDownloadStatus.notDownloaded => s.downloadSurah,
              };

              return Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.creamDark),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.emerald.withValues(alpha: 0.12),
                          foregroundColor: AppColors.emerald,
                          child: Text('${d.surahId}'),
                        ),
                        title: Text(
                          title,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 20,
                          ),
                        ),
                        subtitle: Text(
                          '$subtitle\n$statusLabel',
                          style: const TextStyle(
                            fontFamily: 'SourceSerif4',
                            fontSize: 12,
                          ),
                        ),
                        isThreeLine: true,
                        onTap: () => context.push('/surahs/${d.surahId}'),
                      ),
                      if (d.status == SurahDownloadStatus.downloading)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8, right: 8),
                          child: LinearProgressIndicator(
                            value: d.progress > 0 && d.progress < 1
                                ? d.progress
                                : null,
                            color: AppColors.emerald,
                            backgroundColor: AppColors.creamDark,
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 4,
                          children: [
                            if (d.status == SurahDownloadStatus.downloading)
                              TextButton(
                                onPressed: () => ref
                                    .read(downloadControllerProvider.notifier)
                                    .cancel(
                                      reciterId: d.reciterId,
                                      surahId: d.surahId,
                                    ),
                                child: Text(s.cancelDownload),
                              ),
                            if (d.status == SurahDownloadStatus.paused ||
                                d.status == SurahDownloadStatus.failed)
                              TextButton(
                                onPressed: () => ref
                                    .read(downloadControllerProvider.notifier)
                                    .downloadSurah(
                                      reciter: reciter,
                                      surahId: d.surahId,
                                      verseCount: d.verseCount,
                                    ),
                                child: Text(s.resumeDownload),
                              ),
                            if (d.status == SurahDownloadStatus.downloaded ||
                                d.status == SurahDownloadStatus.paused ||
                                d.status == SurahDownloadStatus.failed)
                              TextButton(
                                onPressed: () async {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(s.deleteDownload),
                                      content: Text(s.confirmDeleteDownload),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text(s.cancelDownload),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          child: Text(s.deleteDownload),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (ok == true) {
                                    await ref
                                        .read(
                                          downloadControllerProvider.notifier,
                                        )
                                        .delete(
                                          reciter: reciter,
                                          surahId: d.surahId,
                                        );
                                  }
                                },
                                child: Text(s.deleteDownload),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
