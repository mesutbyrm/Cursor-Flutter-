import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../membership/presentation/controllers/membership_controller.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_theme.dart';

/// Ücretsiz kullanıcıya premium plan teşviki (profil hub — yalnızca free dal).
class ProfileHubVipBanner extends ConsumerWidget {
  const ProfileHubVipBanner({
    super.key,
    this.membership,
    this.onViewPrivileges,
  });

  final String? membership;
  final VoidCallback? onViewPrivileges;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = resolveProfileMembership(rawMembership: membership);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(info, ui.tiers);
    final subtitle = buildMembershipCatalogHintSubtitle(
      info: info,
      catalogTier: catalogTier,
    );

    void openPlans() {
      if (onViewPrivileges != null) {
        onViewPrivileges!();
        return;
      }
      context.push('/premium-membership');
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusMd),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3D2060),
            Color(0xFF1A0A30),
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
            const Text('✨', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium Üyelik',
                    style: TextStyle(
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
              onPressed: openPlans,
              child: const Text(
                'Planları Gör >',
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
