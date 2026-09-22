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

/// Falcı panelindeki tüm Claude + P0/P1 ekranları — keşif kataloğu.
List<PsychicFeatureCatalogSection> psychicTellerFeaturesCatalog({
  required String profileId,
}) {
  String p(String path) => path;
  String profileRoute() => '/canli-falcilar/$profileId';

  return [
    PsychicFeatureCatalogSection(
      title: 'Günlük panel (P0)',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Canlı panel',
          subtitle: 'Gelen talepler, çevrimiçi durumu',
          icon: Icons.dashboard_customize_rounded,
          routePath: p('/canli-falcilar/dashboard'),
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
        PsychicFeatureCatalogItem(
          title: 'Profil düzenle',
          subtitle: 'Bio, foto, uzmanlık',
          icon: Icons.edit_rounded,
          routePath: p('/canli-falcilar/dashboard/profile-edit'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Takvim & müsaitlik',
          subtitle: 'Seans saatleri',
          icon: Icons.calendar_month_rounded,
          routePath: p('/canli-falcilar/dashboard/schedule'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Müsaitlik takvimi',
          subtitle: 'Detaylı slot yönetimi',
          icon: Icons.event_available_rounded,
          routePath: p('/canli-falcilar/availability'),
          tier: PsychicFeatureTier.p1,
        ),
        PsychicFeatureCatalogItem(
          title: 'Seans geçmişi',
          subtitle: 'Tamamlanan görüşmeler',
          icon: Icons.history_rounded,
          routePath: p('/canli-falcilar/sessions'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Müşteriler',
          subtitle: 'CRM listesi',
          icon: Icons.people_rounded,
          routePath: p('/canli-falcilar/customers'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Yorumlar & puan',
          subtitle: 'Değerlendirme merkezi',
          icon: Icons.star_rounded,
          routePath: p('/canli-falcilar/dashboard/reviews'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Puan sistemi',
          subtitle: 'Detaylı rating analizi',
          icon: Icons.grade_rounded,
          routePath: p('/canli-falcilar/ratings'),
          tier: PsychicFeatureTier.p1,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'Kazanç & analitik',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Kazançlar',
          subtitle: 'Bakiye ve ödemeler',
          icon: Icons.payments_rounded,
          routePath: p('/canli-falcilar/earnings'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Analitikler',
          subtitle: 'Performans özeti',
          icon: Icons.analytics_rounded,
          routePath: p('/canli-falcilar/analytics'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Metrikler',
          subtitle: 'Canlı KPI panosu',
          icon: Icons.trending_up_rounded,
          routePath: p('/canli-falcilar/metrics'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Kazanç analitiği',
          subtitle: 'Gelir kırılımı',
          icon: Icons.insights_rounded,
          routePath: p('/canli-falcilar/earnings-analytics'),
          tier: PsychicFeatureTier.p1,
        ),
        PsychicFeatureCatalogItem(
          title: 'Analitik dışa aktar',
          subtitle: 'CSV / rapor',
          icon: Icons.file_download_rounded,
          routePath: p('/canli-falcilar/analytics-export'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Gelir tahmini',
          subtitle: 'Forecasting',
          icon: Icons.show_chart_rounded,
          routePath: p('/canli-falcilar/revenue-forecasting'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Vergi raporlama',
          subtitle: 'Mali özet',
          icon: Icons.receipt_long_rounded,
          routePath: p('/canli-falcilar/tax-reporting'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Para çekme',
          subtitle: 'Withdrawal yönetimi',
          icon: Icons.account_balance_wallet_rounded,
          routePath: p('/canli-falcilar/withdrawal-management'),
          tier: PsychicFeatureTier.p1,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'Büyüme & pazarlama',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Kampanyalar',
          subtitle: 'Promosyonlar',
          icon: Icons.local_offer_rounded,
          routePath: p('/canli-falcilar/campaigns'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Kampanya yönetimi',
          subtitle: 'Gelişmiş kampanya stüdyosu',
          icon: Icons.campaign_rounded,
          routePath: p('/canli-falcilar/campaign-management'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Flash satış',
          subtitle: 'Sınırlı süre fiyat',
          icon: Icons.flash_on_rounded,
          routePath: p('/canli-falcilar/flash-sales'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Referans programı',
          subtitle: 'Arkadaşını getir',
          icon: Icons.group_add_rounded,
          routePath: p('/canli-falcilar/referral'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Takipçiler',
          subtitle: 'Sadık kitlen',
          icon: Icons.favorite_rounded,
          routePath: p('/canli-falcilar/followers'),
          tier: PsychicFeatureTier.p1,
        ),
        PsychicFeatureCatalogItem(
          title: 'Sosyal medya planlayıcı',
          subtitle: 'İçerik takvimi',
          icon: Icons.share_rounded,
          routePath: p('/canli-falcilar/social-media-planner'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Büyüme metrikleri',
          subtitle: 'Growth dashboard',
          icon: Icons.rocket_launch_rounded,
          routePath: p('/canli-falcilar/growth-metrics'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Fiyat optimizasyonu',
          subtitle: 'Dakika ücreti önerileri',
          icon: Icons.price_change_rounded,
          routePath: p('/canli-falcilar/pricing-optimization'),
          tier: PsychicFeatureTier.pro,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'Müşteri deneyimi',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Bildirim ayarları',
          subtitle: 'Panel bildirimleri',
          icon: Icons.notifications_rounded,
          routePath: p('/canli-falcilar/settings/notifications'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Bildirim merkezi',
          subtitle: 'Gelişmiş bildirim tercihleri',
          icon: Icons.notifications_active_rounded,
          routePath: p('/canli-falcilar/notifications'),
          tier: PsychicFeatureTier.p1,
        ),
        PsychicFeatureCatalogItem(
          title: 'Mesaj şablonları',
          subtitle: 'Hazır yanıtlar',
          icon: Icons.quickreply_rounded,
          routePath: p('/canli-falcilar/message-templates'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Müşteri kimyası',
          subtitle: 'Uyum skorları',
          icon: Icons.psychology_rounded,
          routePath: p('/canli-falcilar/customer-chemistry'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Müşteri LTV',
          subtitle: 'Yaşam boyu değer',
          icon: Icons.diamond_rounded,
          routePath: p('/canli-falcilar/customer-ltv-optimization'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Geri bildirim yönetimi',
          subtitle: 'Feedback inbox',
          icon: Icons.feedback_rounded,
          routePath: p('/canli-falcilar/feedback-management'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Churn analizi',
          subtitle: 'Kayıp müşteri',
          icon: Icons.trending_down_rounded,
          routePath: p('/canli-falcilar/churn-analysis'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Gelişmiş arama',
          subtitle: 'Müşteri / seans filtre',
          icon: Icons.manage_search_rounded,
          routePath: p('/canli-falcilar/advanced-search'),
          tier: PsychicFeatureTier.pro,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'Oyunlaştırma & rozetler',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Rozetler',
          subtitle: 'Başarı rozetleri',
          icon: Icons.emoji_events_rounded,
          routePath: p('/canli-falcilar/badges'),
          tier: PsychicFeatureTier.p0,
        ),
        PsychicFeatureCatalogItem(
          title: 'Gamification',
          subtitle: 'Seviye, görev, ödül',
          icon: Icons.videogame_asset_rounded,
          routePath: p('/canli-falcilar/gamification'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Paket yönetimi',
          subtitle: 'Seans paketleri',
          icon: Icons.inventory_2_rounded,
          routePath: p('/canli-falcilar/packages'),
          tier: PsychicFeatureTier.p1,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'Operasyon & otomasyon',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Müşteri yönetimi',
          subtitle: 'Gelişmiş CRM',
          icon: Icons.support_agent_rounded,
          routePath: p('/canli-falcilar/client-management'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Seans otomasyonu',
          subtitle: 'Kural tabanlı akış',
          icon: Icons.smart_toy_rounded,
          routePath: p('/canli-falcilar/session-automation'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Takvim optimizasyonu',
          subtitle: 'Slot önerileri',
          icon: Icons.schedule_rounded,
          routePath: p('/canli-falcilar/scheduling-optimization'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'İş akışı otomasyonu',
          subtitle: 'Workflow builder',
          icon: Icons.account_tree_rounded,
          routePath: p('/canli-falcilar/workflow-automation'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Takım çalışma alanı',
          subtitle: 'Asistan / ekip',
          icon: Icons.groups_rounded,
          routePath: p('/canli-falcilar/team-workspace'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Seans kaydı',
          subtitle: 'Recording ayarları',
          icon: Icons.fiber_manual_record_rounded,
          routePath: p('/canli-falcilar/session-recording'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'AI asistan',
          subtitle: 'Chatbot yardımcı',
          icon: Icons.auto_awesome_rounded,
          routePath: p('/canli-falcilar/ai-chatbot'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Uyumluluk & hukuk',
          subtitle: 'Politika ve onaylar',
          icon: Icons.gavel_rounded,
          routePath: p('/canli-falcilar/compliance-legal'),
          tier: PsychicFeatureTier.pro,
        ),
      ],
    ),
    PsychicFeatureCatalogSection(
      title: 'İleri analitik',
      items: [
        PsychicFeatureCatalogItem(
          title: 'Performans içgörüleri',
          subtitle: 'Derinlemesine analiz',
          icon: Icons.lightbulb_rounded,
          routePath: p('/canli-falcilar/performance-insights'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Elde tutma analitiği',
          subtitle: 'Retention',
          icon: Icons.loop_rounded,
          routePath: p('/canli-falcilar/retention-analytics'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Davranış analitiği',
          subtitle: 'Kullanıcı yolculuğu',
          icon: Icons.route_rounded,
          routePath: p('/canli-falcilar/behavior-analytics'),
          tier: PsychicFeatureTier.pro,
        ),
        PsychicFeatureCatalogItem(
          title: 'Kıyaslama',
          subtitle: 'Benchmark',
          icon: Icons.leaderboard_rounded,
          routePath: p('/canli-falcilar/benchmarking'),
          tier: PsychicFeatureTier.pro,
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
