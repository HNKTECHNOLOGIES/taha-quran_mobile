import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/app_strings.dart';
import '../../../../app/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../providers/quran_providers.dart';
import '../widgets/surah_list_tile.dart';

class SurahListScreen extends ConsumerWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final asyncSurahs = ref.watch(surahListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.surahs),
        actions: [
          IconButton(
            tooltip: s.language == AppLanguage.french ? 'العربية' : 'FR',
            onPressed: () => ref.read(localeProvider.notifier).toggle(),
            icon: const Icon(Icons.language),
          ),
        ],
      ),
      body: asyncSurahs.when(
        loading: () => LoadingView(message: s.loading),
        error: (e, _) => ErrorView(
          message: '${s.errorTitle}: $e',
          retryLabel: s.retry,
          onRetry: () => ref.invalidate(surahListProvider),
        ),
        data: (surahs) {
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: surahs.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Theme.of(context).dividerColor,
            ),
            itemBuilder: (context, index) {
              final surah = surahs[index];
              return SurahListTile(
                surah: surah,
                strings: s,
                onTap: () => context.push('/surahs/${surah.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: asyncSurahs.maybeWhen(
        data: (surahs) => Chip(
          avatar: const Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
          label: Text('${surahs.length}'),
          backgroundColor: AppColors.cream,
        ),
        orElse: () => null,
      ),
    );
  }
}
