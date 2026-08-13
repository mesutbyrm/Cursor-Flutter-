import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../feed/presentation/providers/platform_stats_providers.dart';
import '../theme/home_approved_design.dart';

/// Kompakt canlı istatistik şeridi — `GET /api/public-stats`.
class HomePlatformStatsStrip extends ConsumerWidget {
  const HomePlatformStatsStrip({super.key});

  static String _format(int n) =>
      NumberFormat.compact(locale: 'tr').format(n);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(platformStatsProvider);
    return stats.when(
      loading: () => const SizedBox(height: 4),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) {
        if (data.onlineUsers <= 0 &&
            data.onLive <= 0 &&
            data.inVoiceChat <= 0) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeApprovedDesign.hPad,
            0,
            HomeApprovedDesign.hPad,
            8,
          ),
          child: Row(
            children: [
              if (data.onlineUsers > 0)
                Expanded(
                  child: _StatPill(
                    icon: Icons.groups_rounded,
                    color: HomeApprovedDesign.purple,
                    label: 'Çevrimiçi',
                    value: _format(data.onlineUsers),
                  ),
                ),
              if (data.onlineUsers > 0 && data.onLive > 0)
                const SizedBox(width: 8),
              if (data.onLive > 0)
                Expanded(
                  child: _StatPill(
                    icon: Icons.sensors_rounded,
                    color: HomeApprovedDesign.liveRed,
                    label: 'Canlı',
                    value: _format(data.onLive),
                  ),
                ),
              if (data.onLive > 0 && data.inVoiceChat > 0)
                const SizedBox(width: 8),
              if (data.inVoiceChat > 0)
                Expanded(
                  child: _StatPill(
                    icon: Icons.mic_rounded,
                    color: const Color(0xFF4DA6FF),
                    label: 'Sesli',
                    value: _format(data.inVoiceChat),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                    height: 1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: HomeApprovedDesign.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
