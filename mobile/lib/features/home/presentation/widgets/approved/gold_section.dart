import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../membership/domain/membership_package_entity.dart';
import '../../../../membership/presentation/pages/premium_membership_page.dart';
import '../../data/section_visual_catalog.dart';
import '../../theme/home_approved_design.dart';
import 'home_section_title.dart';
import '../premium_2026/premium_home_glass_card.dart';

/// Gold Üyelikler — 2026 premium yatay tier kartları.
class GoldSection extends ConsumerWidget {
  const GoldSection({super.key});

  static const _cardW = 148.0;
  static const _cardH = 200.0;
  static const _gap = 12.0;

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
      id: 'premium',
      planId: 'premium',
      title: 'Premium',
      durationDays: 30,
      priceJeton: 3000,
      bonusJeton: 3500,
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
      loading: () => _skeleton(context),
      error: (_, _) => _content(context, _fallbackPackages),
      data: (cat) => _content(
        context,
        cat.packages.isNotEmpty ? cat.packages : _fallbackPackages,
      ),
    );
  }

  Widget _skeleton(BuildContext context) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '👑',
          title: 'Gold Üyelikler',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/premium-membership'),
        ),
        SizedBox(
          height: _cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (_, _) => const PremiumSkeleton(
              width: _cardW,
              height: _cardH,
              borderRadius: BorderRadius.all(Radius.circular(24)),
            ),
          ),
        ),
      ],
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
          height: _cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: _cardW * 3,
            itemCount: packages.length,
            separatorBuilder: (_, _) => const SizedBox(width: _gap),
            itemBuilder: (_, i) {
              final pkg = packages[i];
              final theme = _tierTheme(pkg);
              return PremiumHomeGlassCard(
                title: pkg.title,
                subtitle: '₺${pkg.priceJeton ~/ 2}/ay · +${pkg.bonusJeton} jeton',
                coverSlug: SectionVisualCatalog.goldSlug(
                  pkg.planId.isNotEmpty ? pkg.planId : pkg.id,
                ),
                networkUrl: SectionVisualCatalog.goldTier(
                  pkg.planId.isNotEmpty ? pkg.planId : pkg.id,
                  width: 400,
                ),
                heroTag: 'home-gold-${pkg.id}',
                width: _cardW,
                height: _cardH,
                accentColor: theme.accent,
                shimmer: theme.shimmer,
                onTap: () => context.push('/premium-membership'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TierTheme {
  const _TierTheme({required this.accent, this.shimmer = true});

  final Color accent;
  final bool shimmer;
}

_TierTheme _tierTheme(MembershipPackageEntity pkg) {
  final key = pkg.planId.isNotEmpty ? pkg.planId : pkg.id;
  return switch (key) {
    'basic' => const _TierTheme(accent: Color(0xFFCD7F32)),
    'premium' => const _TierTheme(accent: Color(0xFF38BDF8)),
    'gold' => const _TierTheme(accent: Color(0xFFFFD700)),
    'diamond' => const _TierTheme(accent: Color(0xFFA855F7)),
    _ => const _TierTheme(accent: Color(0xFFA020F0)),
  };
}
