import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../app/providers/reading_settings_provider.dart';
import '../../../../core/constants/quran_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../audio/domain/entities/audio_playback_state.dart';
import '../../../audio/presentation/providers/audio_providers.dart';
import '../../../audio/presentation/widgets/compact_audio_player.dart';
import '../../../audio/presentation/widgets/surah_download_button.dart';
import '../../../library/domain/entities/verse_ref.dart';
import '../../../library/presentation/providers/library_providers.dart';
import '../../../surahs/domain/entities/surah.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../../../translations/domain/entities/ayah_translation.dart';
import '../../../translations/presentation/providers/translation_providers.dart';
import '../widgets/ayah_tile.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({
    super.key,
    required this.surahId,
    this.initialAyah,
  });

  final int surahId;
  final int? initialAyah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final settings = ref.watch(readingSettingsProvider);
    final asyncSurah = ref.watch(surahDetailProvider(surahId));
    final translationInfo =
        ref.watch(frenchTranslationInfoProvider).asData?.value;

    return asyncSurah.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.mushafCream,
        appBar: AppBar(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
        ),
        body: LoadingView(message: s.loading),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.mushafCream,
        appBar: AppBar(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
        ),
        body: ErrorView(
          message: '${s.errorTitle}: $e',
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(surahDetailProvider(surahId)),
        ),
      ),
      data: (surah) => _ReadingView(
        surah: surah,
        strings: s,
        initialAyah: initialAyah,
        showTranslation: settings.showFrenchTranslation,
        translationFontSize: settings.translationFontSize,
        tafsirFontSize: settings.tafsirFontSize,
        translationInfo: translationInfo,
        onToggleTranslation: () =>
            ref.read(readingSettingsProvider.notifier).toggleFrenchTranslation(),
      ),
    );
  }
}

class _ReadingView extends ConsumerStatefulWidget {
  const _ReadingView({
    required this.surah,
    required this.strings,
    required this.showTranslation,
    required this.translationFontSize,
    required this.tafsirFontSize,
    required this.translationInfo,
    required this.onToggleTranslation,
    this.initialAyah,
  });

  final Surah surah;
  final AppStrings strings;
  final bool showTranslation;
  final double translationFontSize;
  final double tafsirFontSize;
  final TranslationInfo? translationInfo;
  final VoidCallback onToggleTranslation;
  final int? initialAyah;

  @override
  ConsumerState<_ReadingView> createState() => _ReadingViewState();
}

