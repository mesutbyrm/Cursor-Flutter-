import 'package:flutter/material.dart';

import '../providers/staff_access_provider.dart';

/// Yönetim menüsünde uygulama içi işlem (sayfa yerine sayfa üstü pencere).
enum AdminNavAction { creditJeton, creditCfc, grantMembership, todayStats }

/// Tek yönetim menüsü maddesi.
///
/// Her işlev menüde yalnız bir kez bulunur. Hedef:
///  • [route]: uygulamadaki, sunucu ucu çalışan yerel ekran,
///  • [webPath]: web yönetim panelindeki aynı sayfa (uygulama içinde açılır),
///  • [action]: kullanıcı seçip jeton/CFC/üyelik işlemi gibi pencere.
/// Hem [route] hem [webPath] varsa ve [preferWeb] ise web sayfası (sitedeki
/// gibi) açılır; web paneline erişimi olmayan yetkili (ör. finans) yerel
/// ekranı görür.
class AdminNavItem {
  const AdminNavItem({
    required this.label,
    required this.description,
    required this.icon,
    this.route,
    this.webPath,
    this.action,
    this.preferWeb = false,
    this.nativeVisible = true,
  });

  final String label;
  final String description;
  final IconData icon;
  final String? route;
  final String? webPath;
  final AdminNavAction? action;
  final bool preferWeb;

  /// Yerel hedefin ([route] / [action]) yetki koşulu.
  final bool nativeVisible;

  bool get hasNative => route != null || action != null;

  /// Bu kullanıcı için madde görünür mü / nereye gider.
  AdminNavTarget? resolve({required bool webAccess}) {
    final web = webPath != null && webAccess;
    final native = hasNative && nativeVisible;
    if (web && (preferWeb || !native)) return AdminNavTarget.web(webPath!);
    if (native) {
      return action != null
          ? AdminNavTarget.action(action!)
          : AdminNavTarget.route(route!);
    }
    return null;
  }
}

class AdminNavTarget {
  const AdminNavTarget._({this.route, this.webPath, this.action});
  const AdminNavTarget.route(String r) : this._(route: r);
  const AdminNavTarget.web(String p) : this._(webPath: p);
  const AdminNavTarget.action(AdminNavAction a) : this._(action: a);

  final String? route;
  final String? webPath;
  final AdminNavAction? action;

  bool get isWeb => webPath != null;
}

class AdminNavGroup {
  const AdminNavGroup({
    required this.title,
    required this.emoji,
    required this.items,
  });

  final String title;
  final String emoji;
  final List<AdminNavItem> items;
}

/// Tek yönetim menüsüne ([adminNavGroups]) taşınan eski hub'lar ve sunucuda
/// ucu olmadığı için çalışmayan / sahte veri gösteren ekranlar. Bu yollara
/// giden eski bağlantılar (bildirim, eski sürüm, yer imi) Yönetim Paneli'ne
/// yönlenir.
const adminRetiredPaths = <String>{
  // Eski menü / hub sayfaları (aynı işlevler Yönetim Paneli'nde)
  '/admin/panel',
  '/admin/home',
  '/admin/tools',
  '/admin/visual-fx',
  '/admin/collections',
  '/admin/live-broadcasts-control',
  // Sunucuda ucu olmayan ekranlar (/api/admin/users/... yok)
  '/admin/activity-monitoring',
  '/admin/activity-log',
  '/admin/fraud-detection',
  '/admin/bulk-operations',
  '/admin/team-management',
  '/admin/system-config',
  // Sahte / yerel veri gösteren ekranlar
  '/admin/audit-logs',
  '/admin/user-sessions',
  '/admin/security',
  '/admin/feature-flags',
  '/admin/email-templates',
  '/admin/preferences',
  '/admin/notification-manager',
  '/admin/entrance-effects',
};

/// Web yönetim panelindeki bir sayfayı uygulama içinde açan rota.
String adminWebRoute(String path, String title) => Uri(
      path: '/admin/web',
      queryParameters: {'path': path, 'title': title},
    ).toString();

