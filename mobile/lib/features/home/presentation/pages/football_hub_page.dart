import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../domain/entities/home_football_match_entity.dart';
import '../providers/home_providers.dart';

/// Canlı futbol skorları — kılavuz `GET /api/football`.
class FootballHubPage extends ConsumerWidget {
  const FootballHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(footballHubMatchesProvider);
    return DiscoverSubPage(
      title: 'Futbol',
      subtitle: 'Canlı skorlar',
      onRefresh: () async {
        ref.invalidate(footballHubMatchesProvider);
        await ref.read(footballHubMatchesProvider.future);
      },
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => DiscoverEmptyState(
          icon: Icons.sports_soccer_rounded,
          message: ApiException.userMessage(e),
          action: () => ref.invalidate(footballHubMatchesProvider),
          actionLabel: 'Tekrar dene',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const DiscoverEmptyState(
              icon: Icons.sports_soccer_rounded,
              message: 'Şu an maç yok.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MatchTile(match: items[i]),
          );
        },
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final HomeFootballMatchEntity match;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (match.league != null && match.league!.trim().isNotEmpty)
        match.league!.trim(),
      if (match.status != null && match.status!.trim().isNotEmpty)
        match.status!.trim(),
    ].join(' • ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.sports_soccer_rounded),
        title: Text(
          '${match.homeTeam} – ${match.awayTeam}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: meta.isEmpty ? null : Text(meta),
        trailing: Text(
          match.scoreLabel,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
      ),
    );
  }
}
