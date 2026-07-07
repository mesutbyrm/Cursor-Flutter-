import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../data/datasources/achievements_remote_datasource.dart';
import '../providers/profile_providers.dart';
import '../widgets/premium/profile_glass.dart';
import '../premium_2026/profile_theme.dart';

/// Son rozetler + sonraki rozet ilerlemesi.
class ProfileHubBadgesSection extends ConsumerWidget {
  const ProfileHubBadgesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(userAchievementsProvider);

    return async.when(
      loading: () => const PremiumSkeleton(
        height: 140,
        width: double.infinity,
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final unlocked = items.where((a) => a.unlocked).toList();
        final locked = items.where((a) => !a.unlocked).toList();
        final recent = unlocked.take(4).toList();
        final next = locked.isNotEmpty ? locked.first : null;

        return ProfileGlass(
          padding: const EdgeInsets.all(16),
          borderRadius: ProfilePremiumTheme.radiusMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Son Rozetlerim',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/profile/growth'),
                    child: const Text('Tümü >'),
                  ),
                ],
              ),
              if (recent.isNotEmpty)
                Row(
                  children: [
                    for (final badge in recent) ...[
                      Expanded(
                        child: _BadgeChip(badge: badge),
                      ),
                      if (badge != recent.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
              if (next != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ProfilePremiumTheme.glassBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sonraki Rozet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        next.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                      if (next.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          next.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                      if (next.progress != null && next.progress! > 0) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (next.progress! / 100).clamp(0.0, 1.0),
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(alpha: 0.1),
                            color: ProfilePremiumTheme.neonPurple,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${next.progress} / 100',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});

  final AchievementEntity badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: ProfilePremiumTheme.premiumGradient,
            boxShadow: [
              BoxShadow(
                color: ProfilePremiumTheme.neonPurple.withValues(alpha: 0.3),
                blurRadius: 12,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            badge.icon ?? '🏅',
            style: const TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          badge.title,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
