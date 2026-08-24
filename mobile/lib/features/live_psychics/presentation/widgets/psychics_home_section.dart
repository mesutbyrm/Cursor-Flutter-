import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/home/presentation/widgets/premium_2026/home_horizontal_list.dart';
import 'package:canlifal_social/features/home/presentation/widgets/premium_2026/home_section_shell.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/navigation/psychic_card_navigation.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_premium_card.dart';

/// Ana sayfa — Canlı Falcılar V2 (premium kart + gerçek API).
class PsychicsHomeSection extends ConsumerWidget {
  const PsychicsHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psychics = ref.watch(homeDisplayedPsychicsProvider);

    return psychics.when(
      loading: () => HomeSectionShell(
        emoji: '🔮',
        title: 'Canlı Falcılar',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.push('/canli-falcilar'),
        contentHeight: PsychicPremiumCard.cardHeight,
        loading: HomeHorizontalList(
          height: PsychicPremiumCard.cardHeight,
          separatorWidth: 12,
          itemCount: 3,
          itemBuilder: (_, _) => const PsychicPremiumCardSkeleton(),
        ),
      ),
      error: (_, __) => HomeSectionShell(
        emoji: '🔮',
        title: 'Canlı Falcılar',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.push('/canli-falcilar'),
        errorMessage: 'Falcılar yüklenemedi',
        onRetry: () => ref.invalidate(homeOnlinePsychicsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return HomeSectionShell(
            emoji: '🔮',
            title: 'Canlı Falcılar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/canli-falcilar'),
            emptyIcon: Icons.psychology_outlined,
            emptyMessage:
                'Şu anda müsait falcı bulunmuyor. Biraz sonra tekrar deneyin.',
          );
        }
        final preview = list.take(12).toList();
        return HomeSectionShell(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
          child: RepaintBoundary(
            child: HomeHorizontalList(
              height: PsychicPremiumCard.cardHeight,
              separatorWidth: 12,
              itemCount: preview.length,
              itemBuilder: (_, i) => _Card(
                psychic: preview[i],
                onTap: () => openPsychicCardDestination(
                  context,
                  ref,
                  preview[i],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.psychic, required this.onTap});

  final PsychicEntity psychic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PsychicPremiumCard(
      name: psychic.name,
      avatarUrl: psychic.avatarUrl,
      isOnline: psychic.isOnline,
      rating: psychic.rating,
      reviewCount: psychic.reviewCount,
      categoryLabel: psychic.specialtiesLabel,
      pricePerMinute: psychic.pricePerMinute,
      showLiveBadge: psychic.hasLiveBroadcast && psychic.isOnline,
      onTap: onTap,
    );
  }
}
