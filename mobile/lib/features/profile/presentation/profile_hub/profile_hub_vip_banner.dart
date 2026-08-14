import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_theme.dart';

/// VIP / üyelik banner'ı — ücretsiz kullanıcıya plan teşviki, aktif üyeye özet.
class ProfileHubVipBanner extends StatelessWidget {
  const ProfileHubVipBanner({
    super.key,
    this.membership,
    this.daysRemaining,
    this.expiresAt,
    this.onViewPrivileges,
    this.onManageMembership,
  });

  final String? membership;
  final int? daysRemaining;
  final String? expiresAt;
  final VoidCallback? onViewPrivileges;
  final VoidCallback? onManageMembership;

  @override
  Widget build(BuildContext context) {
    final info = resolveProfileMembership(
      rawMembership: membership,
      daysRemaining: daysRemaining,
    );
    final paid = info.hasPaidTier;

    final title = paid ? '${info.tierLabel} Ayrıcalıkları' : 'Premium Üyelik';

    final String subtitle;
    if (paid && daysRemaining != null && daysRemaining! > 0) {
      subtitle = 'Aktif üyelik · $daysRemaining gün kaldı';
    } else if (paid && expiresAt != null && expiresAt!.isNotEmpty) {
      final dt = DateTime.tryParse(expiresAt!);
      subtitle = dt != null
          ? 'Bitiş: ${DateFormat('d MMM yyyy', 'tr').format(dt.toLocal())}'
          : 'Size özel ayrıcalıkların tadını çıkarın';
    } else if (paid) {
      subtitle = 'Rozetler, öncelikli destek ve VIP odalar';
    } else {
      subtitle = 'Gold, Diamond ve SVIP planlarını keşfedin';
    }

    final primaryCta = paid ? 'Ayrıcalıkları Gör' : 'Planları Gör';
    final secondaryCta = paid ? 'Yönet' : null;

    void openPrivileges() {
      if (onViewPrivileges != null) {
        onViewPrivileges!();
        return;
      }
      if (info.isVip) {
        context.push('/vip-gold');
      } else {
        context.push('/premium-membership');
      }
    }

    void openManage() {
      if (onManageMembership != null) {
        onManageMembership!();
        return;
      }
      context.push('/premium-membership');
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusMd),
        gradient: LinearGradient(
          colors: paid
              ? [
                  ProfilePremiumTheme.neonPurple.withValues(alpha: 0.85),
                  const Color(0xFF4A148C),
                ]
              : [
                  const Color(0xFF3D2060),
                  const Color(0xFF1A0A30),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(paid ? '👑' : '✨', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (secondaryCta != null) ...[
              TextButton(
                onPressed: openManage,
                child: Text(
                  secondaryCta,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            TextButton(
              onPressed: openPrivileges,
              child: Text(
                '$primaryCta >',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
