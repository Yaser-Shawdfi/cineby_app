import 'package:flutter/material.dart';

import '../../core/constants/app_urls.dart';

/// One entry in the native bottom navigation bar.
class NavItem {
  const NavItem({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;
}

/// The canonical tab list, in display order. Indices line up with
/// [activeNavTabProvider]'s state.
const List<NavItem> kAppNavTabs = [
  NavItem(icon: Icons.home_rounded, label: 'Home', url: AppUrls.home),
  NavItem(icon: Icons.movie_rounded, label: 'Movies', url: AppUrls.movies),
  NavItem(icon: Icons.tv_rounded, label: 'TV Shows', url: AppUrls.tvShows),
  NavItem(icon: Icons.search_rounded, label: 'Search', url: AppUrls.search),
  NavItem(icon: Icons.bookmark_rounded, label: 'Watchlist', url: AppUrls.watchlist),
];
