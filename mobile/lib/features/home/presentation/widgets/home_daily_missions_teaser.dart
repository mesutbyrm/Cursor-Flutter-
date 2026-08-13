import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../profile/presentation/providers/profile_providers.dart';
import '../theme/home_approved_design.dart';
import 'approved/home_section_title.dart';

/// Günlük görevler önizlemesi — `/profile/growth` sayfasına yönlendirir.
class HomeDailyMissionsTeaser extends ConsumerWidget {
  const HomeDailyMissionsTeaser({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(userDailyTasksProvider);
    final pending = tasks.valueOrNull
            ?.where((t) => !t.completed && t.current < t.target)
            .length ??
        0;
    if (tasks.hasError && pending == 0) return const SizedBox.shrink();

    final subtitle = tasks.when(
      loading: () => 'Günlük görevler yükleniyor…',
      error: (_, _) => 'Görevleri tamamla, jeton ve XP kazan',
      data: (items) {
        if (items.isEmpty) return 'Görevleri tamamla, jeton ve XP kazan';
        if (pending > 0) return '$pending bekleyen görev';
        return 'Tüm görevler tamamlandı 🎉';
      },
    );

    return Column(
      children: [
        HomeSectionTitle(
          emoji: '🎯',
          title: 'Günlük Görevler',
          actionLabel: 'Aç >',
          onAction: () => context.push('/profile/growth'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: HomeApprovedDesign.hPad),
          child: Material(
            color: HomeApprovedDesign.surface,
            borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
            child: InkWell(
              onTap: () => context.push('/profile/growth'),
              borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
                  border: Border.all(color: HomeApprovedDesign.border),
                  gradient: LinearGradient(
                    colors: [
                      HomeApprovedDesign.gold.withValues(alpha: 0.15),
                      HomeApprovedDesign.purple.withValues(alpha: 0.08),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: HomeApprovedDesign.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: HomeApprovedDesign.gold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Görevler & Rozetler',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: HomeApprovedDesign.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: HomeApprovedDesign.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: HomeApprovedDesign.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
