import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_colors.dart';
import 'features/downloads/downloads_screen.dart';
import 'features/player/native_player_screen.dart';
import 'features/webview/webview_controller_provider.dart';
import 'shared/navigation/app_shell.dart';

/// Root of the app. Hosts the [GoRouter] and the top-level [MaterialApp.router].
class CinebyApp extends ConsumerStatefulWidget {
  const CinebyApp({super.key});

  @override
  ConsumerState<CinebyApp> createState() => _CinebyAppState();
}

class _CinebyAppState extends ConsumerState<CinebyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _BackAwareShell(),
        ),
        GoRoute(
          path: '/player',
          builder: (context, state) {
            final url = state.extra as String? ?? '';
            return NativePlayerScreen(videoUrl: url);
          },
        ),
        GoRoute(
          path: '/downloads',
          builder: (context, state) => const DownloadsScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cineby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.surface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.navBar,
          selectedItemColor: AppColors.iconActive,
          unselectedItemColor: AppColors.iconInactive,
        ),
      ),
      routerConfig: _router,
    );
  }
}

/// Wraps [AppShell] in a [PopScope] that delegates the Android back press to
/// the WebView's history stack instead of popping the route (which would exit
/// the app). cineby.at is a Next.js SPA, so back has to navigate within the
/// page history, not within Flutter's navigator.
class _BackAwareShell extends ConsumerWidget {
  const _BackAwareShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref.read(webviewControllerProvider.notifier).goBack();
        // If goBack had no effect, swallow the back press — the spec says
        // "if no history, do nothing (don't exit the app on back)".
      },
      child: const AppShell(),
    );
  }
}
