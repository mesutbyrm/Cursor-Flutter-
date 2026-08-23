import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/network/api_exception.dart';
import '../../../../../games/domain/game_models.dart';
import '../../../../../games/presentation/providers/game_providers.dart';

/// Yıldız turnuvası — `/api/tournaments` listesi ve katılım.
Future<void> showLiveStarTournamentSheet(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF151522),
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => const _LiveStarTournamentSheet(),
  );
}

class _LiveStarTournamentSheet extends ConsumerWidget {
  const _LiveStarTournamentSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournaments = ref.watch(gameTournamentsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yıldız Turnuvası',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aktif turnuvalara katılın, sıralamada yükselin.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            tournaments.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  ApiException.userMessage(e),
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Şu an açık turnuva yok. Yakında yenileri eklenecek.',
                      style: TextStyle(color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                  ),
                  child: ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) =>
                        _TournamentTile(item: list[i], ref: ref),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentTile extends ConsumerStatefulWidget {
  const _TournamentTile({required this.item, required this.ref});

  final GameScoreItem item;
  final WidgetRef ref;

  @override
  ConsumerState<_TournamentTile> createState() => _TournamentTileState();
}

class _TournamentTileState extends ConsumerState<_TournamentTile> {
  var _joining = false;

  Future<void> _join() async {
    if (_joining || widget.item.id.isEmpty) return;
    setState(() => _joining = true);
    try {
      await widget.ref.read(gameRemoteProvider).joinTournament(widget.item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.item.title} turnuvasına katıldınız')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (item.score > 0)
                  Text(
                    'Ödül: ${item.score} puan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          FilledButton(
            onPressed: _joining ? null : _join,
            child: _joining
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Katıl'),
          ),
        ],
      ),
    );
  }
}
