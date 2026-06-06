import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/js_scripts.dart';

/// Detected video stream awaiting a native player handoff.
class DetectedVideo {
  const DetectedVideo({required this.url, required this.detectedAt});
  final String url;
  final DateTime detectedAt;
}

/// Riverpod state holding the most recently detected video stream URL.
///
/// The WebView's JS channel posts here whenever it finds a playable URL.
/// `app_shell` listens and, if appropriate, pushes the native player route.
final videoInterceptorProvider =
    NotifierProvider<VideoInterceptor, DetectedVideo?>(
  VideoInterceptor.new,
);

class VideoInterceptor extends Notifier<DetectedVideo?> {
  @override
  DetectedVideo? build() => null;

  /// Called from the JS `VideoChannel` callback.
  /// [context] must be a Navigator-aware context (typically the AppShell's).
  void onVideoUrlDetected(String url, BuildContext context) {
    if (url.isEmpty) return;
    if (state?.url == url) return; // de-dupe consecutive identical reports

    state = DetectedVideo(url: url, detectedAt: DateTime.now());

    // Don't open the player for URLs we can't actually play natively
    // (e.g. blob: URLs in older webviews, or DRM-protected manifests).
    if (url.startsWith('blob:')) {
      // The site owns the playback; let the WebView handle it.
      return;
    }

    final router = GoRouter.maybeOf(context);
    router?.push('/player', extra: url);
  }

  /// Returns the JS script that should be evaluated inside the WebView.
  /// Exposed here so the WebView feature can inject it on every page load.
  String get injectionScript => videoInterceptScript;
}
