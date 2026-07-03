import 'package:flutter/material.dart';

import '../profile_theme.dart';

/// Premium üyelik — gradient glow kart.
class ProfilePremiumCard extends StatelessWidget {
  const ProfilePremiumCard({
    super.key,
    this.membership,
    this.daysRemaining,
    this.onViewPrivileges,
  });

  final String? membership;
  final int? daysRemaining;
  final VoidCallback? onViewPrivileges;

  @override
  Widget build(BuildContext context) {
    final active = membership != null && membership!.trim().isNotEmpty;

    return RepaintBoundary(
      child: Container(
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
                      active ? 'Premium · $membership' : 'Premium Üyelik',
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
                      active && daysRemaining != null
                          ? '$daysRemaining gün kaldı · özel rozetler ve ayrıcalıklar'
                          : 'Özel rozetler, VIP odalar ve ekstra jeton fırsatları',
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
              FilledButton(
                onPressed: onViewPrivileges,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5A2A80),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text(
                  'Avantajları Gör',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
