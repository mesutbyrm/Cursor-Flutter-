import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/pk/pk_battle_state.dart';
import '../providers/pk_battle_provider.dart';
import '../widgets/premium_2026/pk/pk_winner_celebration.dart';

/// PK sonuç ekranı.
class PkResultPage extends ConsumerWidget {
  const PkResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pk = ref.watch(pkBattleProvider);

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
          ? PkWinnerCelebration(
              state: pk,
              onRestart: () => context.pop(),
              onClose: () => context.pop(),
            )
          : const Center(child: Text('PK henüz bitmedi')),
    );
  }
}
