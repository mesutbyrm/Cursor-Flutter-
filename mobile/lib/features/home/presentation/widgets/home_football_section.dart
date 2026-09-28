import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../football/data/football_remote_datasource.dart';
import '../../../football/domain/football_models.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Ana sayfa — bugünkü maçlar şeridi; tümü `/football`.
class HomeFootballSection extends ConsumerWidget {
  const HomeFootballSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final matches = ref.watch(
      footballMatchesProvider(DateTime(now.year, now.month, now.day)),
    );
    final list = <FootballMatch>[...?matches.valueOrNull]..sort((a, b) {
      if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
      return (a.utcDate ?? now).compareTo(b.utcDate ?? now);
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionTitle(
          emoji: '⚽',
          title: 'Futbol',
          actionLabel: 'Tümü >',
          onAction: () => context.push('/football'),
        ),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: HomeApprovedDesign.hPad,
            ),
            child: OutlinedButton.icon(
              onPressed: () => context.push('/football'),
              icon: const Icon(Icons.sports_soccer_rounded),
              label: const Text('Maçlar, puan durumu ve gol krallığı'),
            ),
          )
        else
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: HomeApprovedDesign.hPad,
              ),
              itemCount: list.length > 12 ? 12 : list.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) => _MatchChip(match: list[i]),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({required this.match});

  final FootballMatch match;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = match.utcDate?.toLocal();
    final center = match.hasScore && (match.isLive || match.isFinished)
        ? '${match.homeGoals} - ${match.awayGoals}'
        : t == null
            ? '—'
            : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => context.push('/football'),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: match.isLive ? Colors.red.withValues(alpha: 0.6) : c.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${match.competitionFlag} ${match.competitionName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurfaceMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              match.home.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              match.away.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const Spacer(),
            Text(
              match.isLive ? '$center · CANLI' : center,
              style: TextStyle(
                color: match.isLive ? Colors.red : c.primary,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
