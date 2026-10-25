import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_numerals.dart';
import '../../../../core/utils/juz_utils.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../surahs/domain/entities/surah.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../widgets/mushaf_page.dart';

/// Fond crème type page de Mushaf.
const Color _mushafCream = Color(0xFFFFF6E8);

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key, required this.surahId});

  final int surahId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(localeProvider);
    final asyncSurah = ref.watch(surahDetailProvider(widget.surahId));

    return asyncSurah.when(
      loading: () => const Scaffold(
        backgroundColor: _mushafCream,
        body: LoadingView(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: _mushafCream,
        appBar: AppBar(
          backgroundColor: _mushafCream,
          foregroundColor: AppColors.emeraldDark,
          elevation: 0,
        ),
        body: ErrorView(
          message: '${s.errorTitle}: $e',
          retryLabel: s.retry,
          onRetry: () =>
              ref.invalidate(surahDetailProvider(widget.surahId)),
        ),
      ),
      data: (surah) => _MushafReader(
        surah: surah,
        pageController: _pageController,
        pageIndex: _pageIndex,
        onPageChanged: (i) => setState(() => _pageIndex = i),
      ),
    );
  }
}

class _MushafReader extends StatelessWidget {
  const _MushafReader({
    required this.surah,
    required this.pageController,
    required this.pageIndex,
    required this.onPageChanged,
  });

  final Surah surah;
  final PageController pageController;
  final int pageIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pages = paginateAyahs(surah.ayahs);
    final safeIndex =
        pages.isEmpty ? 0 : pageIndex.clamp(0, pages.length - 1);
    final firstAyahNumber =
        pages.isEmpty ? 1 : pages[safeIndex].first.number;
    final juz = juzFor(surahId: surah.id, ayahNumber: firstAyahNumber);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _mushafCream,
        body: SafeArea(
          child: Column(
            children: [
              _MushafHeader(
                surahNameAr: surah.nameAr,
                juz: juz,
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: PageView.builder(
                  controller: pageController,
                  itemCount: pages.length,
                  onPageChanged: onPageChanged,
                  // En RTL, glisser vers la gauche = page suivante (comme un Mushaf).
                  reverse: false,
                  itemBuilder: (context, index) {
                    final showBasmala = surah.id != 1 &&
                        surah.id != 9 &&
                        index == 0;
                    return MushafPage(
                      ayahs: pages[index],
                      showBasmala: showBasmala,
                    );
                  },
                ),
              ),
              _MushafFooter(
                pageNumber: safeIndex + 1,
                totalPages: pages.length,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafHeader extends StatelessWidget {
  const _MushafHeader({
    required this.surahNameAr,
    required this.juz,
    required this.onBack,
  });

  final String surahNameAr;
  final int juz;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_forward_ios, size: 18),
                color: AppColors.emerald.withValues(alpha: 0.7),
                tooltip: 'Retour',
              ),
              Expanded(
                // LTR pour positionner comme sur un Mushaf imprimé :
                // sourate à gauche, juz à droite.
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        surahNameAr,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 20,
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'الجزء ${toArabicNumerals(juz)}',
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          color: AppColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: AppColors.gold.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

class _MushafFooter extends StatelessWidget {
  const _MushafFooter({
    required this.pageNumber,
    required this.totalPages,
  });

  final int pageNumber;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${toArabicNumerals(pageNumber)} / ${toArabicNumerals(totalPages)}',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: AppColors.inkMuted.withValues(alpha: 0.65),
                  ),
                ),
              ),
            Text(
              toArabicNumerals(pageNumber),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: AppColors.ink.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
