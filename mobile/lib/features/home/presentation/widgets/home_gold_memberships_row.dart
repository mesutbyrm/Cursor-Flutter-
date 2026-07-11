import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../membership/domain/membership_package_entity.dart';
import '../../../membership/presentation/pages/premium_membership_page.dart';
import '../theme/home_palette.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

class HomeGoldMembershipsRow extends ConsumerWidget {
  const HomeGoldMembershipsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(membershipCatalogProvider);

    return catalog.when(
      loading: () => _skeleton(),
      error: (_, _) => _fallback(context),
      data: (cat) => _content(context, cat.packages),
    );
  }

  Widget _skeleton() {
    return Column(
      children: [
        const HomeSectionHeader(
          title: 'Gold Üyelikler',
          leadingDotColor: Color(0xFFFFD700),
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, _) => SizedBox(width: 12),
            itemBuilder: (_, _) => PremiumSkeleton(
              width: 120,
              height: 155,
              borderRadius: BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback(BuildContext context) {
    return _content(
      context,
      const [
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
      ],
    );
  }

  Widget _content(BuildContext context, List<MembershipPackageEntity> packages) {
    return Column(
      children: [
        HomeSectionHeader(
          title: 'Gold Üyelikler',
          leadingDotColor: const Color(0xFFFFD700),
          onTrailing: () => context.push('/premium-membership'),
        ),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: packages.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
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

  Color get _accent {
    switch (pkg.id) {
      case 'gold':
        return const Color(0xFFFFD700);
      case 'diamond':
        return const Color(0xFFB84DFF);
      case 'premium':
        return const Color(0xFF38BDF8);
      default:
        return const Color(0xFFD97706);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: HomeGlassCard(
        onTap: onTap,
        glowColor: _accent,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _accent.withValues(alpha: 0.35),
            const Color(0xFF0A0618),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_icon, size: 36, color: _accent),
            const SizedBox(height: 10),
            Text(
              pkg.title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '₺${pkg.priceJeton ~/ 2}/ay',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${pkg.bonusJeton} jeton',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
