import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/ui/premium/live_badge.dart';
import 'package:canlifal_social/core/ui/premium/premium_skeleton.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';
import 'package:canlifal_social/features/home/presentation/theme/home_approved_design.dart';
import 'package:canlifal_social/features/home/presentation/widgets/premium_2026/home_horizontal_list.dart';
import 'package:canlifal_social/features/home/presentation/widgets/premium_2026/home_section_shell.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';

/// Ana sayfa — çevrimiçi falcılar yatay liste (premium kart).
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
        contentHeight: HomeApprovedDesign.tellerCardH,
        loading: HomeHorizontalList(
          height: HomeApprovedDesign.tellerCardH,
          itemCount: 3,
          itemBuilder: (_, _) => const PremiumSkeleton(
            width: HomeApprovedDesign.tellerCardW,
            height: HomeApprovedDesign.tellerCardH,
            borderRadius: BorderRadius.all(
              Radius.circular(HomeApprovedDesign.cardRadius),
            ),
          ),
        ),
      ),
      error: (e, _) => HomeSectionShell(
        emoji: '🔮',
        title: 'Canlı Falcılar',
        actionLabel: 'Tümünü Gör >',
        onAction: () => context.push('/canli-falcilar'),
        errorMessage: 'Falcılar yüklenemedi',
        onRetry: () => ref.invalidate(homeDisplayedPsychicsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return HomeSectionShell(
            emoji: '🔮',
            title: 'Canlı Falcılar',
            actionLabel: 'Tümünü Gör >',
            onAction: () => context.push('/canli-falcilar'),
            emptyIcon: Icons.psychology_outlined,
            emptyMessage: 'Şu an çevrimiçi falcı yok',
          );
        }
        return HomeSectionShell(
          emoji: '🔮',
          title: 'Canlı Falcılar',
          actionLabel: 'Tümünü Gör >',
          onAction: () => context.push('/canli-falcilar'),
          child: RepaintBoundary(
            child: HomeHorizontalList(
              height: HomeApprovedDesign.tellerCardH,
              itemCount: list.take(12).length,
              itemBuilder: (_, i) => _PsychicCard(psychic: list[i]),
            ),
          ),
        );
      },
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
    final category = psychic.displayCategory;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/canli-falcilar/${psychic.id}'),
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Ink(
          width: HomeApprovedDesign.tellerCardW,
          height: HomeApprovedDesign.tellerCardH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(
              color: psychic.isOnline
                  ? HomeApprovedDesign.purple.withValues(alpha: 0.5)
                  : HomeApprovedDesign.border,
            ),
            boxShadow:
                psychic.isOnline ? const [HomeApprovedDesign.liveGlow] : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            child: Stack(
            fit: StackFit.expand,
            children: [
              SizedBox.expand(
                child: psychic.avatarUrl != null &&
                        psychic.avatarUrl!.trim().isNotEmpty
                    ? CanlifalNetworkImage(
                        url: psychic.avatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: UserAvatar(url: null, radius: 44),
                        placeholder: UserAvatar(url: null, radius: 44),
                      )
                    : UserAvatar(url: null, radius: 44),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.78),
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
        ),
      ),
    );
  }
}
