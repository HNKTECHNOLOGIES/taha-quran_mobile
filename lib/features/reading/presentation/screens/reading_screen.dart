import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../surahs/presentation/providers/quran_providers.dart';
import '../widgets/ayah_tile.dart';

class ReadingScreen extends ConsumerWidget {
  const ReadingScreen({super.key, required this.surahId});

  final int surahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final asyncSurah = ref.watch(surahDetailProvider(surahId));

    return asyncSurah.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: LoadingView(message: s.loading),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: '${s.errorTitle}: $e',
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(surahDetailProvider(surahId)),
        ),
      ),
      data: (surah) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            appBar: AppBar(
              title: Column(
                children: [
                  Text(
                    surah.nameAr,
                    style: const TextStyle(
                      fontFamily: 'AmiriQuran',
                      fontSize: 22,
                    ),
                  ),
                  Text(
                    '${surah.transliteration} · ${s.verseCountLabel(surah.versesCount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            body: CustomScrollView(
              slivers: [
                if (surah.id != 9 && surah.id != 1)
                  const SliverToBoxAdapter(child: _Basmala()),
                SliverList.separated(
                  itemCount: surah.ayahs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (context, index) {
                    return AyahTile(ayah: surah.ayahs[index]);
                  },
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Basmala extends StatelessWidget {
  const _Basmala();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'AmiriQuran',
          fontSize: 26,
          color: AppColors.emerald.withValues(alpha: 0.85),
          height: 1.8,
        ),
      ),
    );
  }
}
