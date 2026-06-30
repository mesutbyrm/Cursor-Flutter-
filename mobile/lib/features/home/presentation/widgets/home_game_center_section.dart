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
                              loading: () => 'Yakında yeni oyunlar',
                              error: (_, _) => 'Liderlik tablosu ve ödüller',
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
      ],
    );
  }
}
