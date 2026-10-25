import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/locale_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../providers/library_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.mushafCream,
        appBar: AppBar(
          backgroundColor: AppColors.emerald,
          foregroundColor: Colors.white,
          title: Text(s.favorites),
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: s.favorites),
              Tab(text: s.bookmarks),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _FavoritesTab(),
            _BookmarksTab(),
          ],
        ),
      ),
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final async = ref.watch(favoriteDisplaysProvider);

    return async.when(
      loading: () => LoadingView(message: s.loading),
      error: (e, _) => ErrorView(
        message: '$e',
        retryLabel: s.retry,
        onRetry: () => ref.invalidate(favoriteDisplaysProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.noFavorites,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 16),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.creamDark),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push(
                  '/surahs/${item.entry.ref.surahId}?ayah=${item.entry.ref.ayahNumber}',
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.surah.nameAr} · ${item.surah.transliteration}',
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                fontFamily: 'AmiriQuran',
                                fontSize: 18,
                                color: AppColors.emeraldDark,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: s.removeFavorite,
                            onPressed: () => ref
                                .read(libraryActionsProvider)
                                .removeFavorite(item.entry.ref),
                            icon: const Icon(Icons.favorite, color: Colors.redAccent),
                          ),
                        ],
                      ),
                      Text(
                        '${s.verse} ${item.entry.ref.ayahNumber}',
                        style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.ayah.textAr,
                        textDirection: TextDirection.rtl,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 22,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BookmarksTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    final async = ref.watch(bookmarkDisplaysProvider);

    return async.when(
      loading: () => LoadingView(message: s.loading),
      error: (e, _) => ErrorView(
        message: '$e',
        retryLabel: s.retry,
        onRetry: () => ref.invalidate(bookmarkDisplaysProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                s.noBookmarks,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkMuted, fontSize: 16),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.creamDark),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                leading: const Icon(Icons.bookmark, color: AppColors.gold),
                title: Text(
                  '${item.surah.nameAr} — ${s.verse} ${item.entry.ref.ayahNumber}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 18),
                ),
                subtitle: Text(
                  item.ayah.textAr,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 16),
                ),
                trailing: IconButton(
                  tooltip: s.removeBookmark,
                  onPressed: () => ref
                      .read(libraryActionsProvider)
                      .removeBookmark(item.entry.id),
                  icon: const Icon(Icons.delete_outline),
                ),
                onTap: () => context.push(
                  '/surahs/${item.entry.ref.surahId}?ayah=${item.entry.ref.ayahNumber}',
                ),
              ),
            );
          },
        );
      },
    );
  }
}
