# cineby_app

A native Flutter wrapper for [cineby.at](https://www.cineby.at) with a native bottom navigation bar, a download manager for stream URLs, and a native video player for detected HLS/MP4 streams.

> The app loads the real cineby.at website inside a WebView (`flutter_inappwebview`) and adds native capabilities around it. It is not a clone and does not call TMDB directly.

## Architecture

```
lib/
├── main.dart                     # entry: init FlutterDownloader, Hive, lock orientation
├── app.dart                      # GoRouter + MaterialApp.router
├── core/
│   ├── constants/
│   │   ├── app_urls.dart         # cineby.at URLs
│   │   └── app_colors.dart       # dark palette
│   ├── services/
│   │   ├── video_interceptor.dart  # JS-bridge -> native player
│   │   └── download_service.dart   # flutter_downloader queue
│   └── utils/
│       ├── js_scripts.dart       # video + download JS injection
│       └── css_overrides.dart    # CSS hiding site chrome
├── features/
│   ├── webview/                  # InAppWebView widget, controllers, providers
│   ├── player/                   # Native Chewie-based video player
│   └── downloads/                # In-app downloads screen
└── shared/
    ├── navigation/               # AppShell + native bottom nav
    └── widgets/                  # DownloadFab, LoadingOverlay
```

## Build

```bash
flutter pub get
flutter run -d <device>
```

### Known build patch

`flutter_inappwebview_android 1.1.3` references `getDefaultProguardFile('proguard-android.txt')`, which the modern Android Gradle Plugin rejects with:

> `getDefaultProguardFile('proguard-android.txt')` is no longer supported since it includes -dontoptimize, which prevents R8 from performing many optimizations.

If you hit this, patch the cached file:

```
# In your pub cache, e.g. AppData\Local\Pub\Cache\hosted\pub.dev\flutter_inappwebview_android-1.1.3\android\build.gradle
# Change:
#   proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
# To:
#   proguardFiles 'proguard-rules.pro'
```

…or wait for an upstream `flutter_inappwebview_android` release that uses `proguard-android-optimize.txt`. This is a per-machine pub-cache patch; track it in your CI's post-install step.

## Native features

- **Native bottom nav** with five tabs (Home, Movies, TV Shows, Search, Watchlist). Tapping a tab navigates the WebView to the matching cineby.at URL. WebView navigation auto-highlights the right tab.
- **Video stream interceptor** — JS injected on every page load watches for `<video>` and `<source>` elements, patches `XMLHttpRequest.open` and `fetch`, and posts detected URLs (`.m3u8`, `.mp4`, `blob:`) to Flutter via the `VideoChannel` JS handler. Flutter pushes the native player route.
- **Native player** — `video_player` + `chewie` (the spec's fallback path; `better_player` 0.0.84 is unmaintained and uses `hashValues` which was removed from the Flutter SDK). Locks landscape, immersive mode, skips ±10s.
- **Download manager** — site's own download buttons are hijacked via JS (`DownloadChannel` handler). URLs go through `flutter_downloader` with progress notifications. In-app queue at `/downloads`.
- **Back-button handler** — `PopScope` around the app shell routes the Android back press to `controller.goBack()` instead of exiting the app.
- **External URL blocking** — `shouldOverrideUrlLoading` cancels any non-cineby.at redirect silently.

## Tests

```bash
flutter test
```

Smoke test covers `NavItem` ordering, the cineby.at URL contract, and the `ActiveNavTab.updateFromUrl()` URL→tab mapping.

## Platform notes

- **Android `minSdk = 21`** (required by `flutter_downloader` and `flutter_inappwebview`)
- **iOS deployment target 13.0** (Flutter default; `flutter_inappwebview` requires 12+)
- Android `AndroidManifest.xml` has `INTERNET`, `WAKE_LOCK`, `POST_NOTIFICATIONS`, and scoped storage permissions. `usesCleartextTraffic="true"` is enabled.
- iOS `Info.plist` has `NSAllowsArbitraryLoads` (so non-HTTPS video CDNs can stream), `WebKitMediaPlaybackAllowsInline`, `UIRequiresFullScreen`.
