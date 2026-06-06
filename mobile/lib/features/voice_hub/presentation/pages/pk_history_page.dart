import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/pk/pk_battle_remote_models.dart';
import '../providers/pk_battle_remote_provider.dart';

/// PK geçmişi — sunucu kayıtları.
class PkHistoryPage extends ConsumerWidget {
  const PkHistoryPage({super.key, this.battleType});

  final String? battleType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(pkHistoryProvider(battleType));

    return Scaffold(
      appBar: AppBar(title: const Text('PK Geçmişi')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Henüz PK geçmişi yok'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _HistoryTile(battle: items[i]),
          );
        },
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.battle});

  final PkBattleRemote battle;

  @override
  Widget build(BuildContext context) {
    final winner = battle.result?.winnerSide ?? '—';
    final left = battle.challenger?.displayName ?? 'Sol';
    final right = battle.opponent?.displayName ?? 'Sağ';
    return ListTile(
      title: Text('$left vs $right'),
      subtitle: Text(
        '${battle.challengerScore} — ${battle.opponentScore} · $winner',
      ),
      trailing: battle.result?.championBadge == true
          ? const Icon(Icons.emoji_events_rounded, color: Colors.amber)
          : null,
    );
  }
}
