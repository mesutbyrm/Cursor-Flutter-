import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/motion/canlifal_motion_widgets.dart';
import '../theme/home_approved_design.dart';

/// Referans — Tanış & Kaynaş geniş premium banner.
class HomeDiscoverPremiumBanner extends StatelessWidget {
  const HomeDiscoverPremiumBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        8,
        HomeApprovedDesign.hPad,
        16,
      ),
      child: CanlifalPressable(
        onTap: () => context.push('/social/tanis-kaynas'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4C1D95),
                Color(0xFF831843),
                Color(0xFF1E1B4B),
              ],
            ),
            border: Border.all(
              color: HomeApprovedDesign.pink.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: HomeApprovedDesign.purple.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💜 Tanış & Kaynaş',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Yeni insanlarla tanış,\nsohbet et, keşfet.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(
                            HomeApprovedDesign.pillRadius,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                        ),
                        child: const Text(
                          'Keşfet',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.favorite_rounded,
                  size: 56,
                  color: HomeApprovedDesign.pink.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
