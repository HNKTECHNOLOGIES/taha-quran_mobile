import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/app_strings.dart';
import '../../app/providers/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home, color: AppColors.emerald),
            label: s.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book, color: AppColors.emerald),
            label: s.surahs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite, color: AppColors.emerald),
            label: s.favorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.search),
            selectedIcon: const Icon(Icons.search, color: AppColors.emerald),
            label: s.search,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings, color: AppColors.emerald),
            label: s.settings,
          ),
        ],
      ),
    );
  }
}

class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key, required this.titleBuilder});

  final String Function(AppStrings s) titleBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(titleBuilder(s))),
      body: Center(
        child: Text(
          s.comingSoon,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.inkMuted,
              ),
        ),
      ),
    );
  }
}
