import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/reciter_catalog.dart';
import '../../domain/entities/audio_playback_state.dart';
import '../../domain/entities/reciter.dart';
import '../providers/audio_providers.dart';

/// Lecteur audio compact (bas d'écran de lecture).
class CompactAudioPlayer extends ConsumerWidget {
  const CompactAudioPlayer({
    super.key,
    required this.strings,
    required this.surahId,
    required this.verseCount,
    this.startAyah = 1,
  });

  final AppStrings strings;
  final int surahId;
  final int verseCount;
  final int startAyah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioControllerProvider);
    final selectedReciter = ref.watch(selectedReciterProvider);
    final controller = ref.read(audioControllerProvider.notifier);
    final isThisSurah = audio.surahId == surahId;
    final reciter = isThisSurah ? audio.reciter : selectedReciter;
    final ayahLabel = isThisSurah && audio.ayahNumber != null
        ? '${strings.verse} ${audio.ayahNumber}'
        : strings.audioReady;
    final progress = isThisSurah ? audio.progress : 0.0;
    final busy = audio.status == AudioStatus.loading && isThisSurah;
    final playing = audio.status == AudioStatus.playing && isThisSurah;
    final canSkip = isThisSurah &&
        (audio.isActive || audio.status == AudioStatus.completed);

    return Material(
      elevation: 10,
      color: Colors.white,
      shadowColor: AppColors.emerald.withValues(alpha: 0.35),
      child: SafeArea(
        top: false,
        bottom: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withValues(alpha: 0.65),
                width: 2,
              ),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.emerald.withValues(alpha: 0.06),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.headphones_rounded,
                          size: 16,
                          color: AppColors.emerald.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            strings.recitationPlayer,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'SourceSerif4',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: AppColors.emeraldDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            ReciterCatalog.attribution,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.inkMuted.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showReciterSheet(context, ref),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reciter.nameEn,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'SourceSerif4',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.emeraldDark,
                                    ),
                                  ),
                                  Text(
                                    ayahLabel,
                                    style: TextStyle(
                                      fontFamily: 'SourceSerif4',
                                      fontSize: 12,
                                      color: AppColors.inkMuted.withValues(
                                        alpha: 0.9,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.previousVerse,
                          onPressed:
                              canSkip ? () => controller.previous() : null,
                          icon: const Icon(Icons.skip_previous_rounded),
                          color: AppColors.emerald,
                        ),
                        _PlayButton(
                          busy: busy,
                          playing: playing,
                          hasError: audio.status == AudioStatus.error &&
                              isThisSurah,
                          onPressed: () => controller.togglePlayPause(
                            surahId: surahId,
                            verseCount: verseCount,
                            startAyah: isThisSurah
                                ? (audio.ayahNumber ?? startAyah)
                                : startAyah,
                          ),
                        ),
                        IconButton(
                          tooltip: strings.nextVerse,
                          onPressed: canSkip ? () => controller.next() : null,
                          icon: const Icon(Icons.skip_next_rounded),
                          color: AppColors.emerald,
                        ),
                        IconButton(
                          tooltip: strings.stopAudio,
                          onPressed: isThisSurah &&
                                  audio.status != AudioStatus.idle
                              ? () => controller.stop()
                              : null,
                          icon: const Icon(Icons.stop_rounded),
                          color: AppColors.inkMuted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: busy ? null : progress,
                        minHeight: 4,
                        backgroundColor: AppColors.creamDark,
                        color: AppColors.emerald,
                      ),
                    ),
                    if (audio.status == AudioStatus.error && isThisSurah)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                strings.audioError,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                  fontFamily: 'SourceSerif4',
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => controller.playSurah(
                                surahId: surahId,
                                verseCount: verseCount,
                                startAyah: audio.ayahNumber ?? startAyah,
                              ),
                              child: Text(strings.retry),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showReciterSheet(BuildContext context, WidgetRef ref) async {
    final strings = this.strings;
    final current = ref.read(selectedReciterProvider);
    final chosen = await showModalBottomSheet<Reciter>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  strings.chooseReciter,
                  style: const TextStyle(
                    fontFamily: 'SourceSerif4',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emeraldDark,
                  ),
                ),
              ),
              for (final reciter in ReciterCatalog.all)
                ListTile(
                  title: Text(reciter.nameEn),
                  subtitle: Text(
                    '${reciter.nameAr} · ${reciter.bitrateLabel}',
                    textDirection: TextDirection.rtl,
                  ),
                  trailing: reciter.id == current.id
                      ? const Icon(Icons.check, color: AppColors.emerald)
                      : null,
                  onTap: () => Navigator.pop(ctx, reciter),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (chosen == null) return;
    await ref.read(audioControllerProvider.notifier).changeReciter(chosen);
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.busy,
    required this.playing,
    required this.hasError,
    required this.onPressed,
  });

  final bool busy;
  final bool playing;
  final bool hasError;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.emerald,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: busy ? null : onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    hasError
                        ? Icons.refresh_rounded
                        : (playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                    color: Colors.white,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
