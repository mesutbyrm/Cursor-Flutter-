import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/pk/live_pk_broadcast_stage.dart';
import '../../../live/domain/pk/live_pk_status_pill_mode.dart';
import '../../../live/presentation/widgets/broadcast_room/pk_status_pill.dart';
import '../providers/pk_battle_provider.dart';
import '../widgets/premium_2026/pk/pk_animated_score_bar.dart';

/// PK sonuç ekranı — tam ekran kutlama yok; skor + küçük rozet.
class PkResultPage extends ConsumerWidget {
  const PkResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(pkBattleProvider);
    final leftScore = pk.left.total;
    final rightScore = pk.right.total;
    final pillMode = livePkStatusPillMode(
      ended: pk.isFinished,
      leftScore: leftScore,
      rightScore: rightScore,
    );
    final winnerName = livePkWinnerName(
      leftScore: leftScore,
      rightScore: rightScore,
      leftLabel: pk.left.leader?.displayName ?? 'Sol',
      rightLabel: pk.right.leader?.displayName ?? 'Sağ',
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PK Sonucu'),
        actions: [
          TextButton(
            onPressed: () => context.push('/pk/history'),
            child: const Text('Geçmiş'),
          ),
        ],
      ),
      body: pk.isFinished
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${PkAnimatedScoreBar.fmt(leftScore)} — ${PkAnimatedScoreBar.fmt(rightScore)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PkStatusPill(
                      mode: pillMode,
                      winnerName: winnerName,
                      highlight: true,
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Kapat'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: pk.serverAuthoritative
                              ? () => context.pop()
                              : () =>
                                  ref.read(pkBattleProvider.notifier).restart(),
                          child: const Text('Tekrar PK'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : const Center(child: Text('PK henüz bitmedi')),
    );
  }
}
