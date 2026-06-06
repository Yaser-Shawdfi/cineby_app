import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the live [InAppWebViewController] so that widgets outside the
/// webview feature (the bottom nav, the back button handler, the FAB) can
/// invoke `loadUrl` / `goBack` / `canGoBack`.
final webviewControllerProvider =
    NotifierProvider<WebviewControllerHolder, InAppWebViewController?>(
  WebviewControllerHolder.new,
);

class WebviewControllerHolder extends Notifier<InAppWebViewController?> {
  @override
  InAppWebViewController? build() => null;

  void setController(InAppWebViewController controller) {
    state = controller;
  }

  Future<void> loadUrl(String url) async {
    final c = state;
    if (c == null) return;
    await c.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  Future<bool> canGoBack() async {
    final c = state;
    if (c == null) return false;
    return c.canGoBack();
  }

  Future<void> goBack() async {
    final c = state;
    if (c == null) return;
    if (await c.canGoBack()) {
      await c.goBack();
    }
  }
}

/// The index of the currently active bottom-nav tab.
///
/// Synced with the WebView's current URL in `onLoadStop` and read by the
/// `AppShell` to highlight the right tab.
final activeNavTabProvider =
    NotifierProvider<ActiveNavTab, int>(ActiveNavTab.new);

class ActiveNavTab extends Notifier<int> {
  @override
  int build() => 0; // Default: Home tab

  void updateFromUrl(String url) {
    if (url.contains('/browse/movie')) {
      state = 1;
      return;
    }
    if (url.contains('/browse/tv')) {
      state = 2;
      return;
    }
    if (url.contains('/search')) {
      state = 3;
      return;
    }
    if (url.contains('/watchlist')) {
      state = 4;
      return;
    }
    if (url == 'https://www.cineby.at/' ||
        url == 'https://www.cineby.at' ||
        url == 'https://www.cineby.at/') {
      state = 0;
      return;
    }
    // Detail pages (/movie/xxx, /tv/xxx) — don't change nav tab
  }
}

/// Live page-load progress (0..100). Driven by `onProgressChanged`.
final pageLoadProgressProvider =
    NotifierProvider<PageLoadProgress, int>(PageLoadProgress.new);

class PageLoadProgress extends Notifier<int> {
  @override
  int build() => 0;

  void setProgress(int value) {
    state = value;
  }
}
