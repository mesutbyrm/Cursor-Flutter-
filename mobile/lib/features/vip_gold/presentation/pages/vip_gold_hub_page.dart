import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/vip_tier.dart';
import '../providers/vip_membership_provider.dart';
import '../theme/vip_gold_tokens.dart';
import '../widgets/vip_luxury_card.dart';
import '../widgets/vip_privilege_grid.dart';
import '../widgets/vip_tier_carousel.dart';
import '../widgets/vip_badge.dart';

/// Premium VIP / Gold merkezi — SVIP ayrıcalıklar, upgrade.
class VipGoldHubPage extends ConsumerStatefulWidget {
  const VipGoldHubPage({super.key});

  @override
  ConsumerState<VipGoldHubPage> createState() => _VipGoldHubPageState();
}

class _VipGoldHubPageState extends ConsumerState<VipGoldHubPage> {
  VipTier _preview = VipTier.gold;

  @override
  Widget build(BuildContext context) {
    final tier = ref.watch(vipTierProvider);
    final days = ref.watch(vipMembershipDaysProvider);

    return Scaffold(
      backgroundColor: VipGoldTokens.bgDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: VipGoldTokens.goldRadial),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'VIP & Gold',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _CrownHero(tier: tier),
                        const SizedBox(height: 16),
                        VipBadge(tier: tier, animate: tier.isVip),
                        const SizedBox(height: 8),
                        Text(
                          'Mevcut: ${tier.label}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        if (days != null && days > 0)
                          Text(
                            '$days gün kaldı',
                            style: TextStyle(
                              color: AppColors.textMuted.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                        const SizedBox(height: 24),
                        VipLuxuryCard(
                          highlighted: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Gold üyelik',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'VIP odalar, özel giriş animasyonu, premium çerçeve ve şifreli odalar.',
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.black.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: () =>
                                    context.push('/premium-membership'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.black87,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text(
                                  'Gold Üye Ol',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Seviye önizleme',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMuted.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        VipTierCarousel(
                          selected: _preview,
                          onSelected: (t) => setState(() => _preview = t),
                        ),
                        const SizedBox(height: 20),
                        VipPrivilegeGrid(tier: _preview),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CrownHero extends StatelessWidget {
  const _CrownHero({required this.tier});

  final VipTier tier;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: VipGoldTokens.goldMid.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              colors: [
                VipGoldTokens.goldMid.withValues(alpha: 0.2),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 88,
            color: VipGoldTokens.goldMid,
            shadows: [
              Shadow(
                color: VipGoldTokens.goldMid.withValues(alpha: 0.8),
                blurRadius: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
