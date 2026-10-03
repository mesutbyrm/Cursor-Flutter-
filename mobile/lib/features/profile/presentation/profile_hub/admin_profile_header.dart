import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/mock_ui_kit.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../admin/presentation/providers/admin_dashboard_providers.dart';
import '../../../admin/presentation/providers/admin_providers.dart';
import '../../../admin/presentation/providers/staff_access_provider.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_streams_list_notifier.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../providers/profile_hub_providers.dart';

const _gold = Color(0xFFFFC13B);

/// Admin profil sayfası üst bölümü (mockup): taçlı avatar, ADMIN rozeti,
/// rol etiketi, 4 gerçek sayaç, Yönetim Merkezi / Profil Düzenle düğmeleri,
/// bilgi kartları ve «Hızlı İşlemler». Yalnızca yetkili staff için çizilir.
class AdminProfileHeader extends ConsumerWidget {
  const AdminProfileHeader({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final access = ref.watch(staffAccessProvider);
    if (!access.canAccessAdminHome) return const SizedBox.shrink();

    final ext = ref.watch(profileExtendedProvider).valueOrNull ??
        const ProfileExtendedEntity();
    final pending = ref.watch(adminPendingPaymentsCountProvider);
    final rooms = ref.watch(voiceRoomsListNotifierProvider).valueOrNull?.length;
    final streams = ref
        .watch(liveStreamsListNotifierProvider)
        .valueOrNull
        ?.where((s) => s.isLive)
        .length;
    final acts = ref.watch(staffFilteredActivitiesProvider).valueOrNull;
    final sessions = ref.watch(activeSessionsProvider).valueOrNull;
    final dateFmt = DateFormat('d MMM yyyy');

    String fmt(int? v) => v == null ? '—' : '$v';

    final lastActive = DateTime.tryParse(
      '${ext.raw['lastActiveAt'] ?? ext.raw['lastSeenAt'] ?? ''}',
    );

    void share() => unawaited(
          SharePlus.instance.share(
            ShareParams(text: 'https://canlifal.com/@${user.username}'),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              Image.asset(
                'assets/brand/canlifal_logo_horizontal.png',
                height: 26,
                errorBuilder: (_, _, _) => Text(
                  'CanlıFal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.onSurface,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Paylaş',
                icon: const Icon(Icons.ios_share_rounded, size: 22),
                onPressed: share,
              ),
              IconButton(
                tooltip: 'Ayarlar',
                icon: const Icon(Icons.settings_outlined, size: 23),
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Center(child: _CrownAvatar(user: user, online: ext.isOnline)),
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _gold, width: 1.6),
              color: _gold.withValues(alpha: 0.12),
            ),
            child: const Text(
              'ADMIN',
              style: TextStyle(
                color: _gold,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '@${user.username}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: c.onSurface,
                ),
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 5),
              const Icon(Icons.verified_rounded,
                  size: 17, color: Color(0xFF3B9DFF)),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                'Sistem Yöneticisi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: c.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD36B), Color(0xFFFF9F1C)],
                ),
              ),
              child: Text(
                access.roleLabel,
                style: const TextStyle(
                  color: Color(0xFF2B1B00),
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _Kpi(value: fmt(acts?.length), label: 'Yönetici İşlemi'),
            _Kpi(value: fmt(pending), label: 'Bekleyen Ödeme'),
            _Kpi(value: fmt(streams), label: 'Aktif Yayın'),
            _Kpi(value: fmt(rooms), label: 'Aktif Oda'),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 5,
              child: _GoldButton(
                onTap: () => context.push('/admin/center'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _OutlineBtn(
                label: 'Profil Düzenle',
                onTap: () => context.push('/profile/edit'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.access_time_rounded,
                color: const Color(0xFF3B82F6),
                label: 'Son Aktivite',
                value: lastActive == null ? '—' : dateFmt.format(lastActive),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.verified_user_rounded,
                color: const Color(0xFFEC4899),
                label: 'Yetki Seviyesi',
                value: access.roleLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _InfoCard(
                icon: Icons.calendar_month_rounded,
                color: const Color(0xFF3B82F6),
                label: 'Katılma Tarihi',
                value: ext.joinedAt == null ? '—' : dateFmt.format(ext.joinedAt!),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _InfoCard(
                icon: Icons.shield_rounded,
                color: const Color(0xFF22C55E),
                label: 'Giriş Cihazları',
                value: sessions == null ? '—' : '${sessions.length} cihaz',
                onTap: () => context.push('/settings/devices'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: c.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            if (access.canManageUsers)
              _Quick(
                icon: Icons.groups_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'Kullanıcılar',
                onTap: () => context.push('/admin/users'),
              ),
            if (access.canManageLiveStreams)
              _Quick(
                icon: Icons.videocam_rounded,
                color: const Color(0xFFEF4444),
                label: 'Aktif Yayınlar',
                onTap: () => context.push('/admin/live-streams'),
              ),
            if (access.canViewReports)
              _Quick(
                icon: Icons.assignment_rounded,
                color: const Color(0xFFA855F7),
                label: 'Raporlar',
                onTap: () => context.push('/admin/reports'),
              ),
            if (access.canManageNotifications)
              _Quick(
                icon: Icons.campaign_rounded,
                color: const Color(0xFF22A6F2),
                label: 'Duyuru Gönder',
                onTap: () => context.push('/admin/notification-manager'),
              ),
          ],
        ),
      ],
    );
  }
}

class _CrownAvatar extends StatelessWidget {
  const _CrownAvatar({required this.user, required this.online});

  final UserEntity user;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 138,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 14,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE08A), Color(0xFFFF9F1C)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.45),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: UserAvatar(url: user.avatarUrl, radius: 46),
            ),
          ),
          const Positioned(
            top: -6,
            child: Icon(Icons.workspace_premium_rounded, size: 40, color: _gold),
          ),
          if (online)
            Positioned(
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 7, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Çevrimiçi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: c.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD36B), Color(0xFFFF9F1C)],
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  size: 18, color: Color(0xFF2B1B00)),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Yönetim Merkezi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFF2B1B00),
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          height: 44,
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mockCardBorder(context)),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: c.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: mockCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mockCardBorder(context)),
          ),
          child: Row(
            children: [
              MockIconSquare(icon: icon, color: color, size: 30),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: c.onSurfaceMuted),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: c.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Quick extends StatelessWidget {
  const _Quick({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: mockCardColor(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: mockCardBorder(context)),
              ),
              child: Column(
                children: [
                  MockIconSquare(icon: icon, color: color, size: 34),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: c.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
