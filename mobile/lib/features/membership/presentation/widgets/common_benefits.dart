import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/membership_model.dart';

class MembershipCommonBenefits extends StatelessWidget {
  const MembershipCommonBenefits({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tüm Üyelerde Ortak Avantajlar',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 520;
            final children = [
              for (var i = 0;
                  i < MembershipCatalogData.commonBenefits.length;
                  i++)
                Expanded(
                  child: _BenefitTile(
                    benefit: MembershipCatalogData.commonBenefits[i],
                    index: i,
                  ),
                ),
            ];
            if (wide) {
              return Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    children[i],
                  ],
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    children[0],
                    const SizedBox(width: 10),
                    children[1],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    children[2],
                    const SizedBox(width: 10),
                    children[3],
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({required this.benefit, required this.index});

  final MembershipCommonBenefit benefit;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MembershipCatalogData.glassBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: MembershipCatalogData.gold,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                benefit.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (70 * index).ms)
        .fadeIn(duration: 320.ms)
        .scale(
          begin: const Offset(0.94, 0.94),
          end: const Offset(1, 1),
          duration: 360.ms,
        );
  }
}
