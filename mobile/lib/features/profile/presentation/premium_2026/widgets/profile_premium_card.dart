import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../profile_membership_helpers.dart';
import '../profile_theme.dart';
import '../../../../membership/domain/membership_model.dart';

/// Premium üyelik — gradient glow kart.
class ProfilePremiumCard extends StatelessWidget {
  const ProfilePremiumCard({
    super.key,
    this.membership,
    this.daysRemaining,
    this.catalogSubtitle,
    this.catalogTier,
    this.expiresAt,
    this.onViewPrivileges,
    this.onManageMembership,
  });

  final String? membership;
  final int? daysRemaining;
  final String? catalogSubtitle;
  final MembershipTierModel? catalogTier;
  final String? expiresAt;
  final VoidCallback? onViewPrivileges;
  final VoidCallback? onManageMembership;

  @override
  Widget build(BuildContext context) {
    final info = resolveProfileMembership(
      rawMembership: membership,
      daysRemaining: daysRemaining,
    );
    final active = info.hasActiveSubscription;
    final expired = info.isExpired;

    return Container(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(ProfilePremiumTheme.radiusLg),
          gradient: ProfilePremiumTheme.premiumGradient,
          boxShadow: [
            BoxShadow(
              color: ProfilePremiumTheme.neonPink.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buildMembershipPremiumCardTitle(
                        info: info,
                        expiresAt: expiresAt,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      catalogSubtitle ??
                          buildMembershipPremiumCardSubtitle(
                            info: info,
                            tiers: const [],
                            catalogTier: catalogTier,
                            expiresAt: expiresAt,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton(
                    onPressed: onViewPrivileges ??
                        () {
                          if (info.isVip) {
                            context.push('/vip-gold');
                          } else {
                            context.push('/premium-membership');
                          }
                        },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF5A2A80),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      buildMembershipPremiumCardPrimaryActionLabel(info: info),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (active || expired) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: onManageMembership ??
                          () => context.push('/premium-membership'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        buildMembershipPremiumCardManageActionLabel(info: info),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
    );
  }
}
