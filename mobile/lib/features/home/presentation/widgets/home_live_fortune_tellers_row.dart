import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_glass_card.dart';
import 'home_section_header.dart';

/// canlifal.com ana sayfa — **Canlı Falcılar** (§3.2, `/api/fortune-tellers`).
class HomeLiveFortuneTellersRow extends ConsumerWidget {
  const HomeLiveFortuneTellersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tellers = ref.watch(homeLiveFortuneTellersProvider);

    return tellers.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(
            title: 'Canlı Falcılar',
            subtitle: 'Çevrimiçi uzmanlarla anında seans',
            leadingDotColor: AppThemeColors.accentPink,
          ),
          SizedBox(
            height: AppSpacing.liveCardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: AppSpacing.liveCardWidth,
                height: AppSpacing.liveCardHeight,
                borderRadius: BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final online = items.where((t) => t.isOnline).toList();
        final list = (online.isNotEmpty ? online : items).take(8).toList();
        return Column(
          children: [
            HomeSectionHeader(
              title: 'Canlı Falcılar',
              subtitle: 'Çevrimiçi uzmanlarla anında seans',
              leadingDotColor: AppThemeColors.accentPink,
              onTrailing: () => context.push('/canli-falcilar'),
            ),
            SizedBox(
              height: AppSpacing.liveCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _TellerCard(teller: list[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _QuickActions(),
            ),
          ],
        );
      },
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionChip(
            icon: Icons.auto_awesome_rounded,
            label: 'Fal & Tarot',
            onTap: () => context.go('/fortune'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: Icons.mic_rounded,
            label: 'Sesli Sohbet',
            onTap: () => context.push('/voice-rooms'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionChip(
            icon: Icons.person_add_rounded,
            label: 'Falcı Ol',
            onTap: () => context.push('/content-hub'),
          ),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeGlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: HomePalette.secondary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TellerCard extends StatelessWidget {
  const _TellerCard({required this.teller});

  final LiveFortuneTellerEntity teller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.liveCardWidth,
      height: AppSpacing.liveCardHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/canli-falcilar/${teller.id}'),
          borderRadius: BorderRadius.circular(HomePalette.radiusCard),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomePalette.radiusCard),
              boxShadow: [
                BoxShadow(
                  color: HomePalette.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(HomePalette.radiusCard),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (teller.avatarUrl != null && teller.avatarUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: teller.avatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 480,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                  ),
                  if (teller.isOnline)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: LiveBadge(compact: true),
                    ),
                  if (teller.levelLabel != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppThemeColors.coinGold.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          teller.levelLabel!,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A0F2E),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                teller.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (teller.rating > 0) ...[
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: AppThemeColors.coinGold,
                              ),
                              Text(
                                teller.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          teller.displayCategory,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                        if (teller.pricePerMinute > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${teller.pricePerMinute} jeton/dk',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: HomePalette.secondary.withValues(alpha: 0.95),
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
      ),
    );
  }

  Widget _placeholder() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HomePalette.primary.withValues(alpha: 0.55),
            const Color(0xFF1A0F2E),
          ],
        ),
      ),
      child: const Center(
        child: UserAvatar(radius: 36),
      ),
    );
  }
}
