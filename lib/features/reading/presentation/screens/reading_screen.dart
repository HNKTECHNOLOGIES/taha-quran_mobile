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
import '../../../surahs/domain/entities/surah.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../widgets/ayah_tile.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final settings = ref.watch(readingSettingsProvider);
    final asyncSurah = ref.watch(surahDetailProvider(surahId));

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
        showTranslation: settings.showFrenchTranslation,
        onToggleTranslation: () =>
            ref.read(readingSettingsProvider.notifier).toggleFrenchTranslation(),
      ),
    );
  }
}

class _ReadingView extends StatelessWidget {
  const _ReadingView({
    required this.surah,
    required this.strings,
    required this.showTranslation,
    required this.onToggleTranslation,
  });

  final Surah surah;
  final AppStrings strings;
  final bool showTranslation;
  final VoidCallback onToggleTranslation;

  void _goToSurah(BuildContext context, int id) {
    if (id < 1 || id > QuranConstants.surahCount) return;
    context.pushReplacement('/surahs/$id');
  }

  @override
  Widget build(BuildContext context) {
    final hasPrev = surah.id > 1;
    final hasNext = surah.id < QuranConstants.surahCount;

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
          IconButton(
            tooltip: showTranslation
                ? strings.hideTranslation
                : strings.showTranslation,
            onPressed: onToggleTranslation,
            icon: Icon(
              showTranslation
                  ? Icons.translate
                  : Icons.translate_outlined,
              color: showTranslation ? AppColors.goldSoft : Colors.white,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showTranslation)
            Container(
              width: double.infinity,
              color: AppColors.creamDark.withValues(alpha: 0.55),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                strings.translationCredit,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted.withValues(alpha: 0.9),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  itemCount: surah.ayahs.length +
                      (surah.id != 1 && surah.id != 9 ? 1 : 0),
                  separatorBuilder: (context, index) {
                    // Pas de séparateur avant le premier verset après basmala.
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
                    return AyahTile(
                      ayah: surah.ayahs[ayahIndex],
                      showTranslation: showTranslation,
                    );
                  },
                ),
              ),
            ),
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
