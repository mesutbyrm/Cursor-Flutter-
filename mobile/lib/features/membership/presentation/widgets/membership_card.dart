import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/membership_model.dart';

class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.tier,
    required this.selected,
    required this.onTap,
    this.animationIndex = 0,
  });

  final MembershipTierModel tier;
  final bool selected;
  final VoidCallback onTap;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final card = GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: 132,
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: selected ? 0.14 : 0.08),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
            border: Border.all(
              color: selected
                  ? MembershipCatalogData.gold
                  : MembershipCatalogData.glassBorder,
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: MembershipCatalogData.gold.withValues(alpha: 0.35),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                    BoxShadow(
                      color: tier.glow.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tier.isActivePlan)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF34D399),
                            Color(0xFF059669),
                          ],
                        ),
                      ),
                      child: const Text(
                        'Aktif',
                        style: TextStyle(
                          color: Color(0xFF052E16),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else if (tier.popular)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFD54F),
                            Color(0xFFFFB300),
                          ],
                        ),
                      ),
                      child: const Text(
                        'Popüler',
                        style: TextStyle(
                          color: Color(0xFF1A1030),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 18),
                  Hero(
                    tag: 'membership-badge-${tier.wireId}',
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            tier.accent,
                            tier.glow.withValues(alpha: 0.75),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: tier.glow.withValues(alpha: 0.45),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: Icon(
                        tier.badgeIcon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tier.title,
                    style: TextStyle(
                      color: selected
                          ? MembershipCatalogData.gold
                          : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tier.subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_rounded,
                        size: 14,
                        color: MembershipCatalogData.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${tier.monthlyTokens}',
                        style: const TextStyle(
                          color: MembershipCatalogData.gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₺${tier.monthlyPriceTry}/ay',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return card
        .animate(delay: (80 * animationIndex).ms)
        .fadeIn(duration: 360.ms, curve: Curves.easeOut)
        .slideY(begin: 0.12, end: 0, duration: 420.ms, curve: Curves.easeOutCubic);
  }
}
