// Widget tests for cineby_app.
//
// A full UI test would require booting a real WebView (flutter_inappwebview
// ships its own test platform, but wiring it up here is more work than the
// value warrants). Instead, this file exercises the pure-Dart layer:
//
//   • NavItem is wired up so all five labels are present.
//   • The active-tab provider flips correctly when the URL changes.
//
// Run with: flutter test

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cineby_app/core/constants/app_urls.dart';
import 'package:cineby_app/features/webview/webview_controller_provider.dart';
import 'package:cineby_app/shared/navigation/nav_item.dart';

void main() {
  group('NavItem tab list', () {
    test('has exactly five tabs in the canonical order', () {
      expect(kAppNavTabs.length, 5);
      expect(kAppNavTabs[0].label, 'Home');
      expect(kAppNavTabs[1].label, 'Movies');
      expect(kAppNavTabs[2].label, 'TV Shows');
      expect(kAppNavTabs[3].label, 'Search');
      expect(kAppNavTabs[4].label, 'Watchlist');
    });

    test('every tab points at a cineby.at URL', () {
      for (final t in kAppNavTabs) {
        expect(t.url, startsWith('https://www.cineby.at'));
      }
    });

    test('home tab points at AppUrls.home', () {
      expect(kAppNavTabs[0].url, AppUrls.home);
      expect(kAppNavTabs[1].url, AppUrls.movies);
      expect(kAppNavTabs[2].url, AppUrls.tvShows);
      expect(kAppNavTabs[3].url, AppUrls.search);
      expect(kAppNavTabs[4].url, AppUrls.watchlist);
    });
  });

  group('ActiveNavTab.updateFromUrl', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    int readActive() => container.read(activeNavTabProvider);

    test('browse/movie -> Movies tab', () {
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/browse/movie');
      expect(readActive(), 1);
    });

    test('browse/tv -> TV Shows tab', () {
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/browse/tv');
      expect(readActive(), 2);
    });

    test('search -> Search tab', () {
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/search?q=foo');
      expect(readActive(), 3);
    });

    test('watchlist -> Watchlist tab', () {
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/watchlist');
      expect(readActive(), 4);
    });

    test('root URL -> Home tab', () {
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/');
      expect(readActive(), 0);
    });

    test('movie detail page leaves the active tab unchanged', () {
      // Per spec: detail pages don't change the nav tab.
      // First set it to a known tab, then visit a /movie/ URL.
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/browse/movie');
      expect(readActive(), 1);
      container.read(activeNavTabProvider.notifier)
          .updateFromUrl('https://www.cineby.at/movie/12345');
      expect(readActive(), 1);
    });
  });
}
