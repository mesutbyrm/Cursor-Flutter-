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
        ContentLink(
          title: 'Çevrimiçi',
          subtitle: 'Şu anda sitede olanlar',
          path: '/cevrimici',
          icon: Icons.circle_rounded,
        ),
        ContentLink(
          title: 'Seni beğenenler',
          subtitle: 'Profil beğenileri',
          path: '/likers',
          icon: Icons.favorite_rounded,
        ),
        ContentLink(
          title: 'Duyurular',
          subtitle: 'Site duyuruları',
          path: '/duyurular',
          icon: Icons.campaign_rounded,
        ),
        ContentLink(
          title: 'Futbol',
          subtitle: 'Canlı skorlar',
          path: '/futbol',
          icon: Icons.sports_soccer_rounded,
        ),
      ],
    ),
  ];
}
