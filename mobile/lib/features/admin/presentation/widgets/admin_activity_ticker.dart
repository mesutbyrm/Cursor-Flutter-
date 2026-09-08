import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../providers/admin_dashboard_providers.dart';

/// Dashboard üstü — son site aktiviteleri kaydırıcı.
class AdminActivityTicker extends ConsumerWidget {
  const AdminActivityTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminRecentActivitiesProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rows) {
        if (rows.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.bolt_rounded,
                    size: 16,
                    color: AppThemeColors.accentCyan,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Canlı aktivite',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppThemeColors.accentCyan,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rows.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final row = rows[i];
                  return _ActivityChip(row: row);
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        );
      },
    );
  }
}

class _ActivityChip extends StatelessWidget {
  const _ActivityChip({required this.row});

  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final type = (row['activityType'] ?? row['type'] ?? 'aktivite')
        .toString();
    final user = row['user'] is Map
        ? (row['user'] as Map)['name']?.toString() ??
            (row['user'] as Map)['username']?.toString()
        : row['username']?.toString();
    final at = _formatTime(
      row['createdAt']?.toString() ?? row['timestamp']?.toString(),
    );
    final label = user != null && user.isNotEmpty ? '$user · $type' : type;

    return DiscoverGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
            if (at != null) ...[
              const SizedBox(height: 4),
              Text(
                at,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return DateFormat('HH:mm').format(dt.toLocal());
  }
}
