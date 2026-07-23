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

/// Ana sayfa — çevrimiçi falcılar yatay liste (premium kart).
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

  String get _stars {
    final r = psychic.rating.clamp(0, 5);
    final full = r.floor();
    final half = r - full >= 0.5;
    final buf = StringBuffer();
    for (var i = 0; i < full; i++) {
      buf.write('★');
    }
    if (half && full < 5) buf.write('☆');
    while (buf.length < 5) {
      buf.write('☆');
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final price = psychic.pricePerMinute;
    final reviews = psychic.reviewCount;

    return GestureDetector(
      onTap: () => context.push('/canli-falcilar/${psychic.id}'),
      child: Container(
        width: HomeApprovedDesign.tellerCardW,
        height: HomeApprovedDesign.tellerCardH,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(
            color: psychic.isOnline
                ? HomeApprovedDesign.purple.withValues(alpha: 0.5)
                : HomeApprovedDesign.border,
          ),
          boxShadow: psychic.isOnline ? const [HomeApprovedDesign.liveGlow] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (psychic.avatarUrl != null && psychic.avatarUrl!.isNotEmpty)
              CanlifalNetworkImage(
                url: psychic.avatarUrl!,
                fit: BoxFit.cover,
              )
            else
              ColoredBox(
                color: HomeApprovedDesign.searchFill,
                child: Center(
                  child: Text(
                    psychic.name.isNotEmpty
                        ? psychic.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: HomeApprovedDesign.textPrimary,
                    ),
                  ),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),
            ),
            if (psychic.isOnline)
              const Positioned(
                top: 8,
                left: 8,
                child: LiveBadge(compact: true, label: 'CANLI'),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: psychic.isOnline
                      ? HomeApprovedDesign.green.withValues(alpha: 0.9)
                      : Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  psychic.isOnline ? 'Müsait' : 'Çevrimdışı',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    psychic.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stars,
                    style: const TextStyle(
                      fontSize: 10,
                      color: HomeApprovedDesign.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (reviews > 0)
                    Text(
                      '($reviews yorum)',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  if (price > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$price jeton/dk',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.gold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
