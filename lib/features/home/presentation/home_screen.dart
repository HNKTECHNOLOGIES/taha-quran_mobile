import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../library/domain/entities/verse_ref.dart';
import '../../library/presentation/providers/library_providers.dart';
import '../../surahs/domain/entities/surah.dart';
import '../../surahs/presentation/providers/quran_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final width = MediaQuery.sizeOf(context).width;
    final maxContent = width > 720 ? 560.0 : double.infinity;
    final resumeAsync = ref.watch(readingPositionProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: AppColors.mushafCream,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.emeraldDark,
              AppColors.emerald,
              Color(0xFF1A7A58),
              AppColors.mushafCream,
            ],
            stops: [0.0, 0.28, 0.48, 0.72],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContent),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  width < 360 ? 16 : 24,
                  12,
                  width < 360 ? 16 : 24,
                  28,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.appName,
                          textDirection: s.isRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: s.isRtl ? 'AmiriQuran' : 'SourceSerif4',
                            fontSize: width < 360 ? 22 : 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldSoft,
                            letterSpacing: s.isRtl ? 0 : 1.2,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            ref.read(localeProvider.notifier).toggle(),
                        icon: const Icon(
                          Icons.language,
                          color: AppColors.goldSoft,
                          size: 20,
                        ),
                        label: Text(
                          s.language == AppLanguage.french ? 'العربية' : 'FR',
                          style: const TextStyle(color: AppColors.goldSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: width < 360 ? 148 : 168,
                      height: width < 360 ? 148 : 168,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.28),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                        border: Border.all(
                          color: AppColors.goldSoft.withValues(alpha: 0.7),
                          width: 1.5,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/branding/taha_logo.png',
                        fit: BoxFit.cover,
                        semanticLabel: s.appBrand,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    s.appBrand,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SourceSerif4',
                      fontSize: width < 360 ? 28 : 34,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: Colors.white,
                      letterSpacing: 1.0,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'السلام عليكم',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: width < 360 ? 24 : 28,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 64,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    s.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 28),
                  resumeAsync.when(
                    loading: () => const _ResumeSkeleton(),
                    error: (_, _) => _EmptyResumeCard(strings: s),
                    data: (pos) => pos == null
                        ? _EmptyResumeCard(strings: s)
                        : _ContinueReadingCard(
                            strings: s,
                            position: pos,
                          ),
                  ),
                  const SizedBox(height: 20),
                  _PrimaryActionButton(
                    label: s.readQuran,
                    icon: Icons.menu_book_rounded,
                    onPressed: () => context.go('/surahs'),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: s.listenRecitation,
                    icon: Icons.headphones_rounded,
                    onPressed: () => context.push('/surahs/1'),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: s.myDownloads,
                    icon: Icons.download_for_offline_rounded,
                    onPressed: () => context.push('/downloads'),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: s.myFavorites,
                    icon: Icons.favorite_rounded,
                    badge: favoritesAsync.asData?.value.length,
                    onPressed: () => context.go('/favorites'),
                  ),
                  const SizedBox(height: 12),
                  _SecondaryActionButton(
                    label: s.bookmarks,
                    icon: Icons.bookmark_rounded,
                    badge: bookmarksAsync.asData?.value.length,
                    outlined: true,
                    onPressed: () => context.go('/favorites?tab=bookmarks'),
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

class _ResumeSkeleton extends StatelessWidget {
  const _ResumeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

class _EmptyResumeCard extends StatelessWidget {
  const _EmptyResumeCard({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.my_location, color: AppColors.goldSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.continueReading,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  strings.noResumeYet,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({
    required this.strings,
    required this.position,
  });

  final AppStrings strings;
  final ReadingPosition position;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(position.ref.surahId));

    return Material(
      color: Colors.white,
      elevation: 0,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push(
          '/surahs/${position.ref.surahId}?ayah=${position.ref.ayahNumber}',
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.emeraldDark.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emerald, AppColors.emeraldSoft],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.continueReading,
                      style: const TextStyle(
                        color: AppColors.emeraldDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    surahAsync.when(
                      loading: () => Text(
                        '${strings.verse} ${position.ref.ayahNumber}',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                      error: (_, _) => Text(
                        '${strings.verse} ${position.ref.ayahNumber}',
                        style: TextStyle(color: AppColors.inkMuted),
                      ),
                      data: (Surah surah) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.nameAr,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 22,
                              color: AppColors.ink,
                              height: 1.2,
                            ),
                          ),
                          Text(
                            '${surah.transliteration} · ${strings.verse} ${position.ref.ayahNumber}',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.emerald),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.outlined = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final int? badge;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (badge != null && badge! > 0) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: outlined
                  ? AppColors.emerald.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$badge',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: outlined ? AppColors.emeraldDark : Colors.white,
              ),
            ),
          ),
        ],
      ],
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emeraldDark,
          side: const BorderSide(color: AppColors.emerald, width: 1.4),
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        textStyle: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: child,
    );
  }
}
