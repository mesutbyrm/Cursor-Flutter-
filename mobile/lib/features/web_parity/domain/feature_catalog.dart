import 'package:flutter/material.dart';

/// Web'deki özelliklerin mobil giriş noktaları (ana sayfa kutuları + hub).
class FeatureEntry {
  const FeatureEntry({
    required this.label,
    required this.icon,
    required this.route,
    required this.colors,
    required this.group,
    this.onHome = false,
  });

  final String label;
  final IconData icon;
  final String route;
  final List<Color> colors;
  final String group;

  /// Ana sayfadaki 5 kutunun yanında (kaydırmalı satır) görünsün mü?
  final bool onHome;
}

const kFeatureGroups = <String>[
  'Keşfet ve oyna',
  'Rüya ve fal',
  'Üyelik ve cüzdan',
  'Yayıncı ve ajans',
  'Yardım',
];

const kFeatureCatalog = <FeatureEntry>[
  FeatureEntry(
    label: 'Liderlik',
    icon: Icons.emoji_events_rounded,
    route: '/liderlik',
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    group: 'Keşfet ve oyna',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Rüya Trendleri',
    icon: Icons.nights_stay_rounded,
    route: '/ruya/trendler',
    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
    group: 'Rüya ve fal',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Lamba Cini',
    icon: Icons.auto_awesome_rounded,
    route: '/oyunlar/lamba-cini',
    colors: [Color(0xFFEAB308), Color(0xFFF97316)],
    group: 'Keşfet ve oyna',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Oyun Lobisi',
    icon: Icons.sports_esports_rounded,
    route: '/oyunlar/lobi',
    colors: [Color(0xFF22C55E), Color(0xFF0EA5E9)],
    group: 'Keşfet ve oyna',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Falcı Sohbeti',
    icon: Icons.forum_rounded,
    route: '/falci-sohbet',
    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    group: 'Rüya ve fal',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Destek',
    icon: Icons.support_agent_rounded,
    route: '/destek',
    colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
    group: 'Yardım',
    onHome: true,
  ),
  FeatureEntry(
    label: 'Rüya Üret',
    icon: Icons.psychology_alt_rounded,
    route: '/ruya/uret',
    colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
    group: 'Rüya ve fal',
  ),
  FeatureEntry(
    label: 'Rüya Yarışması',
    icon: Icons.bedtime_rounded,
    route: '/dreams/contest',
    colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
    group: 'Rüya ve fal',
  ),
  FeatureEntry(
    label: 'Burç Uyumu',
    icon: Icons.favorite_border_rounded,
    route: '/astrology/compatibility',
    colors: [Color(0xFFEC4899), Color(0xFFF97316)],
    group: 'Rüya ve fal',
  ),
  FeatureEntry(
    label: 'Futbol',
    icon: Icons.sports_soccer_rounded,
    route: '/football',
    colors: [Color(0xFF16A34A), Color(0xFF65A30D)],
    group: 'Keşfet ve oyna',
  ),
  FeatureEntry(
    label: 'Üyelik Hediye Et',
    icon: Icons.card_giftcard_rounded,
    route: '/uyelik/hediye',
    colors: [Color(0xFFF43F5E), Color(0xFFF59E0B)],
    group: 'Üyelik ve cüzdan',
  ),
  FeatureEntry(
    label: 'Plan Karşılaştır',
    icon: Icons.compare_arrows_rounded,
    route: '/uyelik/karsilastir',
    colors: [Color(0xFFFFD700), Color(0xFFFF8A00)],
    group: 'Üyelik ve cüzdan',
  ),
  FeatureEntry(
    label: 'İade Talebi',
    icon: Icons.assignment_return_rounded,
    route: '/iade',
    colors: [Color(0xFF64748B), Color(0xFF0EA5E9)],
    group: 'Üyelik ve cüzdan',
  ),
  FeatureEntry(
    label: 'Falcı Paneli',
    icon: Icons.dashboard_customize_rounded,
    route: '/falci-paneli',
    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
    group: 'Yayıncı ve ajans',
  ),
  FeatureEntry(
    label: 'Ajans Büyümesi',
    icon: Icons.trending_up_rounded,
    route: '/ajans/buyume',
    colors: [Color(0xFF10B981), Color(0xFF06B6D4)],
    group: 'Yayıncı ve ajans',
  ),
  FeatureEntry(
    label: 'Bildirim Tanılama',
    icon: Icons.notifications_active_rounded,
    route: '/settings/notifications/diagnostics',
    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    group: 'Yardım',
  ),
];