/// Web yönetim paneliyle (canlifal.com/admin) aynı gruplar, aynı sıra ve
/// aynı başlıklar. Uygulamada sunucu ucu çalışan ekranı olan maddeler yerel
/// ekrana, diğerleri web panelindeki aynı sayfaya gider.
List<AdminNavGroup> adminNavGroups(StaffAccess a) {
  final pay = a.canManagePayments;
  final site = a.isSiteAdmin;
  return [
    AdminNavGroup(
      title: 'Genel',
      emoji: '📊',
      items: [
        AdminNavItem(
          label: 'Gösterge Paneli',
          description: 'Kullanıcı, jeton/CFC, oda ve yayın özetleri',
          icon: Icons.dashboard_rounded,
          route: '/admin/dashboard',
          nativeVisible: a.hasFullAdminDashboard || pay,
        ),
        AdminNavItem(
          label: 'Bugün & İstatistikler',
          description: 'Bugün üye olan, jeton alan, oda açan, en çok kazanan',
          icon: Icons.insights_rounded,
          action: AdminNavAction.todayStats,
          nativeVisible: pay,
        ),
        const AdminNavItem(
          label: 'Gelir-Gider & Site İstatistikleri',
          description: 'Gelir-gider, hediye komisyonu, reklam, ziyaretçi',
          icon: Icons.query_stats_rounded,
          webPath: '/admin',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Profil & Kullanıcı',
      emoji: '👤',
      items: [
        AdminNavItem(
          label: 'Kullanıcı Yönetimi',
          description: 'Üyeleri düzenle & yönet',
          icon: Icons.manage_accounts_rounded,
          route: '/admin/users',
          nativeVisible: a.canManageUsers || pay,
        ),
        AdminNavItem(
          label: 'Üyelik Yönetimi (VIP Yetenek Matrisi)',
          description: 'Kademe & özellik matrisi',
          icon: Icons.workspace_premium_rounded,
          route: '/admin/membership-management',
          webPath: '/admin/membership-features',
          preferWeb: true,
          nativeVisible: site || pay,
        ),
        const AdminNavItem(
          label: 'Gold Üyelik Paketleri',
          description: 'VIP üyelik paketleri ve satın almalar',
          icon: Icons.diamond_rounded,
          webPath: '/admin/memberships',
        ),
        AdminNavItem(
          label: 'Kullanıcıya Üyelik Ver',
          description: 'Gold / Premium / Diamond tanımla',
          icon: Icons.card_membership_rounded,
          action: AdminNavAction.grantMembership,
          nativeVisible: pay,
        ),
        const AdminNavItem(
          label: 'Üyelik Rozetleri',
          description: 'Üyelik seviye rozetleri',
          icon: Icons.military_tech_rounded,
          webPath: '/admin/membership-badges',
        ),
        const AdminNavItem(
          label: 'Rozet Yönetimi',
          description: 'Rozetleri oluştur & ata',
          icon: Icons.verified_rounded,
          webPath: '/admin/badges',
        ),
        const AdminNavItem(
          label: 'Profil Çerçeveleri',
          description: 'Profil çerçeveleri',
          icon: Icons.filter_frames_rounded,
          webPath: '/admin/profile-frames',
        ),
        const AdminNavItem(
          label: 'İçerik Moderasyonu',
          description: 'Raporlanan içerikler',
          icon: Icons.shield_rounded,
          webPath: '/admin/moderation',
        ),
        const AdminNavItem(
          label: 'Destek Talepleri',
          description: 'Kullanıcı destek talepleri',
          icon: Icons.support_agent_rounded,
          webPath: '/admin/support',
        ),
        AdminNavItem(
          label: 'Şikayet Yönetimi',
          description: 'Kullanıcı şikayetlerini incele & çöz',
          icon: Icons.report_rounded,
          route: '/admin/complaints',
          nativeVisible: a.canViewReports || a.canModerate,
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Sesli Odalar',
      emoji: '🎙️',
      items: [
        AdminNavItem(
          label: 'Sohbet Odaları',
          description: 'Oda yönetimi, koltuklar, kapatma',
          icon: Icons.mic_rounded,
          route: '/admin/voice-rooms',
          nativeVisible: a.canManageVoiceRooms || pay,
        ),
        const AdminNavItem(
          label: 'Oda Temaları',
          description: 'Oda arka plan temaları',
          icon: Icons.landscape_rounded,
          webPath: '/admin/room-themes',
        ),
        const AdminNavItem(
          label: 'Oda Arka Planları',
          description: 'VIP, Premium ve efektli arka planlar',
          icon: Icons.wallpaper_rounded,
          webPath: '/admin/room-themes/backgrounds',
        ),
        const AdminNavItem(
          label: 'Mikrofon Çerçeveleri',
          description: 'Koltuk/mikrofon çerçeveleri',
          icon: Icons.settings_voice_rounded,
          webPath: '/admin/mic-frames',
        ),
        const AdminNavItem(
          label: 'Sohbet Balonları',
          description: 'Mesaj balonu görünümleri',
          icon: Icons.chat_bubble_rounded,
          webPath: '/admin/chat-bubbles',
        ),
        const AdminNavItem(
          label: 'Emoji Paketleri',
          description: 'Özel emoji koleksiyonları',
          icon: Icons.emoji_emotions_rounded,
          webPath: '/admin/emoji-packs',
        ),
        AdminNavItem(
          label: 'Oda Finans Denetimi',
          description: 'Oda hediye gelirleri ve komisyon denetimi',
          icon: Icons.account_balance_rounded,
          route: '/admin/voice-finance',
          nativeVisible: a.canManageVoiceRooms || pay,
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Canlı Yayın',
      emoji: '📡',
      items: [
        AdminNavItem(
          label: 'Canlı Yayın Yönetimi',
          description: 'Aktif yayınlar & kontrol',
          icon: Icons.live_tv_rounded,
          route: '/admin/live-streams',
          nativeVisible: a.canManageLiveStreams,
        ),
        AdminNavItem(
          label: 'Yayın İstatistikleri',
          description: 'Günlük yayın, izleyici ve süre',
          icon: Icons.bar_chart_rounded,
          route: '/admin/live-stats',
          nativeVisible: a.canManageLiveStreams || a.canViewReports,
        ),
        const AdminNavItem(
          label: 'Yayın Resimleri',
          description: 'Yayın arka plan görselleri',
          icon: Icons.image_rounded,
          webPath: '/admin/broadcast-images',
        ),
        const AdminNavItem(
          label: 'Bağlantı Kalitesi',
          description: 'Canlı görüşme ağ kalite ölçümleri',
          icon: Icons.network_check_rounded,
          webPath: '/admin/rtc-telemetry',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Sosyal & İçerik',
      emoji: '🌐',
      items: [
        const AdminNavItem(
          label: 'Blog Yönetimi',
          description: 'Yazıları oluştur & düzenle',
          icon: Icons.article_rounded,
          webPath: '/admin/blog',
        ),
        const AdminNavItem(
          label: 'Rüya Tabirleri',
          description: 'Rüya yorumları',
          icon: Icons.nights_stay_rounded,
          webPath: '/admin/dreams',
        ),
        const AdminNavItem(
          label: 'Sayfa Yönetimi',
          description: 'Statik sayfaları düzenle',
          icon: Icons.description_rounded,
          webPath: '/admin/site-pages',
        ),
        const AdminNavItem(
          label: 'Fal İstek Türleri',
          description: 'Fal türlerini oluştur & düzenle',
          icon: Icons.auto_awesome_rounded,
          webPath: '/admin/fortune-types',
        ),
        const AdminNavItem(
          label: 'Bana Özel Yönetimi',
          description: 'Kişiselleştirilmiş içerik',
          icon: Icons.person_pin_rounded,
          webPath: '/admin/bana-ozel',
        ),
        const AdminNavItem(
          label: 'Online Fal Sayfası',
          description: 'Online fal ayarları',
          icon: Icons.blur_on_rounded,
          webPath: '/admin/online-fal',
        ),
        const AdminNavItem(
          label: 'Trend Videolar',
          description: 'YouTube trend videolarını yönet',
          icon: Icons.smart_display_rounded,
          webPath: '/admin/trend-videos',
        ),
        const AdminNavItem(
          label: 'TikTok Videoları',
          description: 'TikTok videolarını yönet',
          icon: Icons.music_video_rounded,
          webPath: '/admin/tiktok-videos',
        ),
        const AdminNavItem(
          label: 'Trend Yönetimi',
          description: 'Platform trendlerini yönet',
          icon: Icons.local_fire_department_rounded,
          webPath: '/admin/trendler',
        ),
        const AdminNavItem(
          label: 'Oyun Merkezi',
          description: 'Oyunları düzenle',
          icon: Icons.sports_esports_rounded,
          webPath: '/admin/games',
        ),
        const AdminNavItem(
          label: 'Rüya Yarışmaları',
          description: 'Rüya yorumu yarışmaları',
          icon: Icons.emoji_events_rounded,
          webPath: '/admin/contests',
        ),
        AdminNavItem(
          label: 'CFC ARENA',
          description: 'Yarışma & etkinlik sistemi',
          icon: Icons.stadium_rounded,
          route: '/admin/cfc-arena',
          webPath: '/admin/cfc-arena',
          nativeVisible: site || a.isFounder || pay,
        ),
        AdminNavItem(
          label: 'Sosyal Medya Hesapları',
          description: 'Sitedeki sosyal medya bağlantıları',
          icon: Icons.share_rounded,
          route: '/admin/social-accounts',
          nativeVisible: site,
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Keşif & Analitik',
      emoji: '🔍',
      items: [
        const AdminNavItem(
          label: 'Global Arama',
          description: 'Kullanıcı, ajans, falcı ara',
          icon: Icons.travel_explore_rounded,
          webPath: '/admin/global-search',
        ),
        AdminNavItem(
          label: 'Platform Analitik',
          description: 'DAU/WAU/MAU, KPI dashboard',
          icon: Icons.analytics_rounded,
          route: '/admin/advanced-reporting',
          webPath: '/admin/platform-analytics',
          nativeVisible: site,
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Ajans & Falcı',
      emoji: '🏢',
      items: [
        const AdminNavItem(
          label: 'Ajans Listesi',
          description: 'Ajansları yönet, başvuruları onayla',
          icon: Icons.business_rounded,
          webPath: '/admin/ajanslar',
        ),
        const AdminNavItem(
          label: 'Ajans Finans Merkezi',
          description: 'Cüzdan, bonus ve komisyon kuralları',
          icon: Icons.work_rounded,
          webPath: '/admin/ajans-finans',
        ),
        AdminNavItem(
          label: 'Ajans Vaat & Raporları',
          description: 'Vaat onayı, şüpheli işlemler, raporlar',
          icon: Icons.fact_check_rounded,
          route: '/admin/ajans-yonetimi',
          webPath: '/admin/ajans-yonetimi',
          nativeVisible: site,
        ),
        const AdminNavItem(
          label: 'Canlı Falcı Yönetimi',
          description: 'Falcı onay & düzenleme',
          icon: Icons.psychology_rounded,
          webPath: '/admin/live-tellers',
        ),
        const AdminNavItem(
          label: 'Falcı Performansı',
          description: 'Falcı kazanç & seans tablosu',
          icon: Icons.trending_up_rounded,
          webPath: '/admin/falci-performans',
        ),
        const AdminNavItem(
          label: 'Doğrulama Talepleri',
          description: 'Kimlik & yayıncı doğrulama',
          icon: Icons.verified_user_rounded,
          webPath: '/admin/verification',
        ),
        const AdminNavItem(
          label: 'Kimlik Doğrulama',
          description: 'Falcı kimlik belgesi doğrulama',
          icon: Icons.badge_rounded,
          webPath: '/admin/kimlik-dogrulama',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Finans & Jeton',
      emoji: '💰',
      items: [
        AdminNavItem(
          label: 'Ödeme Talepleri (Jeton & CFC)',
          description: 'Havale / EFT bildirimlerini onayla veya reddet',
          icon: Icons.payments_rounded,
          route: '/admin',
          nativeVisible: pay,
        ),
        AdminNavItem(
          label: 'Jeton Yükle / Çıkar',
          description: 'Kullanıcıya jeton ekle veya düş',
          icon: Icons.add_circle_rounded,
          action: AdminNavAction.creditJeton,
          nativeVisible: pay,
        ),
        AdminNavItem(
          label: 'CFC Yükle / Çıkar',
          description: 'Kullanıcıya CFC ekle veya düş',
          icon: Icons.toll_rounded,
          action: AdminNavAction.creditCfc,
          nativeVisible: pay,
        ),
        const AdminNavItem(
          label: 'Jeton Yönetimi',
          description: 'Fiyat, paket, indirim ayarları',
          icon: Icons.price_change_rounded,
          webPath: '/admin/jeton-yonetimi',
        ),
        AdminNavItem(
          label: 'Finans Yönetimi',
          description: 'Gelir-gider takibi, komisyon ayarları',
          icon: Icons.account_balance_wallet_rounded,
          route: '/admin/finance-summary',
          webPath: '/admin/finance',
          preferWeb: true,
          nativeVisible: pay,
        ),
        const AdminNavItem(
          label: 'CFC Paketleri',
          description: 'Satış paketlerini düzenle',
          icon: Icons.inventory_2_rounded,
          webPath: '/admin/credit-packages',
        ),
        const AdminNavItem(
          label: 'Jeton / CFC Kur Ayarları',
          description: 'Kur ve birim ayarları',
          icon: Icons.balance_rounded,
          webPath: '/admin/currency-config',
        ),
        const AdminNavItem(
          label: 'Ödeme Yöntemleri',
          description: 'Ödeme seçenekleri',
          icon: Icons.credit_card_rounded,
          webPath: '/admin/payment-methods',
        ),
        const AdminNavItem(
          label: 'Çekim & Ödüller',
          description: 'Para çekim talepleri',
          icon: Icons.atm_rounded,
          webPath: '/admin/withdrawals',
        ),
        const AdminNavItem(
          label: 'Denetim & Defter',
          description: 'Denetim kaydı & finansal defter',
          icon: Icons.receipt_long_rounded,
          webPath: '/admin/audit',
        ),
        const AdminNavItem(
          label: 'Risk & Dolandırıcılık',
          description: 'Finansal işlemlerde risk sinyalleri',
          icon: Icons.warning_amber_rounded,
          webPath: '/admin/risk',
        ),
        const AdminNavItem(
          label: 'Reklam Ağı Yönetimi',
          description: 'Reklam entegrasyonları',
          icon: Icons.tv_rounded,
          webPath: '/admin/ad-networks',
        ),
        const AdminNavItem(
          label: 'Reklam Yerleşimleri',
          description: 'Reklamların nerede gösterileceği',
          icon: Icons.campaign_rounded,
          webPath: '/admin/ad-placements',
        ),
        const AdminNavItem(
          label: 'Referans & Ajans Komisyonu',
          description: 'Yükleme başına davet/ajans komisyonu',
          icon: Icons.handshake_rounded,
          webPath: '/admin/referral-commission',
        ),
        const AdminNavItem(
          label: 'Para Birimi & Bonus',
          description: 'Jeton/CFC isim-ikon ve yükleme bonus kademeleri',
          icon: Icons.savings_rounded,
          webPath: '/admin/currency-settings',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Hediye & Ödül',
      emoji: '🎁',
      items: [
        AdminNavItem(
          label: 'Hediye Kataloğu',
          description: 'Hediye ekle, düzenle, sil, medya yükle',
          icon: Icons.card_giftcard_rounded,
          route: '/admin/gifts',
          nativeVisible: a.canManageGifts,
        ),
        const AdminNavItem(
          label: 'Şanslı Hediye',
          description: 'Ödül kademeleri, jackpot ve olasılıklar',
          icon: Icons.casino_rounded,
          webPath: '/admin/lucky-gifts',
        ),
        const AdminNavItem(
          label: 'Efekt Kuralları',
          description: 'Seviye/harcamaya göre efekt atama',
          icon: Icons.rule_rounded,
          webPath: '/admin/effect-rules',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Animasyon & Görünüm',
      emoji: '🎨',
      items: [
        AdminNavItem(
          label: 'Site Animasyonları',
          description: 'Merkezi animasyon kütüphanesi & atamalar',
          icon: Icons.animation_rounded,
          route: '/admin/site-animations',
          nativeVisible: a.canManageSiteAnimations || site,
        ),
        const AdminNavItem(
          label: 'İsim Efektleri',
          description: 'Renkli/animasyonlu isim stilleri',
          icon: Icons.text_fields_rounded,
          webPath: '/admin/name-effects',
        ),
        const AdminNavItem(
          label: 'Giriş Efektleri',
          description: 'Odaya giriş animasyonları',
          icon: Icons.bolt_rounded,
          webPath: '/admin/entrance-effects',
        ),
        const AdminNavItem(
          label: 'Avatar Aksesuarları',
          description: 'Şapka, gözlük, taç vb.',
          icon: Icons.face_retouching_natural_rounded,
          webPath: '/admin/avatar-accessories',
        ),
        const AdminNavItem(
          label: 'Tema Yönetimi',
          description: 'Site renk & tema değiştir',
          icon: Icons.palette_rounded,
          webPath: '/admin/themes',
        ),
        const AdminNavItem(
          label: 'Anasayfa Kartları & Hero',
          description: 'Hero & kart görselleri',
          icon: Icons.view_carousel_rounded,
          webPath: '/admin/homepage-cards',
        ),
        const AdminNavItem(
          label: 'Ana Sayfa Butonları',
          description: 'Anasayfa buton düzeni',
          icon: Icons.smart_button_rounded,
          webPath: '/admin/homepage-buttons',
        ),
        const AdminNavItem(
          label: 'Buton Sıralaması',
          description: 'Buton sırasını düzenle',
          icon: Icons.format_list_numbered_rounded,
          webPath: '/admin/button-order',
        ),
        const AdminNavItem(
          label: 'Kayan Yazı Yönetimi',
          description: 'Kayan duyuru bantları',
          icon: Icons.text_rotation_none_rounded,
          webPath: '/admin/ticker-messages',
        ),
        const AdminNavItem(
          label: 'Popup Yönetimi',
          description: 'Açılır pencere ayarları',
          icon: Icons.open_in_new_rounded,
          webPath: '/admin/popups',
        ),
        const AdminNavItem(
          label: 'Giriş Duyurusu Ayarları',
          description: 'Duyuru şablonları & efektler',
          icon: Icons.campaign_outlined,
          webPath: '/admin/announcement-settings',
        ),
      ],
    ),
    AdminNavGroup(
      title: 'Sistem & Yönetim',
      emoji: '⚙️',
      items: [
        const AdminNavItem(
          label: 'Platform Ayarları',
          description: 'Genel platform yapılandırma',
          icon: Icons.settings_rounded,
          webPath: '/admin/settings',
        ),
        const AdminNavItem(
          label: 'Feature Flags & Config',
          description: 'Özellik bayrakları & uzak yapılandırma',
          icon: Icons.flag_rounded,
          webPath: '/admin/feature-config',
        ),
        const AdminNavItem(
          label: 'Rol & Yetki',
          description: 'Rollerin izinlerini yönetin',
          icon: Icons.admin_panel_settings_rounded,
          webPath: '/admin/roles',
        ),
        const AdminNavItem(
          label: 'Push Bildirim Yönetimi',
          description: 'Bildirim gönder & yönet',
          icon: Icons.notifications_active_rounded,
          webPath: '/admin/notifications',
        ),
        AdminNavItem(
          label: 'Canlı Aktivite Akışı',
          description: 'Gerçek zamanlı aktivite',
          icon: Icons.timeline_rounded,
          route: '/admin/reports',
          webPath: '/admin/activity-feed',
          nativeVisible: a.canViewReports || pay,
        ),
        AdminNavItem(
          label: 'Sistem Durumu',
          description: 'Canlı üretim izleme metrikleri',
          icon: Icons.monitor_heart_rounded,
          route: '/admin/system-health',
          webPath: '/admin/system-monitor',
          preferWeb: true,
          nativeVisible: site || a.isFounder,
        ),
        AdminNavItem(
          label: 'GirLive Bot Yönetimi',
          description: 'Moderasyon, karşılama, PK ve sohbet bot ayarları',
          icon: Icons.smart_toy_rounded,
          route: '/admin/girlive-bot',
          webPath: '/admin/girlive-bot',
          nativeVisible: site || a.isFounder,
        ),
        const AdminNavItem(
          label: 'AI Bot Yönetimi',
          description: 'Bot simülasyonu & kontrol',
          icon: Icons.precision_manufacturing_rounded,
          webPath: '/admin/bots',
        ),
        const AdminNavItem(
          label: 'Site Yedekleme',
          description: 'Veri yedekleme işlemleri',
          icon: Icons.backup_rounded,
          webPath: '/admin/backup',
        ),
        const AdminNavItem(
          label: 'Entegrasyonlar / Secret & API',
          description: 'SMS/OTP, Apple IAP, Google Play anahtarları',
          icon: Icons.key_rounded,
          webPath: '/admin/integrations',
        ),
      ],
    ),
  ];
}
