import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../fortune/presentation/providers/fortune_api_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../premium_2026/profile_membership_helpers.dart';
import '../premium_2026/profile_theme.dart';
import '../providers/profile_hub_providers.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../../../membership/presentation/controllers/membership_controller.dart';

const _kMembershipServiceSlug = '__membership__';
const _kVipGoldServiceSlug = '__vip_gold__';

/// Hizmetlerim — API'den dinamik fal türleri.
class ProfileHubServicesRow extends ConsumerWidget {
  const ProfileHubServicesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(homeFortuneCardsProvider);
    final historyAsync = ref.watch(fortuneHistoryProvider);
    final membershipInfo = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(membershipInfo, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;
    final membershipTitle = buildMembershipHubMembershipServiceCardTitle(
      info: membershipInfo,
    );
    final vipGoldTitle = buildMembershipHubVipGoldServiceCardTitle(
      info: membershipInfo,
    );
    final membershipHint = buildMembershipHubServiceCardHint(
      info: membershipInfo,
      tiers: ui.tiers,
      packages: ui.apiPackages,
      catalogTier: catalogTier,
      expiresAt: expiresAt,
    );
    final vipGoldHint = buildMembershipHubVipGoldServiceCardHint(
      info: membershipInfo,
    );

    return cardsAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => _fallbackServices(context, ref),
      data: (cards) {
        if (cards.isEmpty) return _fallbackServices(context, ref);
        final history = historyAsync.valueOrNull ?? const [];

        final services = [
          _ServiceItem(
            title: membershipTitle,
            icon: '👑',
            slug: _kMembershipServiceSlug,
            count: 0,
            hint: membershipHint,
          ),
          _ServiceItem(
            title: vipGoldTitle,
            icon: '💎',
            slug: _kVipGoldServiceSlug,
            count: 0,
            hint: vipGoldHint,
          ),
          ...cards.take(6).map((c) {
          final slug = c.navigationSlug;
          final count = history
              .where((h) => (h.slug ?? h.type).contains(slug))
              .length;
          return _ServiceItem(
            title: c.title,
            icon: c.icon,
            slug: c.navigationSlug,
            count: count,
          );
        }),
        ];

        return _ServicesScroller(services: services);
      },
    );
  }

  Widget _fallbackServices(BuildContext context, WidgetRef ref) {
    final membershipInfo = ref.watch(profileMembershipInfoProvider);
    final ui = ref.watch(membershipControllerProvider);
    final catalogTier = catalogTierForMembership(membershipInfo, ui.tiers);
    final expiresAt =
        ref.watch(walletBalancesProvider).valueOrNull?.membershipExpiresAt;
    final membershipTitle = buildMembershipHubMembershipServiceCardTitle(
      info: membershipInfo,
    );
    final vipGoldTitle = buildMembershipHubVipGoldServiceCardTitle(
      info: membershipInfo,
    );
    final membershipHint = buildMembershipHubServiceCardHint(
      info: membershipInfo,
      tiers: ui.tiers,
      packages: ui.apiPackages,
      catalogTier: catalogTier,
      expiresAt: expiresAt,
    );
    final vipGoldHint = buildMembershipHubVipGoldServiceCardHint(
      info: membershipInfo,
    );
    const defaults = [
      _ServiceItem(title: 'Fal Geçmişim', icon: '☕', slug: 'kahve', count: 0),
      _ServiceItem(title: 'Tarot', icon: '🃏', slug: 'tarot', count: 0),
      _ServiceItem(title: 'Rüya', icon: '🌙', slug: 'ruya-tabiri', count: 0),
      _ServiceItem(title: 'İstihare', icon: '🕌', slug: 'istihare', count: 0),
      _ServiceItem(title: 'Aura', icon: '🌈', slug: 'aura', count: 0),
    ];
    final history = ref.watch(fortuneHistoryProvider).valueOrNull ?? const [];
    final withCounts = [
      _ServiceItem(
        title: membershipTitle,
        icon: '👑',
        slug: _kMembershipServiceSlug,
        count: 0,
        hint: membershipHint,
      ),
      _ServiceItem(
        title: vipGoldTitle,
        icon: '💎',
        slug: _kVipGoldServiceSlug,
        count: 0,
        hint: vipGoldHint,
      ),
      ...defaults.map((d) {
      final count = history
          .where((h) => (h.slug ?? h.type).contains(d.slug))
          .length;
      return _ServiceItem(
        title: d.title,
        icon: d.icon,
        slug: d.slug,
        count: count,
      );
    }),
    ];
    return _ServicesScroller(services: withCounts);
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.slug,
    required this.count,
    this.hint,
  });

  final String title;
  final String icon;
  final String slug;
  final int count;
  final String? hint;
}

class _ServicesScroller extends StatelessWidget {
  const _ServicesScroller({required this.services});

  final List<_ServiceItem> services;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            buildMembershipHubServicesSectionTitle(),
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final s = services[i];
              return _ServiceCard(item: s);
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item});

  final _ServiceItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: ProfileGlass(
        padding: const EdgeInsets.all(10),
        borderRadius: ProfilePremiumTheme.radiusSm,
        child: InkWell(
          onTap: () {
            if (item.slug == _kMembershipServiceSlug) {
              context.push('/premium-membership');
              return;
            }
            if (item.slug == _kVipGoldServiceSlug) {
              context.push('/vip-gold');
              return;
            }
            if (item.slug == 'kahve' || item.title.contains('Geçmiş')) {
              context.push('/fortune/ready');
            } else {
              context.push('/fortune/${item.slug}');
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 6),
              Text(
                item.title,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.hint != null && item.hint!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  item.hint!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.9),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              if (item.count > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${item.count}',
                  style: TextStyle(
                    color: ProfilePremiumTheme.neonPurple,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
