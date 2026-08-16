import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../domain/membership_model.dart';
import '../../domain/membership_package_entity.dart';
import '../../../profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../vip_gold/domain/vip_tier.dart';

class MembershipCommonBenefits extends StatelessWidget {
  const MembershipCommonBenefits({
    super.key,
    this.membershipInfo = const ProfileMembershipInfo(
      raw: 'basic',
      tier: VipTier.basic,
    ),
    this.highlights = const [],
  });

  /// API `features[]` — doluysa statik katalog yerine gösterilir.
  final ProfileMembershipInfo membershipInfo;
  final List<MembershipFeatureHighlightEntity> highlights;

  @override
  Widget build(BuildContext context) {
    final useApi = highlights.isNotEmpty;
    final title = buildMembershipCommonBenefitsSectionTitle(
      info: membershipInfo,
      useApiHighlights: useApi,
    );
    final itemCount =
        useApi ? highlights.length : MembershipCatalogData.commonBenefits.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
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
              for (var i = 0; i < itemCount; i++)
                Expanded(
                  child: useApi
                      ? _ApiHighlightTile(
                          highlight: highlights[i],
                          index: i,
                        )
                      : _BenefitTile(
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
            if (useApi) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < itemCount; i++)
                    SizedBox(
                      width: (constraints.maxWidth - 10) / 2,
                      child: _ApiHighlightTile(
                        highlight: highlights[i],
                        index: i,
                      ),
                    ),
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

class _ApiHighlightTile extends StatelessWidget {
  const _ApiHighlightTile({required this.highlight, required this.index});

  final MembershipFeatureHighlightEntity highlight;
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
                highlight.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
              if (highlight.subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  highlight.subtitle!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    height: 1.2,
                  ),
                ),
              ],
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
