import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/download_service.dart';
import '../../features/webview/cineby_webview.dart';
import '../../features/webview/webview_controller_provider.dart';
import 'nav_item.dart';

/// Root widget. Contains:
///  • The WebView (fills the screen)
///  • A linear progress bar at the top (page load indicator)
///  • The native bottom navigation bar
///  • A floating downloads button
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<String>? _downloadSub;

  @override
  void initState() {
    super.initState();
    // Subscribe once to the download messages stream and surface them as
    // snackbars. Ref.listen inside build is fine for sync state, but for a
    // broadcast stream we want a single subscription that lives for the
    // lifetime of the shell.
    final messages = ref.read(downloadServiceProvider.notifier).messages;
    _downloadSub = messages.listen(_showSnack);
  }

  @override
  void dispose() {
    _downloadSub?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.accent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(activeNavTabProvider);
    final loadProgress = ref.watch(pageLoadProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // The actual cineby.at website
          const CinebyWebView(),

          // Thin red progress bar at the very top while page loads
          if (loadProgress < 100)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: loadProgress / 100,
                backgroundColor: Colors.transparent,
                color: AppColors.accent,
                minHeight: 2,
              ),
            ),
        ],
      ),

      // Native bottom nav bar — overlaid below the WebView
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.navBar,
          border: Border(
            top: BorderSide(color: AppColors.navBarBorder, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            currentIndex: activeTab,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.iconActive,
            unselectedItemColor: AppColors.iconInactive,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            onTap: (index) {
              final url = kAppNavTabs[index].url;
              ref.read(webviewControllerProvider.notifier).loadUrl(url);
            },
            items: kAppNavTabs
                .map(
                  (t) => BottomNavigationBarItem(
                    icon: Icon(t.icon, size: 22),
                    label: t.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.small(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        onPressed: () {
          GoRouter.of(context).push('/downloads');
        },
        child: const Icon(Icons.download_rounded, size: 20),
      ),
    );
  }
}
