import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/ui/premium/live_badge.dart';
import 'package:canlifal_social/core/ui/premium/premium_skeleton.dart';
import 'package:canlifal_social/features/home/presentation/theme/home_approved_design.dart';
import 'package:canlifal_social/features/home/presentation/widgets/approved/home_section_title.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

/// Ana sayfa — çevrimiçi falcılar yatay liste.
class PsychicsHomeSection extends ConsumerWidget {
  const PsychicsHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final psychics = ref.watch(homeOnlinePsychicsProvider);

    return psychics.when(
      loading: () => Column(
        children: [
          HomeSectionTitle(
            emoji: '🔮',
            title: 'Canlı Falcılar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/canli-falcilar'),
          ),
          SizedBox(
            height: HomeApprovedDesign.tellerCardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => const PremiumSkeleton(
                width: HomeApprovedDesign.tellerCardW,
                height: HomeApprovedDesign.tellerCardH,
                borderRadius: BorderRadius.all(
                  Radius.circular(HomeApprovedDesign.cardRadius),
                ),
              ),
            ),
          ),
        ],
      ),
      error: (e, _) => _emptyState(context, message: '$e'),
      data: (list) {
        if (list.isEmpty) return _emptyState(context);
        return _content(context, list.take(12).toList());
      },
    );
  }

  Widget _content(BuildContext context, List<PsychicEntity> list) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
        ),
        RepaintBoundary(
          child: SizedBox(
            height: HomeApprovedDesign.tellerCardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _PsychicCard(psychic: list[i]),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  static Widget _emptyState(BuildContext context, {String? message}) {
    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: HomeApprovedDesign.hPad,
            vertical: 12,
          ),
          child: Text(
            message ?? 'Şu an çevrimiçi falcı yok.',
            style: TextStyle(
              fontSize: 13,
              color: HomeApprovedDesign.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }
}

class _PsychicCard extends StatelessWidget {
  const _PsychicCard({required this.psychic});

  final PsychicEntity psychic;

  @override
  Widget build(BuildContext context) {
    final specialty = psychic.displayCategory.trim();
    return GestureDetector(
      onTap: () => context.push('/canli-falcilar/${psychic.id}'),
      child: Container(
        width: HomeApprovedDesign.tellerCardW,
        height: HomeApprovedDesign.tellerCardH,
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: HomeApprovedDesign.surface,
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(
            color: psychic.isOnline
                ? HomeApprovedDesign.purple.withValues(alpha: 0.45)
                : HomeApprovedDesign.border,
          ),
          boxShadow: psychic.isOnline ? const [HomeApprovedDesign.liveGlow] : null,
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: psychic.avatarUrl != null &&
                          psychic.avatarUrl!.isNotEmpty
                      ? CanlifalNetworkImage(
                          url: psychic.avatarUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: HomeApprovedDesign.searchFill,
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: Center(
                              child: Text(
                                psychic.name.isNotEmpty
                                    ? psychic.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: HomeApprovedDesign.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
                if (psychic.isOnline)
                  const Positioned(
                    top: -4,
                    right: -4,
                    child: LiveBadge(compact: true, label: 'CANLI'),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    psychic.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                  if (specialty.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      specialty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: HomeApprovedDesign.textMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    psychic.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: psychic.isOnline
                          ? HomeApprovedDesign.green
                          : HomeApprovedDesign.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
