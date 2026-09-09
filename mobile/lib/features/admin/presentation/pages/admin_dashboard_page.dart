import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_providers.dart';
import '../providers/staff_access_provider.dart';
import '../widgets/admin_live_viewer_picker_sheet.dart';
import '../widgets/admin_staff_moderation_checklist.dart';

/// Tam admin dashboard — normal profilden görsel olarak ayrılmış.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(adminDashboardStatsProvider);
    ref.invalidate(adminPanelBadgeCountsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(staffAccessProvider);
    if (!access.hasFullAdminDashboard && !access.canManagePayments) {
      return _locked(context);
    }

    final statsAsync = ref.watch(adminDashboardStatsProvider);
    final stats = statsAsync.valueOrNull ?? const AdminDashboardStats();
    final pending = ref.watch(adminPendingPaymentsCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF06030C),
      body: DiscoverBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 4),
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.admin_panel_settings_rounded,
                              color: AppThemeColors.liveRed,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Admin Kontrol Merkezi',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          access.roleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DiscoverIconButton(
                    icon: Icons.refresh_rounded,
                    onPressed: () => _refresh(ref),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppThemeColors.accentPink,
                onRefresh: () async => _refresh(ref),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    if (statsAsync.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'İstatistikler kısmen yüklenemedi — menü kullanılabilir.',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.onSurfaceMuted,
                          ),
                        ),
                      ),
                    _SectionLabel('Dashboard'),
                    const AdminActivityTicker(),
                    const SizedBox(height: 12),
                    const AdminStaffModerationChecklist(),
                    const SizedBox(height: 16),
                    if (statsAsync.isLoading && !statsAsync.hasValue)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppThemeColors.accentPink,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    else
                    _StatsGrid(
                      children: [
                        _StatTile(
                          label: 'Toplam kullanıcı',
                          value: stats.totalUsers,
                          icon: Icons.people_rounded,
                        ),
                        _StatTile(
                          label: 'Aktif kullanıcı',
                          value: stats.activeUsers,
                          icon: Icons.person_pin_rounded,
                        ),
                        _StatTile(
                          label: 'Online',
                          value: stats.onlineUsers,
                          icon: Icons.wifi_tethering_rounded,
                        ),
                        _StatTile(
                          label: 'Toplam jeton',
                          value: stats.totalJeton,
                          icon: Icons.monetization_on_rounded,
                        ),
                        _StatTile(
                          label: 'Toplam CFC',
                          value: stats.totalCfc,
                          icon: Icons.diamond_rounded,
                        ),
                        _StatTile(
                          label: 'Aktif sesli oda',
                          value: stats.activeVoiceRooms,
                          icon: Icons.meeting_room_rounded,
                        ),
                        _StatTile(
                          label: 'Aktif yayın',
                          value: stats.activeLiveStreams,
                          icon: Icons.live_tv_rounded,
                        ),
                        _StatTile(
                          label: 'Bekleyen işlem',
                          value: pending + stats.pendingWithdrawals,
                          icon: Icons.pending_actions_rounded,
                          highlight: pending > 0,
                        ),
                        _StatTile(
                          label: 'Okunmamış bildirim',
                          value: stats.unreadNotifications,
                          icon: Icons.notifications_rounded,
                          highlight: stats.unreadNotifications > 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel('Jeton & CFC Yönetimi'),
                    _ActionGrid(items: [
                      _AdminAction(
                        icon: Icons.payments_rounded,
                        label: 'Ödeme talepleri',
                        badge: pending,
                        onTap: () => context.push('/admin'),
                      ),
                      _AdminAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'Jeton yükle',
                        onTap: () => context.push('/admin/panel'),
                      ),
                      _AdminAction(
                        icon: Icons.toll_outlined,
                        label: 'CFC yükle',
                        onTap: () => context.push('/admin/panel'),
                      ),
                      _AdminAction(
                        icon: Icons.history_rounded,
                        label: 'İşlem geçmişi',
                        onTap: () => context.push('/admin/reports'),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _SectionLabel('Bildirim Yönetimi'),
                    _ActionGrid(items: [
                      _AdminAction(
                        icon: Icons.notifications_active_rounded,
                        label: 'Ödeme bildirimleri',
                        onTap: () => context.push('/admin'),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _SectionLabel('Sesli Oda & Yayın'),
                    _ActionGrid(items: [
                      if (access.canManageVoiceRooms)
                        _AdminAction(
                          icon: Icons.meeting_room_rounded,
                          label: 'Sesli odalar',
                          onTap: () => context.push('/admin/voice-rooms'),
                        ),
                      if (access.canManagePayments || access.canManageVoiceRooms)
                        _AdminAction(
                          icon: Icons.receipt_long_rounded,
                          label: 'Oda finans denetimi',
                          onTap: () => context.push('/admin/voice-finance'),
                        ),
                      if (access.canManageLiveStreams)
                        _AdminAction(
                          icon: Icons.live_tv_rounded,
                          label: 'Canlı yayınlar',
                          onTap: () => context.push('/admin/live-streams'),
                        ),
                      _AdminAction(
                        icon: Icons.gavel_rounded,
                        label: 'Moderasyon',
                        onTap: () => context.push('/admin/moderation'),
                      ),
                    ]),
                    const SizedBox(height: 22),
                    _SectionLabel('Kullanıcı & Sistem'),
                    _ActionGrid(items: [
                      if (access.canManageUsers)
                        _AdminAction(
                          icon: Icons.people_alt_rounded,
                          label: 'Kullanıcılar',
                          onTap: () => context.push('/admin/users'),
                        ),
                      if (access.canViewReports)
                        _AdminAction(
                          icon: Icons.analytics_rounded,
                          label: 'Raporlar',
                          onTap: () => context.push('/admin/reports'),
                        ),
                      _AdminAction(
                        icon: Icons.dashboard_customize_rounded,
                        label: 'Klasik panel',
                        onTap: () => context.push('/admin/panel'),
                      ),
                      if (access.canManageGifts)
                        _AdminAction(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Hediyeler',
                          onTap: () => context.push('/admin/gifts'),
                        ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locked(BuildContext context) {
    return Scaffold(
      body: DiscoverBackground(
        child: Center(
          child: DiscoverEmptyState(
            icon: Icons.lock_outline_rounded,
            message: 'Bu alan yalnızca yetkili admin hesapları içindir.',
            actionLabel: 'Geri',
            action: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppThemeColors.liveRed,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 500 ? 4 : 2;
        final spacing = 10.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < children.length; i++)
              SizedBox(
                width: w,
                child: children[i]
                    .animate(delay: (i * 40).ms)
                    .fadeIn(duration: 240.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return DiscoverGlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: highlight ? AppThemeColors.liveRed : AppThemeColors.accentCyan,
          ),
          const SizedBox(height: 8),
          Text(
            value > 0 ? _format(value) : '—',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _format(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _AdminAction {
  const _AdminAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items});
  final List<_AdminAction> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 10.0;
        const cols = 2;
        final w = (c.maxWidth - spacing) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: w,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: item.onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Icon(item.icon, color: AppThemeColors.accentPink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (item.badge > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppThemeColors.liveRed,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${item.badge}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
