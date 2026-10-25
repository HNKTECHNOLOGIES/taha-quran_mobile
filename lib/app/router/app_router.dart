import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/home_screen.dart';
import '../../features/reading/presentation/screens/reading_screen.dart';
import '../../features/surahs/presentation/screens/surah_list_screen.dart';
import '../../shared/widgets/main_shell.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/surahs',
                builder: (context, state) => const SurahListScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) {
                      final id = int.parse(state.pathParameters['id']!);
                      return ReadingScreen(surahId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => PlaceholderScreen(
                  titleBuilder: (s) => s.favorites,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => PlaceholderScreen(
                  titleBuilder: (s) => s.search,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => PlaceholderScreen(
                  titleBuilder: (s) => s.settings,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
