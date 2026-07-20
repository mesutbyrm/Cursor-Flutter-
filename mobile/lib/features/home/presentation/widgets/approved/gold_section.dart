import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../membership/domain/membership_package_entity.dart';
import '../../../../membership/presentation/pages/premium_membership_page.dart';
import '../../data/section_visual_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';

/// Gold Üyelikler — yatay paket kartları.
class GoldSection extends ConsumerWidget {
  const GoldSection({super.key});

  static const _fallbackPackages = [
    MembershipPackageEntity(
      id: 'basic',
      planId: 'basic',
      title: 'Basic',
      durationDays: 30,
      priceJeton: 1000,
      bonusJeton: 250,
      falDiscountPercent: 0,
    ),
    MembershipPackageEntity(
      id: 'gold',
      planId: 'gold',
      title: 'Gold',
      durationDays: 30,
      priceJeton: 2000,
      bonusJeton: 1500,
      falDiscountPercent: 0,
    ),
    MembershipPackageEntity(
      id: 'premium',
      planId: 'premium',
      title: 'Premium',
      durationDays: 30,
      priceJeton: 3000,
      bonusJeton: 3500,
      falDiscountPercent: 0,
    ),
    MembershipPackageEntity(
      id: 'diamond',
      planId: 'diamond',
      title: 'Diamond',
      durationDays: 30,
      priceJeton: 5000,
      bonusJeton: 7500,
      falDiscountPercent: 0,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(membershipCatalogProvider);

    return catalog.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '👑',
            title: 'Gold Üyelikler',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/premium-membership'),
          ),
          SizedBox(
            height: 148,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => const PremiumSkeleton(
                width: 110,
                height: 140,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (_, _) => _content(context, _fallbackPackages),
      data: (cat) => _content(
        context,
        cat.packages.isNotEmpty ? cat.packages : _fallbackPackages,
      ),
    );
  }

  Widget _content(BuildContext context, List<MembershipPackageEntity> packages) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '👑',
          title: 'Gold Üyelikler',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/premium-membership'),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: packages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _TierCard(
              pkg: packages[i],
              onTap: () => context.push('/premium-membership'),
            ),
          ),
        ),
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({required this.pkg, required this.onTap});

  final MembershipPackageEntity pkg;
  final VoidCallback onTap;

  Color get _accent {
    switch (pkg.id) {
      case 'gold':
        return HomeApprovedDesign.gold;
      case 'diamond':
        return HomeApprovedDesign.purple;
      case 'premium':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFFD97706);
    }
  }

  IconData get _icon {
    switch (pkg.id) {
      case 'gold':
        return Icons.star_rounded;
      case 'diamond':
        return Icons.diamond_rounded;
      case 'premium':
        return Icons.diamond_outlined;
      default:
        return Icons.workspace_premium_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = SectionVisualCatalog.goldTier(pkg.planId, width: 320);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 110,
          decoration: BoxDecoration(
            border: Border.all(color: _accent.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.22),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CanlifalNetworkImage(url: imageUrl, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _accent.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_icon, size: 28, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      pkg.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${pkg.priceJeton ~/ 2}/ay',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.88),
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
