import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/staff_access_provider.dart';

class AdminCatalogItem {
  const AdminCatalogItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    this.visible = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool visible;
}

class AdminCatalogSection {
  const AdminCatalogSection({required this.title, required this.items});

  final String title;
  final List<AdminCatalogItem> items;
}

List<AdminCatalogSection> adminFeaturesCatalog(StaffAccess access) {
  return [
    AdminCatalogSection(
      title: 'Finans & ödemeler',
      items: [
        AdminCatalogItem(
          title: 'Ödeme talepleri',
          subtitle: 'Jeton / Gold onay kuyruğu',
          icon: Icons.payments_rounded,
          route: '/admin',
          visible: access.canManagePayments,
        ),
        AdminCatalogItem(
          title: 'Admin paneli',
          subtitle: 'Jeton yükleme & ayarlar',
          icon: Icons.admin_panel_settings_rounded,
          route: '/admin/panel',
          visible: access.canManagePayments || access.showAdminPanel,
        ),
        AdminCatalogItem(
          title: 'Sesli oda finansı',
          subtitle: 'Oda gelir özeti',
          icon: Icons.account_balance_rounded,
          route: '/admin/voice-finance',
          visible: access.canManagePayments || access.canManageVoiceRooms,
        ),
      ],
    ),
    AdminCatalogSection(
      title: 'Kullanıcı & üyelik',
      items: [
        AdminCatalogItem(
          title: 'Kullanıcı komuta merkezi',
          subtitle: 'Arama, düzenleme, jeton',
          icon: Icons.manage_accounts_rounded,
          route: '/admin/users',
          visible: access.canManageUsers || access.canManagePayments,
        ),
        AdminCatalogItem(
          title: 'Üyelik yönetimi',
          subtitle: 'Premium planlar',
          icon: Icons.card_membership_rounded,
          route: '/admin/membership-management',
          visible: access.canManagePayments || access.isSiteAdmin,
        ),
        AdminCatalogItem(
          title: 'Kullanıcı oturumları',
          subtitle: 'Aktif cihazlar',
          icon: Icons.devices_rounded,
          route: '/admin/user-sessions',
          visible: access.canViewActivityLog || access.isSiteAdmin,
        ),
      ],
    ),
    AdminCatalogSection(
      title: 'Moderasyon & güvenlik',
      items: [
        AdminCatalogItem(
          title: 'Moderasyon kuyruğu',
          subtitle: 'Raporlanan içerik',
          icon: Icons.flag_rounded,
          route: '/admin/moderation',
          visible: access.canModerate,
        ),
        AdminCatalogItem(
          title: 'Aktivite izleme',
          subtitle: 'Anomali uyarıları',
          icon: Icons.warning_amber_rounded,
          route: '/admin/activity-monitoring',
          visible: access.canModerate || access.canViewActivityLog,
        ),
        AdminCatalogItem(
          title: 'Aktivite günlüğü',
          subtitle: 'Staff eylemleri',
          icon: Icons.history_rounded,
          route: '/admin/activity-log',
          visible: access.canViewActivityLog,
        ),
        AdminCatalogItem(
          title: 'Dolandırıcılık tespiti',
          subtitle: 'Fraud skorları',
          icon: Icons.security_rounded,
          route: '/admin/fraud-detection',
          visible: access.canModerate || access.canManagePayments,
        ),
        AdminCatalogItem(
          title: 'Toplu işlemler',
          subtitle: 'Bulk ops',
          icon: Icons.dynamic_feed_rounded,
          route: '/admin/bulk-operations',
          visible: access.canModerate || access.isSiteAdmin,
        ),
        AdminCatalogItem(
          title: 'Raporlar',
          subtitle: 'Kullanıcı şikayetleri',
          icon: Icons.report_rounded,
          route: '/admin/reports',
          visible: access.canViewReports || access.canModerate,
        ),
        AdminCatalogItem(
          title: 'Güvenlik panosu',
          subtitle: 'Politika & tehdit',
          icon: Icons.shield_rounded,
          route: '/admin/security',
          visible: access.isSiteAdmin || access.canViewActivityLog,
        ),
        AdminCatalogItem(
          title: 'Denetim günlüğü',
          subtitle: 'Audit trail',
          icon: Icons.assignment_rounded,
          route: '/admin/audit-logs',
          visible: access.canViewActivityLog || access.isSiteAdmin,
        ),
      ],
    ),
    AdminCatalogSection(
      title: 'Yayın & sesli odalar',
      items: [
        AdminCatalogItem(
          title: 'Canlı yayınlar',
          subtitle: 'Stream moderasyon',
          icon: Icons.live_tv_rounded,
          route: '/admin/live-streams',
          visible: access.canManageLiveStreams,
        ),
        AdminCatalogItem(
          title: 'Yayın kontrol merkezi',
          subtitle: 'Aktif broadcast',
          icon: Icons.sensors_rounded,
          route: '/admin/live-broadcasts-control',
          visible: access.canManageLiveStreams || access.canManagePayments,
        ),
        AdminCatalogItem(
          title: 'Sesli odalar',
          subtitle: 'Oda listesi & ayar',
          icon: Icons.record_voice_over_rounded,
          route: '/admin/voice-rooms',
          visible: access.canManageVoiceRooms,
        ),
        AdminCatalogItem(
          title: 'Ses arka planları',
          subtitle: 'Voice room BG',
          icon: Icons.wallpaper_rounded,
          route: '/admin/voice-backgrounds',
          visible: access.canManageVoiceRooms || access.canManageGifts,
        ),
      ],
    ),
    AdminCatalogSection(
      title: 'Hediye & görsel efektler',
      items: [
        AdminCatalogItem(
          title: 'Hediye yönetimi',
          subtitle: 'Katalog CRUD',
          icon: Icons.card_giftcard_rounded,
          route: '/admin/gifts',
          visible: access.canManageGifts,
        ),
        AdminCatalogItem(
          title: 'Koleksiyon hub',
          subtitle: 'Gift collections',
          icon: Icons.collections_rounded,
          route: '/admin/collections',
          visible: access.canManageGifts,
        ),
        AdminCatalogItem(
          title: 'Giriş efektleri',
          subtitle: 'Entrance FX',
          icon: Icons.door_front_door_rounded,
          route: '/admin/entrance-effects',
          visible: access.canManageGifts || access.canManageSiteAnimations,
        ),
        AdminCatalogItem(
          title: 'Visual FX',
          subtitle: 'Sahne efektleri',
          icon: Icons.auto_fix_high_rounded,
          route: '/admin/visual-fx',
          visible: access.canManageSiteAnimations,
        ),
        AdminCatalogItem(
          title: 'Site animasyonları',
          subtitle: 'Animasyon kütüphanesi',
          icon: Icons.animation_rounded,
          route: '/admin/site-animations',
          visible: access.canManageSiteAnimations,
        ),
      ],
    ),
    AdminCatalogSection(
      title: 'Sistem & kurucu',
      items: [
        AdminCatalogItem(
          title: 'Dashboard',
          subtitle: 'Özet metrikler',
          icon: Icons.dashboard_rounded,
          route: '/admin/dashboard',
          visible: access.showAdminPanel,
        ),
        AdminCatalogItem(
          title: 'Admin ana sekme',
          subtitle: 'Bildirimler & kısayollar',
          icon: Icons.home_rounded,
          route: '/admin/home',
          visible: access.canAccessAdminHome,
        ),
        AdminCatalogItem(
          title: 'Sistem sağlığı',
          subtitle: 'Health check',
          icon: Icons.monitor_heart_rounded,
          route: '/admin/system-health',
          visible: access.isSiteAdmin || access.isFounder,
        ),
        AdminCatalogItem(
          title: 'Takım yönetimi',
          subtitle: 'Staff rolleri',
          icon: Icons.groups_rounded,
          route: '/admin/team-management',
          visible: access.isFounder,
        ),
        AdminCatalogItem(
          title: 'Sistem yapılandırma',
          subtitle: 'API anahtarları',
          icon: Icons.settings_applications_rounded,
          route: '/admin/system-config',
          visible: access.isFounder || access.canManageGifts,
        ),
        AdminCatalogItem(
          title: 'Gelişmiş raporlama',
          subtitle: 'Analytics export',
          icon: Icons.assessment_rounded,
          route: '/admin/advanced-reporting',
          visible: access.isFounder || access.canViewReports,
        ),
        AdminCatalogItem(
          title: 'Tercihler',
          subtitle: 'Panel ayarları',
          icon: Icons.tune_rounded,
          route: '/admin/preferences',
          visible: access.showAdminPanel || access.isStaffMember,
        ),
        AdminCatalogItem(
          title: 'Bildirim yöneticisi',
          subtitle: 'Push / şablon',
          icon: Icons.notifications_active_rounded,
          route: '/admin/notification-manager',
          visible: access.canManageNotifications || access.canManagePayments,
        ),
        AdminCatalogItem(
          title: 'Özellik bayrakları',
          subtitle: 'Feature flags',
          icon: Icons.toggle_on_rounded,
          route: '/admin/feature-flags',
          visible: access.isSiteAdmin || access.isFounder,
        ),
        AdminCatalogItem(
          title: 'E-posta şablonları',
          subtitle: 'Transactional mail',
          icon: Icons.mail_rounded,
          route: '/admin/email-templates',
          visible: access.isSiteAdmin || access.isFounder,
        ),
        AdminCatalogItem(
          title: 'Web admin (embedded)',
          subtitle: 'canlifal.com panel',
          icon: Icons.language_rounded,
          route: '/admin/web',
          visible: access.showAdminPanel,
        ),
      ],
    ),
  ];
}

