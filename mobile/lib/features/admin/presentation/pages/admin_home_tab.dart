import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../data/services/admin_payments_sse_service.dart';
import '../providers/admin_providers.dart';
import '../providers/admin_panel_providers.dart';
import '../providers/admin_moderation_providers.dart';
import '../providers/admin_activity_monitoring_providers.dart';
import '../providers/admin_fraud_detection_providers.dart';
import '../providers/staff_access_provider.dart';
import '../providers/admin_live_broadcasts_providers.dart';
import '../providers/admin_system_health_providers.dart';
import '../providers/admin_team_management_providers.dart';
import '../providers/admin_system_config_providers.dart';
import '../providers/admin_advanced_reporting_providers.dart';

/// Admin giriş sekmesi — bildirimler + hızlı işlemler birleşti.
class AdminHomeTab extends ConsumerStatefulWidget {
  const AdminHomeTab({super.key});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  Timer? _poll;
  StreamSubscription<void>? _paymentsSseSub;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _refresh();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final access = ref.read(staffAccessProvider);
      if (access.canManagePayments) {
        unawaited(_connectSse());
      }
    });
  }

  Future<void> _connectSse() async {
    await connectAdminPaymentsSse(ref);
    _paymentsSseSub?.cancel();
    _paymentsSseSub = ref
        .read(adminPaymentsSseServiceProvider)
        .onPaymentEvent
        .listen((_) {
      if (!mounted) return;
      _refresh();
    });
  }

  void _refresh() {
    ref.invalidate(adminPaymentRequestsProvider);
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(adminPanelBadgeCountsProvider);
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(_paymentsSseSub?.cancel());
    unawaited(disconnectAdminPaymentsSse(ref));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(staffAccessProvider);
    if (!access.canAccessAdminHome) {
      return const SizedBox.shrink();
    }

    final showFinance = access.canManagePayments;
    final badges = showFinance
        ? ref.watch(adminPanelBadgeCountsProvider).valueOrNull
        : null;
    final pendingCount =
        showFinance ? ref.watch(adminPendingPaymentsCountProvider) : 0;
    final moderationCount = ref.watch(adminModerationQueueCountProvider);
    final activityMonitoringCount = ref.watch(adminActivityMonitoringCountProvider);
    final fraudAlertCount = ref.watch(adminFraudAlertCountProvider);
    final activeBroadcastCount = ref.watch(adminActiveBroadcastCountProvider);
    final systemHealthAsync = ref.watch(adminSystemHealthProvider);
    final teamMembersAsync = ref.watch(adminTeamMembersProvider);
    final reportCountAsync = ref.watch(adminReportCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: DiscoverBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Paneli',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Bildirimler & İşlemler',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
            _AllToolsBanner(onTap: () => context.push('/admin/tools')),
            const SizedBox(height: 20),
            // Bekleyen işlemler
            if (pendingCount > 0 || moderationCount > 0 || activityMonitoringCount > 0 || fraudAlertCount > 0) ...[
              _SectionTitle('🔴 Bekleyen İşlemler'),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _NotificationCard(
                      icon: Icons.payments_rounded,
                      label: 'Ödeme Talepleri',
                      count: badges?.pendingPayments ?? 0,
                      color: AppThemeColors.liveRed,
                      onTap: () => context.push('/admin'),
                    ),
                    const SizedBox(width: 12),
                    _NotificationCard(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Para Çekme',
                      count: badges?.pendingWithdrawals ?? 0,
                      color: AppThemeColors.accentCyan,
                      onTap: () => context.push('/admin'),
                    ),
                    if (moderationCount > 0) ...[
                      const SizedBox(width: 12),
                      _NotificationCard(
                        icon: Icons.flag_rounded,
                        label: 'Moderation',
                        count: moderationCount,
                        color: AppThemeColors.liveRed,
                        onTap: () => context.push('/admin/moderation'),
                      ),
                    ],
                    if (activityMonitoringCount > 0) ...[
                      const SizedBox(width: 12),
                      _NotificationCard(
                        icon: Icons.warning_rounded,
                        label: 'Activity Monitor',
                        count: activityMonitoringCount,
                        color: AppThemeColors.accentCyan,
                        onTap: () => context.push('/admin/activity-monitoring'),
                      ),
                    ],
                    if (fraudAlertCount > 0) ...[
                      const SizedBox(width: 12),
                      _NotificationCard(
                        icon: Icons.security_rounded,
                        label: 'Fraud Alerts',
                        count: fraudAlertCount,
                        color: AppThemeColors.liveRed,
                        onTap: () => context.push('/admin/fraud-detection'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Hızlı İstatistikler
            if (showFinance) ...[
              _SectionTitle('📊 Bugün'),
              _QuickStatsGrid(badges: badges),
              const SizedBox(height: 24),
            ],

            // Sistem & Yayınlar
            _SectionTitle('🎥 Sistem & Yayınlar'),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _NotificationCard(
                    icon: Icons.live_tv_rounded,
                    label: 'Aktif Yayınlar',
                    count: activeBroadcastCount,
                    color: AppThemeColors.accentPink,
                    onTap: () => context.push('/admin/live-broadcasts-control'),
                  ),
                  const SizedBox(width: 12),
                  systemHealthAsync.when(
                    data: (health) {
                      final status = calculateHealthStatus(health);
                      final statusColor = _getHealthColor(status);
                      return _NotificationCard(
                        icon: Icons.monitor_heart_rounded,
                        label: 'Sistem Sağlığı',
                        count: 0,
                        color: statusColor,
                        onTap: () => context.push('/admin/system-health'),
                      );
                    },
                    loading: () => _NotificationCard(
                      icon: Icons.monitor_heart_rounded,
                      label: 'Sistem Sağlığı',
                      count: 0,
                      color: AppThemeColors.accentCyan,
                      onTap: () => context.push('/admin/system-health'),
                    ),
                    error: (_, __) => _NotificationCard(
                      icon: Icons.monitor_heart_rounded,
                      label: 'Sistem Sağlığı',
                      count: 0,
                      color: AppThemeColors.accentCyan,
                      onTap: () => context.push('/admin/system-health'),
                    ),
                  ),
                  if (access.isFounder) ...[
                    const SizedBox(width: 12),
                    teamMembersAsync.when(
                      data: (members) => _NotificationCard(
                        icon: Icons.people_rounded,
                        label: 'Takım Üyeleri',
                        count: members.length,
                        color: AppThemeColors.accentCyan,
                        onTap: () => context.push('/admin/team-management'),
                      ),
                      loading: () => _NotificationCard(
                        icon: Icons.people_rounded,
                        label: 'Takım Üyeleri',
                        count: 0,
                        color: AppThemeColors.accentCyan,
                        onTap: () => context.push('/admin/team-management'),
                      ),
                      error: (_, __) => _NotificationCard(
                        icon: Icons.people_rounded,
                        label: 'Takım Üyeleri',
                        count: 0,
                        color: AppThemeColors.accentCyan,
                        onTap: () => context.push('/admin/team-management'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _NotificationCard(
                      icon: Icons.settings_rounded,
                      label: 'Sistem Yapı',
                      count: 0,
                      color: AppThemeColors.accentPink,
                      onTap: () => context.push('/admin/system-config'),
                    ),
                    const SizedBox(width: 12),
                    _NotificationCard(
                      icon: Icons.assessment_rounded,
                      label: 'Raporlama',
                      count: reportCountAsync,
                      color: AppThemeColors.accentCyan,
                      onTap: () => context.push('/admin/advanced-reporting'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Hızlı İşlemler
            _SectionTitle('⚙️ Hızlı İşlemler'),
            _QuickActionsGrid(access: access),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllToolsBanner extends StatelessWidget {
  const _AllToolsBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.accentPurple.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppThemeColors.accentCyan.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.apps_rounded,
                color: AppThemeColors.accentPink,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tüm admin araçları',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: context.colors.onSurface,
                      ),
                    ),
                    Text(
                      'Claude ile eklenen modüller — arama ile keşfet',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: context.colors.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: context.colors.onSurface,
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 20),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: context.colors.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsGrid extends StatelessWidget {
  const _QuickStatsGrid({required this.badges});

  final AdminPanelBadges? badges;

  @override
  Widget build(BuildContext context) {
    if (badges == null) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _StatCard(
          label: 'Yeni Üye',
          value: badges!.todayMembers,
          icon: Icons.person_add_alt_1_rounded,
        ),
        _StatCard(
          label: 'Jeton Alan',
          value: badges!.todayJetonBuyers,
          icon: Icons.monetization_on_outlined,
        ),
        _StatCard(
          label: 'Oda Açan',
          value: badges!.todayRoomOpeners,
          icon: Icons.meeting_room_outlined,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppThemeColors.accentCyan.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppThemeColors.accentCyan, size: 18),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted,
              height: 1.1,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.access});

  final StaffAccess access;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _ActionButton(
          icon: Icons.person_add_rounded,
          label: 'Jeton Yükle',
          onTap: () => context.push('/admin/panel'),
        ),
        _ActionButton(
          icon: Icons.manage_accounts_rounded,
          label: 'Kullanıcı Yönet',
          onTap: () => context.push('/admin/users'),
        ),
        _ActionButton(
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          onTap: () => context.push('/admin/dashboard'),
        ),
        _ActionButton(
          icon: Icons.flag_rounded,
          label: 'Moderation',
          onTap: () => context.push('/admin/moderation'),
        ),
        _ActionButton(
          icon: Icons.history_rounded,
          label: 'Activity Log',
          onTap: () => context.push('/admin/activity-log'),
        ),
        _ActionButton(
          icon: Icons.trending_up_rounded,
          label: 'Bulk Ops',
          onTap: () => context.push('/admin/bulk-operations'),
        ),
        if (access.canManageGifts) ...[
          _ActionButton(
            icon: Icons.card_giftcard_rounded,
            label: 'Hediye Yönet',
            onTap: () => context.push('/admin/gifts'),
          ),
          _ActionButton(
            icon: Icons.animation_rounded,
            label: 'Efektler',
            onTap: () => context.push('/admin/site-animations'),
          ),
          _ActionButton(
            icon: Icons.vpn_key_rounded,
            label: 'API Keys',
            onTap: () => context.push('/admin/system-config'),
          ),
        ] else ...[
          _ActionButton(
            icon: Icons.settings_rounded,
            label: 'Ayarlar',
            onTap: () => context.push('/admin/panel'),
          ),
          _ActionButton(
            icon: Icons.people_rounded,
            label: 'Üyelik Yönet',
            onTap: () => context.push('/admin/membership-management'),
          ),
          _ActionButton(
            icon: Icons.phone_in_talk_rounded,
            label: 'Sesli Odalar',
            onTap: () => context.push('/admin/voice-rooms'),
          ),
        ],
        _ActionButton(
          icon: Icons.tune_rounded,
          label: 'Tercihler',
          onTap: () => context.push('/admin/preferences'),
        ),
        _ActionButton(
          icon: Icons.notifications_active_rounded,
          label: 'Bildirimler',
          onTap: () => context.push('/admin/notification-manager'),
        ),
        _ActionButton(
          icon: Icons.assignment_rounded,
          label: 'Denetim Günlüğü',
          onTap: () => context.push('/admin/audit-logs'),
        ),
        _ActionButton(
          icon: Icons.devices_rounded,
          label: 'Oturumlar',
          onTap: () => context.push('/admin/user-sessions'),
        ),
        _ActionButton(
          icon: Icons.security_rounded,
          label: 'Güvenlik',
          onTap: () => context.push('/admin/security'),
        ),
        _ActionButton(
          icon: Icons.toggle_on_rounded,
          label: 'Özellik Bayrakları',
          onTap: () => context.push('/admin/feature-flags'),
        ),
        _ActionButton(
          icon: Icons.mail_rounded,
          label: 'E-posta Şablonları',
          onTap: () => context.push('/admin/email-templates'),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemeColors.accentPink.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppThemeColors.accentPink, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: context.colors.onSurface,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

Color _getHealthColor(HealthStatus status) {
  switch (status) {
    case HealthStatus.excellent:
      return AppThemeColors.accentCyan;
    case HealthStatus.good:
      return Colors.green;
    case HealthStatus.fair:
      return AppThemeColors.accentPink;
    case HealthStatus.poor:
      return Colors.orange;
    case HealthStatus.critical:
      return AppThemeColors.liveRed;
  }
}
