import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/providers/locale_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../library/presentation/providers/library_providers.dart';
import '../../surahs/presentation/providers/quran_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final size = MediaQuery.sizeOf(context);
    final resumeAsync = ref.watch(readingPositionProvider);

    return Scaffold(
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
              Color(0xFF0F8A62),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: TextButton.icon(
                    onPressed: () => ref.read(localeProvider.notifier).toggle(),
                    icon: const Icon(Icons.language, color: AppColors.goldSoft),
                    label: Text(
                      s.language == AppLanguage.french ? 'العربية' : 'FR',
                      style: const TextStyle(color: AppColors.goldSoft),
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'القرآن الكريم',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: size.width < 360 ? 40 : 48,
                    height: 1.3,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  alignment: Alignment.center,
                  child: Container(
                    width: 72,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  s.welcomeSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.goldSoft),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.offlineBadge,
                      style: const TextStyle(
                        color: AppColors.goldSoft,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                FilledButton(
                  onPressed: () => context.go('/surahs'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(s.browseSurahs),
                ),
                const SizedBox(height: 12),
                resumeAsync.when(
                  loading: () => const SizedBox(height: 48),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (pos) {
                    if (pos == null) {
                      return OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(s.noResumeYet),
                      );
                    }
                    return _ContinueCard(
                      strings: s,
                      surahId: pos.ref.surahId,
                      ayahNumber: pos.ref.ayahNumber,
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends ConsumerWidget {
  const _ContinueCard({
    required this.strings,
    required this.surahId,
    required this.ayahNumber,
  });

  final AppStrings strings;
  final int surahId;
  final int ayahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahAsync = ref.watch(surahDetailProvider(surahId));
    final subtitle = surahAsync.maybeWhen(
      data: (s) => '${s.nameAr} · ${strings.verse} $ayahNumber',
      orElse: () => '${strings.verse} $ayahNumber',
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/surahs/$surahId?ayah=$ayahNumber'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: AppColors.goldSoft),
              const SizedBox(width: 12),
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
                    Text(
                      subtitle,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontFamily: 'AmiriQuran',
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}
