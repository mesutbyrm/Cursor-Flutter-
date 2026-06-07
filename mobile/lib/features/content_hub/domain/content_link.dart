import 'package:flutter/material.dart';

/// Site SEO / blog / rüya sayfaları — WebView veya harici route.
class ContentLink {
  const ContentLink({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String path;
  final IconData icon;
}

abstract final class ContentHubCatalog {
  static const sections = <(String, List<ContentLink>)>[
    (
      'Blog & Astroloji',
      [
        ContentLink(
          title: 'Blog',
          subtitle: 'Makaleler ve rehberler',
          path: '/blog',
          icon: Icons.menu_book_rounded,
        ),
        ContentLink(
          title: 'Burçlar',
          subtitle: 'Burç yazıları',
          path: '/blog/burclar',
          icon: Icons.star_rounded,
        ),
      ],
    ),
    (
      'Rüya',
      [
        ContentLink(
          title: 'Rüya tabiri',
          subtitle: 'Rüya yorumları',
          path: '/ruya',
          icon: Icons.nights_stay_rounded,
        ),
        ContentLink(
          title: 'Rüya sözlüğü',
          subtitle: 'Semboller ve anlamlar',
          path: '/ruya-sozlugu',
          icon: Icons.auto_stories_rounded,
        ),
        ContentLink(
          title: 'Rüya trendleri',
          subtitle: 'Popüler rüyalar',
          path: '/ruya-trendleri',
          icon: Icons.trending_up_rounded,
        ),
        ContentLink(
          title: 'Rüya takvimi',
          subtitle: 'Günlük rüya enerjisi',
          path: '/ruya-takvimi',
          icon: Icons.calendar_month_rounded,
        ),
      ],
    ),
    (
      'Fal & topluluk',
      [
        ContentLink(
          title: 'Popüler falcılar',
          subtitle: 'Uzman listesi',
          path: '/populer-falcilar',
          icon: Icons.psychology_rounded,
        ),
        ContentLink(
          title: 'Falcı ol',
          subtitle: 'Başvuru',
          path: '/falci-ol',
          icon: Icons.workspace_premium_rounded,
        ),
        ContentLink(
          title: 'Ajans ol',
          subtitle: 'Partner başvurusu',
          path: '/ajans-ol',
          icon: Icons.business_center_rounded,
        ),
        ContentLink(
          title: 'Fan Club',
          subtitle: 'Üretici kulüpleri',
          path: '/fan-club',
          icon: Icons.groups_rounded,
        ),
      ],
    ),
  ];
}
