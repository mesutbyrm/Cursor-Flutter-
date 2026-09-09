import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../profile/presentation/providers/profile_providers.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_state_panel.dart';
import 'ultra_fortune_tokens.dart';

/// Günlük görev ilerleme — `GET /api/daily-missions`.
class UltraFortuneDailyMissionsStrip extends ConsumerWidget {
  const UltraFortuneDailyMissionsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userDailyTasksProvider);

    return tasks.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: SizedBox(
          height: 72,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: UltraFortuneStatePanel(
          icon: Icons.error_outline_rounded,
          message: 'Günlük görevler yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(userDailyTasksProvider),
          height: 88,
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: UltraFortuneStatePanel(
              icon: Icons.task_alt_rounded,
              message: 'Bugün için görev bulunamadı',
              height: 72,
            ),
          );
        }
        final done = list.where((t) => t.completed).length;
        final total = list.length;
        final progress = total == 0 ? 0.0 : done / total;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: UltraFortuneLiquidSurface(
            onTap: () => context.push('/profile/growth'),
            borderRadius: BorderRadius.circular(18),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: PremiumSectionHeader(
                        title: 'GÜNLÜK GÖREVLER',
                        icon: Icons.task_alt_rounded,
                        iconColor: UltraFortuneTokens.metallicGold,
                      ),
                    ),
                    Text(
                      '$done / $total',
                      style: TextStyle(
                        color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    color: UltraFortuneTokens.metallicGold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
