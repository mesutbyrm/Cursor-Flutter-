import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../providers/staff_access_provider.dart';

/// Yönetim Merkezi kartı tanımı. Görünürlük [StaffAccess] yetkilerinden gelir;
/// rota mevcut admin ekranlarına gider (yeni uç eklenmez).
class AdminCenterEntry {
  const AdminCenterEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.route,
    required this.visible,
    this.danger = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String route;
  final bool visible;
  final bool danger;
}

/// Yetkiye göre görünen Yönetim Merkezi kartları.
List<AdminCenterEntry> adminCenterEntries(StaffAccess a) {
  return [
    AdminCenterEntry(
      title: 'Kullanıcı Yönetimi',
      subtitle: 'Kullanıcılar, roller, ban',
      icon: Icons.groups_rounded,
      accent: const Color(0xFF3B82F6),
      route: '/admin/users',
      visible: a.canManageUsers,
    ),
    AdminCenterEntry(
      title: 'Canlı Yayın Yönetimi',
      subtitle: 'Aktif yayınlar, kontrol',
      icon: Icons.live_tv_rounded,
      accent: const Color(0xFFFF3D71),
      route: '/admin/live-streams',
      visible: a.canManageLiveStreams,
    ),
    AdminCenterEntry(
      title: 'Sesli Oda Yönetimi',
      subtitle: 'Aktif odalar, raporlar',
      icon: Icons.graphic_eq_rounded,
      accent: const Color(0xFF8E6BFF),
      route: '/admin/voice-rooms',
      visible: a.canManageVoiceRooms,
    ),
    AdminCenterEntry(
      title: 'PK Yönetimi',
      subtitle: 'PK savaşları, raporlar',
      icon: Icons.sports_mma_rounded,
      accent: const Color(0xFFFF7A45),
      route: '/admin/moderation',
      visible: a.canModerate,
    ),
    AdminCenterEntry(
      title: 'Hediye / Jeton',
      subtitle: 'Hediye, jeton, işlemler',
      icon: Icons.card_giftcard_rounded,
      accent: const Color(0xFFFFB020),
      route: '/admin/gifts',
      visible: a.canManageGifts,
    ),
    AdminCenterEntry(
      title: 'Şikayetler',
      subtitle: 'Kullanıcı ve içerik',
      icon: Icons.report_gmailerrorred_rounded,
      accent: const Color(0xFFFF5A5F),
      route: '/admin/reports',
      visible: a.canViewReports,
    ),
    AdminCenterEntry(
      title: 'Bildirim Gönder',
      subtitle: 'Kullanıcıya duyuru',
      icon: Icons.campaign_rounded,
      accent: const Color(0xFF19C37D),
      route: '/admin/notification-manager',
      visible: a.canManageNotifications,
    ),
    AdminCenterEntry(
      title: 'İstatistikler',
      subtitle: 'Detaylı analizler',
      icon: Icons.insights_rounded,
      accent: const Color(0xFF7C5CFF),
      route: '/admin/dashboard',
      visible: a.canViewReports || a.showAdminPanel,
    ),
    AdminCenterEntry(
      title: 'Ajans Yönetimi',
      subtitle: 'Vaat onayı, şüpheli işlem, performans',
      icon: Icons.apartment_rounded,
      accent: const Color(0xFF10B981),
      route: '/admin/ajans-yonetimi',
      visible: a.isSiteAdmin,
    ),
    AdminCenterEntry(
      title: 'Sosyal Medya',
      subtitle: 'Resmi hesaplar ve bağlantılar',
      icon: Icons.share_rounded,
      accent: const Color(0xFFEC4899),
      route: '/admin/social-accounts',
      visible: a.isSiteAdmin,
    ),
    AdminCenterEntry(
      title: 'Sistem Ayarları',
      subtitle: 'Genel ayarlar',
      icon: Icons.settings_suggest_rounded,
      accent: const Color(0xFF94A3B8),
      route: '/admin/system-config',
      visible: a.isSiteAdmin,
    ),
    AdminCenterEntry(
      title: 'Acil Durum',
      subtitle: 'Sistemi bakım moduna al',
      icon: Icons.warning_amber_rounded,
      accent: const Color(0xFFFF3B30),
      route: '/admin/system-config',
      visible: a.isSiteAdmin,
      danger: true,
    ),
  ];
}

/// Yönetim Merkezi — yalnızca yetkili staff görür; normal kullanıcıya
/// "yetkiniz yok" ekranı gösterilir (sunucu uçları ayrıca 401/403 döner).
class AdminManagementCenterPage extends ConsumerWidget {
  const AdminManagementCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    final c = context.colors;

    Widget body;
    if (!access.canAccessAdminHome) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: c.onSurfaceMuted),
              const SizedBox(height: 12),
              Text(
                'Bu alan için yetkiniz yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceVariant, fontSize: 15),
              ),
            ],
          ),
        ),
      );
    } else {
      final entries = adminCenterEntries(access).where((e) => e.visible).toList();
      body = LayoutBuilder(
        builder: (context, box) {
          final cols = box.maxWidth >= 900 ? 3 : 2;
          const gap = 10.0;
          final w = (box.maxWidth - 32 - gap * (cols - 1)) / cols;
          return SingleChildScrollView(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 40),
            child: Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final e in entries)
                  SizedBox(
                    width: w,
                    child: _CenterCard(
                      entry: e,
                      onTap: () => context.push(e.route),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }

    return MockScaffold(
      title: 'Yönetim Merkezi',
      startAligned: true,
      actions: [
        if (access.canManageLiveStreams || access.canViewReports)
          IconButton(
            tooltip: 'Yayın İstatistikleri',
            icon: const Icon(Icons.bar_chart_rounded),
            color: const Color(0xFF8B8CFF),
            onPressed: () => context.push('/admin/live-stats'),
          ),
      ],
      body: body,
    );
  }
}

class _CenterCard extends StatefulWidget {
  const _CenterCard({required this.entry, required this.onTap});

  final AdminCenterEntry entry;
  final VoidCallback onTap;

  @override
  State<_CenterCard> createState() => _CenterCardState();
}

class _CenterCardState extends State<_CenterCard> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final e = widget.entry;
    final radius = BorderRadius.circular(16);
    const danger = Color(0xFFFF3B30);
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _down = v),
          splashColor: e.accent.withValues(alpha: 0.14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: e.danger
                  ? Color.alphaBlend(
                      danger.withValues(alpha: 0.16),
                      mockCardColor(context),
                    )
                  : mockCardColor(context),
              border: Border.all(
                color: e.danger
                    ? danger.withValues(alpha: 0.55)
                    : mockCardBorder(context),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 104),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MockIconSquare(icon: e.icon, color: e.accent, size: 38),
                    const SizedBox(height: 10),
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        height: 1.2,
                        color: c.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.25,
                        color: c.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
