import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:intl/intl.dart';

import '../../../live/domain/pk/pk_leaderboard_models.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// PK liderlik önizlemesi — `GET /api/pk/leaderboard`.
class HomePkLeaderboardSection extends ConsumerWidget {
  const HomePkLeaderboardSection({super.key});

  static String _formatScore(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaders = ref.watch(homePkLeaderboardProvider);
    return leaders.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final top = entries.take(3).toList();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '⚔️',
              title: 'PK Liderleri',
              actionLabel: 'Tümü >',
              onAction: () => context.push('/pk/leaderboard'),
            ),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: top.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _PkLeaderCard(
                  entry: top[i],
                  rank: i + 1,
                  onTap: () => context.push('/pk/leaderboard'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PkLeaderCard extends StatelessWidget {
  const _PkLeaderCard({
    required this.entry,
    required this.rank,
    required this.onTap,
  });

  final PkLeaderboardEntry entry;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName?.trim().isNotEmpty == true
        ? entry.displayName!
        : 'Yayıncı';
    final avatar = entry.avatarUrl;
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };

    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 148,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
            gradient: LinearGradient(
              colors: [
                HomeApprovedDesign.liveRed.withValues(alpha: rank == 1 ? 0.2 : 0.1),
                HomeApprovedDesign.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(medal, style: const TextStyle(fontSize: 14)),
                  const Spacer(),
                  Text(
                    '${HomePkLeaderboardSection._formatScore(entry.score)} puan',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HomeApprovedDesign.liveRed,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: HomeApprovedDesign.border,
                    backgroundImage: avatar != null && avatar.isNotEmpty
                        ? canlifalImageProvider(avatar)
                        : null,
                    child: avatar == null || avatar.isEmpty
                        ? Text(
                            name.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
