/// All cineby.at URLs used by the app shell and WebView.
class AppUrls {
  AppUrls._();

  static const String base = 'https://www.cineby.at';
  static const String home = 'https://www.cineby.at/';
  static const String movies = 'https://www.cineby.at/browse/movie';
  static const String tvShows = 'https://www.cineby.at/browse/tv';
  static const String search = 'https://www.cineby.at/search';
  static const String watchlist = 'https://www.cineby.at/watchlist';

  // Dynamic URL helpers
  static String movieDetail(int id) => '$base/movie/$id';
  static String tvDetail(int id) => '$base/tv/$id';
}
