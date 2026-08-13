import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/navigation/native_site_routes.dart';
import '../../domain/entities/home_football_match_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Canlı futbol skorları — `GET /api/football`.
class HomeFootballSection extends ConsumerWidget {
  const HomeFootballSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(homeFootballMatchesProvider);
    return matches.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionTitle(
              emoji: '⚽',
              title: 'Futbol',
              actionLabel: 'Tümü >',
              onAction: () => openNativeSitePath(context, '/futbol'),
            ),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: HomeApprovedDesign.hPad,
                ),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _MatchCard(
                  match: items[i],
                  onTap: () => openNativeSitePath(context, '/futbol'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match, required this.onTap});

  final HomeFootballMatchEntity match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeApprovedDesign.surface,
      borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            border: Border.all(color: HomeApprovedDesign.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (match.league?.trim().isNotEmpty == true)
                Text(
                  match.league!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.textMuted,
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: HomeApprovedDesign.textPrimary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      match.scoreLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: HomeApprovedDesign.purple,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 11,
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