/// Tüm admin ekranları — yetkiye göre filtrelenmiş katalog.
class AdminFeaturesCatalogPage extends ConsumerStatefulWidget {
  const AdminFeaturesCatalogPage({super.key});

  @override
  ConsumerState<AdminFeaturesCatalogPage> createState() =>
      _AdminFeaturesCatalogPageState();
}

class _AdminFeaturesCatalogPageState
    extends ConsumerState<AdminFeaturesCatalogPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canAccessAdminHome) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin araçları')),
        body: const Center(child: Text('Bu alan için yetkiniz yok.')),
      );
    }

    final sections = adminFeaturesCatalog(access);
    final total = sections.fold<int>(
      0,
      (n, s) => n + s.items.where((i) => i.visible).length,
    );

    final q = _query.trim().toLowerCase();
    final filtered = sections
        .map((section) {
          final items = section.items.where((i) {
            if (!i.visible) return false;
            if (q.isEmpty) return true;
            return i.title.toLowerCase().contains(q) ||
                i.subtitle.toLowerCase().contains(q);
          }).toList();
          if (items.isEmpty) return null;
          return AdminCatalogSection(title: section.title, items: items);
        })
        .whereType<AdminCatalogSection>()
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Tüm Admin Araçları'),
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            AppThemeColors.accentPurple.withValues(alpha: 0.2),
                            AppThemeColors.accentPink.withValues(alpha: 0.15),
                          ],
                        ),
                        border: Border.all(
                          color: AppThemeColors.accentCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$total modül — Claude ile genişletilen admin paneli. '
                        'Rolünüze göre görünen satırlar listelenir.',
                        style: TextStyle(
                          color: context.colors.onSurface,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Admin aracı ara…',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: context.colors.surfaceContainer,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = filtered[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: context.colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...section.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _AdminTile(
                                item: item,
                                onTap: () => context.push(item.route),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({required this.item, required this.onTap});

  final AdminCatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppThemeColors.accentPink.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: AppThemeColors.accentPink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