class _ReadingViewState extends ConsumerState<_ReadingView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _ayahKeys = {};
  bool _didScrollToInitial = false;
  int? _lastScrolledAudioAyah;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int ayahNumber) =>
      _ayahKeys.putIfAbsent(ayahNumber, GlobalKey.new);

  void _goToSurah(BuildContext context, int id) {
    if (id < 1 || id > QuranConstants.surahCount) return;
    context.pushReplacement('/surahs/$id');
  }

  Future<void> _scrollToAyah(int target, {bool animated = true}) async {
    if (!mounted) return;
    final ctx = _keyFor(target).currentContext;
    if (ctx == null || !ctx.mounted) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: animated
          ? const Duration(milliseconds: 350)
          : Duration.zero,
      alignment: 0.15,
      curve: Curves.easeOut,
    );
  }

  Future<void> _scrollToInitialAyah() async {
    final target = widget.initialAyah;
    if (target == null || _didScrollToInitial) return;
    _didScrollToInitial = true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await _scrollToAyah(target);
  }

  void _maybeScrollToPlayingAyah(AudioPlaybackState audio) {
    if (audio.surahId != widget.surah.id) return;
    if (audio.status != AudioStatus.playing &&
        audio.status != AudioStatus.paused &&
        audio.status != AudioStatus.loading) {
      return;
    }
    final ayah = audio.ayahNumber;
    if (ayah == null || ayah == _lastScrolledAudioAyah) return;
    _lastScrolledAudioAyah = ayah;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToAyah(ayah);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surah = widget.surah;
    final strings = widget.strings;
    final hasPrev = surah.id > 1;
    final hasNext = surah.id < QuranConstants.surahCount;
    final actions = ref.read(libraryActionsProvider);
    final audio = ref.watch(audioControllerProvider);
    final audioController = ref.read(audioControllerProvider.notifier);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitialAyah();
      _maybeScrollToPlayingAyah(audio);
    });

    return Scaffold(
      backgroundColor: AppColors.mushafCream,
      appBar: AppBar(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          children: [
            Text(
              surah.nameAr,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24,
                height: 1.2,
              ),
            ),
            Text(
              '${surah.transliteration} · ${strings.verseCountLabel(surah.versesCount)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          SurahDownloadButton(
            surahId: surah.id,
            verseCount: surah.versesCount,
            strings: strings,
            compact: true,
          ),
          IconButton(
            tooltip: strings.playAudio,
            onPressed: () => audioController.togglePlayPause(
              surahId: surah.id,
              verseCount: surah.versesCount,
              startAyah: widget.initialAyah ?? 1,
            ),
            icon: Icon(
              audio.surahId == surah.id &&
                      audio.status == AudioStatus.playing
                  ? Icons.pause_circle_outline
                  : Icons.headphones_outlined,
            ),
          ),
          IconButton(
            tooltip: widget.showTranslation
                ? strings.hideTranslation
                : strings.showTranslation,
            onPressed: widget.onToggleTranslation,
            icon: Icon(
              widget.showTranslation
                  ? Icons.translate
                  : Icons.translate_outlined,
              color: widget.showTranslation ? AppColors.goldSoft : Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.showTranslation && widget.translationInfo != null)
            Container(
              width: double.infinity,
              color: AppColors.creamDark.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                widget.translationInfo!.attribution,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SourceSerif4',
                  fontSize: 11,
                  color: AppColors.inkMuted.withValues(alpha: 0.9),
                ),
              ),
            ),
          if (!audio.isActive || audio.surahId != surah.id)
            Material(
              color: AppColors.emerald.withValues(alpha: 0.08),
              child: InkWell(
                onTap: () => audioController.togglePlayPause(
                  surahId: surah.id,
                  verseCount: surah.versesCount,
                  startAyah: widget.initialAyah ?? 1,
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.play_circle_filled_rounded,
                        color: AppColors.emerald,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          strings.listenRecitationHint,
                          style: const TextStyle(
                            fontFamily: 'SourceSerif4',
                            fontSize: 13,
                            color: AppColors.emeraldDark,
                          ),
                        ),
                      ),
                      Text(
                        strings.playAudio,
                        style: const TextStyle(
                          fontFamily: 'SourceSerif4',
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: surah.ayahs.length +
                      (surah.id != 1 && surah.id != 9 ? 1 : 0),
                  separatorBuilder: (context, index) {
                    final hasBasmala = surah.id != 1 && surah.id != 9;
                    if (hasBasmala && index == 0) {
                      return const SizedBox(height: 4);
                    }
                    return const AyahSeparator();
                  },
                  itemBuilder: (context, index) {
                    final hasBasmala = surah.id != 1 && surah.id != 9;
                    if (hasBasmala && index == 0) {
                      return const _BasmalaHeader();
                    }
                    final ayahIndex = hasBasmala ? index - 1 : index;
                    final ayah = surah.ayahs[ayahIndex];
                    final verseRef = VerseRef(
                      surahId: surah.id,
                      ayahNumber: ayah.number,
                    );
                    final favAsync = ref.watch(isFavoriteProvider(verseRef));
                    final highlighted = audio.surahId == surah.id &&
                        audio.ayahNumber == ayah.number &&
                        audio.isActive;

                    return KeyedSubtree(
                      key: _keyFor(ayah.number),
                      child: AyahTile(
                        ayah: ayah,
                        showTranslation: widget.showTranslation,
                        translationFontSize: widget.translationFontSize,
                        tafsirFontSize: widget.tafsirFontSize,
                        strings: strings,
                        isFavorite: favAsync.asData?.value ?? false,
                        isHighlighted: highlighted,
                        favoriteTooltip: strings.addFavorite,
                        bookmarkTooltip: strings.addBookmark,
                        markPositionTooltip: strings.markPosition,
                        playTooltip: strings.playFromVerse,
                        onPlayFromHere: () => audioController.playSurah(
                          surahId: surah.id,
                          verseCount: surah.versesCount,
                          startAyah: ayah.number,
                        ),
                        onToggleFavorite: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await actions.toggleFavorite(verseRef);
                          final nowFav = await ref.read(
                            isFavoriteProvider(verseRef).future,
                          );
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                nowFav
                                    ? strings.favoriteAdded
                                    : strings.favoriteRemoved,
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        onAddBookmark: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await actions.addBookmark(verseRef);
                          messenger.showSnackBar(
                            SnackBar(content: Text(strings.bookmarkAdded)),
                          );
                        },
                        onMarkPosition: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await actions.markReadingPosition(verseRef);
                          messenger.showSnackBar(
                            SnackBar(content: Text(strings.positionMarked)),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          CompactAudioPlayer(
            strings: strings,
            surahId: surah.id,
            verseCount: surah.versesCount,
            startAyah: widget.initialAyah ?? 1,
          ),
          _SurahNavBar(
            strings: strings,
            hasPrev: hasPrev,
            hasNext: hasNext,
            onPrev: () => _goToSurah(context, surah.id - 1),
            onNext: () => _goToSurah(context, surah.id + 1),
          ),
        ],
      ),
    );
  }
}

class _BasmalaHeader extends StatelessWidget {
  const _BasmalaHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 26,
          height: 1.8,
          color: AppColors.emerald.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _SurahNavBar extends StatelessWidget {
  const _SurahNavBar({
    required this.strings,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrev,
    required this.onNext,
  });

  final AppStrings strings;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: hasPrev ? onPrev : null,
                      icon: const Icon(Icons.chevron_left),
                      label: Text(strings.previousSurah),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emerald,
                        side: BorderSide(
                          color: hasPrev
                              ? AppColors.emerald
                              : AppColors.creamDark,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: hasNext ? onNext : null,
                      icon: const Icon(Icons.chevron_right),
                      label: Text(strings.nextSurah),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        disabledBackgroundColor: AppColors.creamDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
