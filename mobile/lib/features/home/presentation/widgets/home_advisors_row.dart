import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/home_providers.dart';
import 'approved/home_section_title.dart';
import 'premium_2026/home_horizontal_list.dart';
import 'premium_2026/home_section_shell.dart';
import '../../../live_psychics/presentation/navigation/psychic_card_navigation.dart';
import '../../../live_psychics/presentation/widgets/psychic_premium_card.dart';

/// Popüler falcılar — `GET /api/advisors/online` (+ fortune-tellers yedek).
class HomeAdvisorsRow extends ConsumerWidget {
  const HomeAdvisorsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advisors = ref.watch(homeAdvisorsProvider);

    return advisors.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🔮',
            title: 'Popüler Falcılar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/canli-falcilar'),
          ),
          HomeHorizontalList(
            height: PsychicPremiumCard.cardHeight,
            separatorWidth: 12,
            itemCount: 3,
            itemBuilder: (_, _) => const PsychicPremiumCardSkeleton(),
          ),
        ],
      ),
      error: (_, __) => HomeSectionShell(
        emoji: '🔮',
        title: 'Popüler Falcılar',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.push('/canli-falcilar'),
        errorMessage: 'Popüler falcılar yüklenemedi',
        onRetry: () => ref.invalidate(homeAdvisorsProvider),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final list = items.where((a) => a.id.isNotEmpty).take(12).toList();
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🔮',
              title: 'Popüler Falcılar',
              actionLabel: 'Tümünü Gör >',
              onAction: () => context.push('/canli-falcilar'),
            ),
            HomeHorizontalList(
              height: PsychicPremiumCard.cardHeight,
              separatorWidth: 12,
              itemCount: list.length,
              itemBuilder: (_, i) {
                final psychic = list[i].toPsychicEntity();
                return PsychicPremiumCard(
                  name: psychic.name,
                  avatarUrl: psychic.avatarUrl,
                  isOnline: psychic.isOnline,
                  rating: psychic.rating,
                  reviewCount: psychic.reviewCount,
                  categoryLabel: psychic.specialtiesLabel,
                  pricePerMinute: psychic.pricePerMinute,
                  showLiveBadge: psychic.hasLiveBroadcast && psychic.isOnline,
                  onTap: () =>
                      openPsychicCardDestination(context, ref, psychic),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
