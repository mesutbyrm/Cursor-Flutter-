import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../premium_2026/profile_theme.dart';

/// VIP ayrıcalıklar banner'ı.
class ProfileHubVipBanner extends StatelessWidget {
  const ProfileHubVipBanner({
    super.key,
    this.membership,
    this.daysRemaining,
    this.expiresAt,
    this.onViewPrivileges,
  });

  final String? membership;
  final int? daysRemaining;
  final String? expiresAt;
  final VoidCallback? onViewPrivileges;

  @override
  Widget build(BuildContext context) {
    final active = membership != null && membership!.trim().isNotEmpty;
    final label = active ? membership!.trim() : 'VIP';

    String subtitle;
    if (active && daysRemaining != null && daysRemaining! > 0) {
      subtitle = 'Aktif üyelik · $daysRemaining gün kaldı';
    } else if (active && expiresAt != null && expiresAt!.isNotEmpty) {
      final dt = DateTime.tryParse(expiresAt!);
      subtitle = dt != null
          ? 'Bitiş: ${DateFormat('d MMM yyyy', 'tr').format(dt.toLocal())}'
          : 'Size özel ayrıcalıkların tadını çıkarın!';
    } else if (active) {
      subtitle = 'Size özel ayrıcalıkların tadını çıkarın!';
    } else {
      subtitle = 'Premium üyelik avantajlarını keşfedin';
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusMd),
        gradient: LinearGradient(
          colors: [
            ProfilePremiumTheme.neonPurple.withValues(alpha: 0.85),
            const Color(0xFF4A148C),
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
            const Text('👑', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label Ayrıcalıkları',
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
            TextButton(
              onPressed: onViewPrivileges ?? () => context.push('/vip-gold'),
              child: const Text(
                'Ayrıcalıkları Gör >',
                style: TextStyle(
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
