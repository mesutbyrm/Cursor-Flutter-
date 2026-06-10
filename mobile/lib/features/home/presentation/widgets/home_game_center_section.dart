import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../games/domain/game_center_models.dart';
import '../../../games/presentation/game_center/providers/game_center_providers.dart';
import '../../../games/presentation/game_center/widgets/game_center_widgets.dart';
import '../theme/home_approved_design.dart';
import 'home_section_header.dart';

/// Ana sayfa — Oyun Merkezi CTA + liderlik önizlemesi + hızlı oyunlar.
class HomeGameCenterSection extends ConsumerWidget {
  const HomeGameCenterSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jeton = ref.watch(gameCenterJetonProvider);
    final leaderboard = ref.watch(
      gameCenterLeaderboardProvider(LeaderboardPeriod.weekly),
    );
    final formatter = NumberFormat.decimalPattern('tr');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: 'Oyun Merkezi',
          subtitle: 'Çevir, yarış, kazan',
          trailingLabel: 'Aç',
          onTrailing: () => context.push('/games-hub'),
          leadingDotColor: HomeApprovedDesign.purple,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Material(
            color: HomeApprovedDesign.surface,
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.push('/games-hub'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
                  border: Border.all(color: HomeApprovedDesign.border),
                  gradient: LinearGradient(
                    colors: [
                      HomeApprovedDesign.purple.withValues(alpha: 0.22),
                      HomeApprovedDesign.pink.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEC4899)],
                        ),
                      ),
                      child: const Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Oyun Merkezi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: HomeApprovedDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            jeton.when(
                              data: (b) => '${formatter.format(b)} Jeton',
                              loading: () => 'Jeton yükleniyor…',
                              error: (_, __) => 'Kader Çarkı, Quiz, Tavla ve daha fazlası',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: HomeApprovedDesign.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: HomeApprovedDesign.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        GameCenterLeaderboardPreview(
          entries: leaderboard.valueOrNull ?? const [],
          isLoading: leaderboard.isLoading,
          onSeeAll: () => context.push('/games-hub/leaderboard'),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
            itemCount: GameCenterCatalog.popular.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final game = GameCenterCatalog.popular[i];
              return _QuickGameChip(
                game: game,
                onTap: () => context.push(game.route),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickGameChip extends StatelessWidget {
  const _QuickGameChip({required this.game, required this.onTap});

  final GameCenterItem game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: game.gradient.first.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          border: Border.all(
            color: game.gradient.first.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(game.icon, color: game.gradient.first, size: 24),
            const SizedBox(height: 6),
            Text(
              game.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: HomeApprovedDesign.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
