import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../providers/profile_activity_notifier.dart';
import '../premium_2026/profile_theme.dart';

/// Profil — son 3 aktivite satırı.
class ProfileHubRecentActivity extends ConsumerWidget {
  const ProfileHubRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileActivityNotifierProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final recent = items.take(3).toList(growable: false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Son aktivite',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppThemeColors.accentPink,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push('/profile/transactions'),
                  child: const Text('Tümü', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...recent.map((e) => _ActivityTile(item: e)),
          ],
        );
      },
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final ProfileActivityItemEntity item;

  @override
  Widget build(BuildContext context) {
    final dt = item.createdAt != null ? DateTime.tryParse(item.createdAt!) : null;
    final time = dt != null
        ? DateFormat('dd.MM HH:mm').format(dt.toLocal())
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ProfilePremiumTheme.deepBg.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            size: 18,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty)
                  Text(
                    item.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          if (time != null)
            Text(
              time,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
        ],
      ),
    );
  }
}
