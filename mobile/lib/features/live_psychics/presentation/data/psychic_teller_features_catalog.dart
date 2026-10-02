import 'package:flutter/material.dart';

enum PsychicFeatureTier { p0, p1, pro }

class PsychicFeatureCatalogItem {
  const PsychicFeatureCatalogItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routePath,
    this.tier = PsychicFeatureTier.pro,
    this.requiresProfileId = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  /// `/canli-falcilar/...` — `{id}` profil rotası için yer tutucu.
  final String routePath;
  final PsychicFeatureTier tier;
  final bool requiresProfileId;
}

class PsychicFeatureCatalogSection {
  const PsychicFeatureCatalogSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<PsychicFeatureCatalogItem> items;
}

/// Falcı paneli — YALNIZCA gerçek veriye bağlı ekranlar.
///
/// Eskiden ~45 ekran sabit/sahte veriyle listeleniyordu (sahte kazanç, sahte
/// banka hesapları, hiçbir şey göndermeyen «Çekim talebi gönderildi»). Sunucu
/// karşılığı olmayan ekranlar kaldırıldı; kazanç ve para çekme için cüzdan
/// kullanılır.
List<PsychicFeatureCatalogSection> psychicTellerFeaturesCatalog({
  required String profileId,
}) {
  String profileRoute() => '/canli-falcilar/$profileId';

  return [
    PsychicFeatureCatalogSection(
      title: 'Günlük panel',
      items: [
        const PsychicFeatureCatalogItem(
          title: 'Canlı panel',
          subtitle: 'Gelen talepler, çevrimiçi durumu',
          icon: Icons.dashboard_customize_rounded,
          routePath: '/canli-falcilar/dashboard',
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Halka açık profilim',
          subtitle: 'Müşterilerin gördüğü vitrin',
          icon: Icons.person_rounded,
          routePath: profileRoute(),
          tier: PsychicFeatureTier.p0,
          requiresProfileId: true,
        ),
        const PsychicFeatureCatalogItem(
          title: 'Seans geçmişi',
          subtitle: 'Tamamlanan görüşmeler',
          icon: Icons.history_rounded,
          routePath: '/canli-falcilar/sessions',
          tier: PsychicFeatureTier.p1,
        ),
        const PsychicFeatureCatalogItem(
          title: 'Yorumlar ve puan',
          subtitle: 'Aldığın değerlendirmeler',
          icon: Icons.reviews_rounded,
          routePath: '/canli-falcilar/dashboard/reviews',
          tier: PsychicFeatureTier.p1,
        ),
        const PsychicFeatureCatalogItem(
          title: 'Kazanç ve para çekme',
          subtitle: 'Cüzdan',
          icon: Icons.account_balance_wallet_rounded,
          routePath: '/wallet',
          tier: PsychicFeatureTier.p1,
        ),
      ],
    ),
  ];
}

String psychicFeatureTierLabel(PsychicFeatureTier tier) {
  return switch (tier) {
    PsychicFeatureTier.p0 => 'P0',
    PsychicFeatureTier.p1 => 'P1',
    PsychicFeatureTier.pro => 'Pro',
  };
}

Color psychicFeatureTierColor(PsychicFeatureTier tier) {
  return switch (tier) {
    PsychicFeatureTier.p0 => const Color(0xFF4ADE80),
    PsychicFeatureTier.p1 => const Color(0xFF38BDF8),
    PsychicFeatureTier.pro => const Color(0xFFE879F9),
  };
}
