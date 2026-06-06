import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_urls.dart';
import '../../core/services/download_service.dart';
import '../../core/services/video_interceptor.dart';
import '../../core/utils/css_overrides.dart';
import '../../core/utils/js_scripts.dart';
import 'webview_controller_provider.dart';

/// Core InAppWebView widget that loads cineby.at and bridges JS <-> Flutter.
class CinebyWebView extends ConsumerStatefulWidget {
  const CinebyWebView({super.key});

  @override
  ConsumerState<CinebyWebView> createState() => _CinebyWebViewState();
}

class _CinebyWebViewState extends ConsumerState<CinebyWebView> {
  String _lastInjectedUrl = '';

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(AppUrls.home)),
      initialSettings: InAppWebViewSettings(
        // Required settings
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        allowsBackForwardNavigationGestures: true,
        useShouldOverrideUrlLoading: true,
        useOnDownloadStart: true,

        // Security / UX
        disableContextMenu: false,
        supportZoom: false,
        transparentBackground: true,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,

        // User agent: pretend to be a real mobile browser so cineby.at
        // renders its mobile layout correctly
        userAgent:
            'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      ),

      // --- JavaScript Channels ---
      onWebViewCreated: (controller) {
        ref
            .read(webviewControllerProvider.notifier)
            .setController(controller);

        // Register JS handlers BEFORE page loads. In flutter_inappwebview 6.x,
        // these are exposed on the JS side as
        //   window.<handlerName>.postMessage(value1, value2, ...)
        // and the Dart callback receives a `List<dynamic>` of those args.
        controller.addJavaScriptHandler(
          handlerName: 'VideoChannel',
          callback: (args) {
            if (args.isEmpty) return null;
            final videoUrl = args.first?.toString() ?? '';
            ref
                .read(videoInterceptorProvider.notifier)
                .onVideoUrlDetected(videoUrl, context);
            return null;
          },
        );

        controller.addJavaScriptHandler(
          handlerName: 'DownloadChannel',
          callback: (args) {
            if (args.isEmpty) return null;
            final raw = args.first?.toString() ?? '';
            try {
              final data = jsonDecode(raw) as Map<String, dynamic>;
              final url = data['url'] as String? ?? '';
              final title = data['title'] as String? ?? 'Cineby Download';
              ref
                  .read(downloadServiceProvider.notifier)
                  .startDownload(url: url, title: title);
            } catch (e) {
              // ignore: avoid_print
              print('[DownloadChannel] parse error: $e');
            }
            return null;
          },
        );
      },

      // --- Page Load Hooks ---
      onLoadStop: (controller, url) async {
        final currentUrl = url?.toString() ?? '';

        // Re-inject on first load and on every navigation to a new path.
        // This handles SPA route changes that don't trigger a full reload.
        if (currentUrl != _lastInjectedUrl) {
          _lastInjectedUrl = currentUrl;

          // 1. Inject CSS overrides
          await _injectCss(controller);
          // 2. Inject video interceptor
          await controller.evaluateJavascript(
            source: videoInterceptScript,
          );
          // 3. Inject download button handler
          await controller.evaluateJavascript(
            source: downloadButtonScript,
          );
        }

        // 4. Update bottom nav active tab based on current URL
        ref
            .read(activeNavTabProvider.notifier)
            .updateFromUrl(currentUrl);

        // 5. Reset progress
        ref.read(pageLoadProgressProvider.notifier).setProgress(100);
      },

      // --- URL Loading Policy ---
      shouldOverrideUrlLoading: (controller, action) async {
        final url = action.request.url?.toString() ?? '';

        // Allow all cineby.at internal URLs
        if (url.startsWith(AppUrls.base)) {
          return NavigationActionPolicy.ALLOW;
        }

        // Block external redirects / ads silently
        return NavigationActionPolicy.CANCEL;
      },

      // --- Native Download Trigger ---
      onDownloadStartRequest: (controller, request) {
        final url = request.url.toString();
        ref.read(downloadServiceProvider.notifier).startDownload(
              url: url,
              title: 'Cineby Download',
              suggestedFileName: request.suggestedFilename,
            );
      },

      // --- Loading Feedback ---
      onProgressChanged: (controller, progress) {
        ref.read(pageLoadProgressProvider.notifier).setProgress(progress);
      },

      onReceivedError: (controller, request, error) {
        // ignore: avoid_print
        print(
            '[CinebyWebView] error ${error.description} for ${request.url}');
      },
    );
  }

  Future<void> _injectCss(InAppWebViewController controller) async {
    // Build a fresh <style> element whose textContent is the escaped CSS.
    // We use JSON encoding so backticks, dollar signs, and quotes in the
    // CSS survive the round-trip to JavaScript.
    final encoded = jsonEncode(cssOverrides);
    await controller.evaluateJavascript(
      source:
          "(function(){var s=document.createElement('style');"
          "s.textContent=$encoded;"
          "document.head.appendChild(s);})();",
    );
  }
}
