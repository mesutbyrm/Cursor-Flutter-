import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:intl/intl.dart';

import '../../../agency/domain/entities/agency_leaderboard_entry.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Ajans liderlik önizlemesi — `GET /api/agency/leaderboard`.
class HomeAgencyLeaderboardSection extends ConsumerWidget {
  const HomeAgencyLeaderboardSection({super.key});

  static String _formatScore(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaders = ref.watch(homeAgencyLeaderboardProvider);
    return leaders.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        final top = entries.take(3).toList();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '🏢',
              title: 'Ajans Liderleri',
              actionLabel: 'Ajans >',
              onAction: () => context.push('/ajans/dashboard'),
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
                itemBuilder: (_, i) => _AgencyCard(
                  entry: top[i],
                  rank: i + 1,
                  onTap: () => context.push('/ajans/dashboard'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AgencyCard extends StatelessWidget {
  const _AgencyCard({
    required this.entry,
    required this.rank,
    required this.onTap,
  });

  final AgencyLeaderboardEntry entry;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medal = switch (rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '#$rank',
    };
    final logo = entry.logoUrl;
    final scoreLabel = entry.score > 0
        ? '${HomeAgencyLeaderboardSection._formatScore(entry.score)} puan'
        : entry.memberCount != null
            ? '${entry.memberCount} üye'
            : 'Ajans';

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
                const Color(0xFF06B6D4).withValues(alpha: rank == 1 ? 0.2 : 0.1),
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
                    scoreLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: logo != null && logo.isNotEmpty
                        ? CanlifalNetworkImage(
                            url: logo,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            color: HomeApprovedDesign.border,
                            child: const Icon(Icons.apartment_rounded, size: 18),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.name,
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
