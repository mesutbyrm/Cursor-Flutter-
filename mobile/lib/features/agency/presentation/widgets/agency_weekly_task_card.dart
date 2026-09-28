import 'package:flutter/material.dart';

import '../../../platform_social/presentation/widgets/platform_social_ui_kit.dart';
import '../../domain/entities/agency_entity.dart';

String _day(DateTime? d) {
  if (d == null) return '—';
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}.${l.month.toString().padLeft(2, '0')}';
}

/// Haftalık ajans hedefi: kazanç %50, aktif üye %30, yeni üye %20 (backend APS).
class AgencyWeeklyTaskCard extends StatelessWidget {
  const AgencyWeeklyTaskCard({
    super.key,
    required this.task,
    required this.jetonLabel,
    this.onTap,
  });

  final AgencyWeeklyTask task;
  final String jetonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = task.completionPercent.clamp(0, 100).toDouble();
    return PlatformSocialGlassCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Hafta ${_day(task.weekStart)} – ${_day(task.weekEnd)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                '%${pct.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: pct >= 100
                      ? PlatformSocialPalette.success
                      : PlatformSocialPalette.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Progress(
            label: 'Kazanç',
            actual: task.earningsActual.toStringAsFixed(0),
            target: '${task.earningsTarget.toStringAsFixed(0)} $jetonLabel',
            ratio: task.earningsTarget > 0
                ? task.earningsActual / task.earningsTarget
                : 1,
          ),
          _Progress(
            label: 'Aktif üye',
            actual: '${task.activeUsersActual}',
            target: '${task.activeUsersTarget}',
            ratio: task.activeUsersTarget > 0
                ? task.activeUsersActual / task.activeUsersTarget
                : 1,
          ),
          _Progress(
            label: 'Yeni üye',
            actual: '${task.newUsersActual}',
            target: '${task.newUsersTarget}',
            ratio: task.newUsersTarget > 0
                ? task.newUsersActual / task.newUsersTarget
                : 1,
          ),
          if (task.bonusAwarded > 0)
            Text(
              'Bonus: ${task.bonusAwarded.toStringAsFixed(0)} $jetonLabel',
              style: const TextStyle(
                color: PlatformSocialPalette.gold,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({
    required this.label,
    required this.actual,
    required this.target,
    required this.ratio,
  });

  final String label;
  final String actual;
  final String target;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final r = ratio.clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: PlatformSocialPalette.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$actual / $target',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: r,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              color: r >= 1
                  ? PlatformSocialPalette.success
                  : PlatformSocialPalette.accent,
            ),
          ),
        ],
      ),
    );
  }
}
