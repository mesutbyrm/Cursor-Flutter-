import 'package:flutter/material.dart';

/// canlifal.com ana sayfa — statik keşfet ve fan club kartları.
class HomeDiscoverTile {
  const HomeDiscoverTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
  });

  final String id;
  final String label;
  final IconData icon;
  final List<Color> gradient;
  final String route;
}

class HomeFanClubItem {
  const HomeFanClubItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.route,
    this.memberCount,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String route;
  final int? memberCount;
}

abstract final class HomeSiteCatalog {
  static const discoverTiles = <HomeDiscoverTile>[
    HomeDiscoverTile(
      id: 'football',
      label: 'Canlı Futbol',
      icon: Icons.sports_soccer_rounded,
      gradient: [Color(0xFF22C55E), Color(0xFF14532D)],
      route: '/live',
    ),
    HomeDiscoverTile(
      id: 'series',
      label: 'Dizi & Film',
      icon: Icons.movie_creation_rounded,
      gradient: [Color(0xFFEF4444), Color(0xFF7F1D1D)],
      route: '/content-hub',
    ),
    HomeDiscoverTile(
      id: 'games',
      label: 'Oyunlar',
      icon: Icons.sports_esports_rounded,
      gradient: [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
      route: '/fortune',
    ),
    HomeDiscoverTile(
      id: 'trends',
      label: 'Trendler',
      icon: Icons.local_fire_department_rounded,
      gradient: [Color(0xFFFF6B35), Color(0xFFB832FF)],
      route: '/feed',
    ),
    HomeDiscoverTile(
      id: 'celebrities',
      label: 'Ünlüler',
      icon: Icons.star_rounded,
      gradient: [Color(0xFFFBBF24), Color(0xFFB45309)],
      route: '/social',
    ),
    HomeDiscoverTile(
      id: 'fanclub',
      label: 'Fan Club',
      icon: Icons.favorite_rounded,
      gradient: [Color(0xFFFF4FD8), Color(0xFF7B2FF7)],
      route: '/fan-club',
    ),
    HomeDiscoverTile(
      id: 'invite',
      label: 'Davet Et',
      icon: Icons.group_add_rounded,
      gradient: [Color(0xFF06B6D4), Color(0xFF0E7490)],
      route: '/invite-friends',
    ),
    HomeDiscoverTile(
      id: 'gifts',
      label: 'Hediyeler',
      icon: Icons.card_giftcard_rounded,
      gradient: [Color(0xFFFFD700), Color(0xFFB8860B)],
      route: '/profile/gifts',
    ),
  ];

  static const fanClubs = <HomeFanClubItem>[
    HomeFanClubItem(
      id: 'fb',
      title: 'Fenerbahçe',
      subtitle: 'Fan Club',
      imageUrl: 'https://canlifal.com/apple-touch-icon.png',
      route: '/fan-club',
      memberCount: 12400,
    ),
    HomeFanClubItem(
      id: 'gs',
      title: 'Galatasaray',
      subtitle: 'Fan Club',
      imageUrl: 'https://canlifal.com/favicon.ico',
      route: '/fan-club',
      memberCount: 15800,
    ),
    HomeFanClubItem(
      id: 'arda',
      title: 'Arda Güler',
      subtitle: 'Resmi Fan',
      imageUrl: 'https://canlifal.com/apple-touch-icon.png',
      route: '/fan-club',
      memberCount: 9200,
    ),
    HomeFanClubItem(
      id: 'burak',
      title: 'Burak Özçivit',
      subtitle: 'Fan Club',
      imageUrl: 'https://canlifal.com/favicon.ico',
      route: '/fan-club',
      memberCount: 6100,
    ),
  ];
}
