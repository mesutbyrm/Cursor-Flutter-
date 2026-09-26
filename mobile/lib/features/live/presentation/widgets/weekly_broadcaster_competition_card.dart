import 'package:flutter/material.dart';

import '../../domain/pk/weekly_broadcaster_competition_models.dart';
import 'weekly_competition_detail_sheet.dart';

/// Haftalık yayıncı yarışması kutusu — kompakt özet, dokununca detay açılır.
///
/// Sıralamanın tamamı kutuda değil [showWeeklyCompetitionDetailSheet] içinde
/// gösterilir; kutu küçük ekranlarda oda kontrollerinin üzerine taşmamalı.
class WeeklyBroadcasterCompetitionCard extends StatefulWidget {
  const WeeklyBroadcasterCompetitionCard({
    super.key,
    required this.competition,
    this.maxWidth = 190,
  });

  final WeeklyBroadcasterCompetition competition;
  final double maxWidth;

  @override
  State<WeeklyBroadcasterCompetitionCard> createState() =>
      _WeeklyBroadcasterCompetitionCardState();
}

class _WeeklyBroadcasterCompetitionCardState
    extends State<WeeklyBroadcasterCompetitionCard> {
  bool _collapsed = false;

  void _openDetail() => showWeeklyCompetitionDetailSheet(context);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_collapsed) {
      return Semantics(
        button: true,
        label: 'Haftalık yarışmayı göster',
        child: GestureDetector(
          onTap: () => setState(() => _collapsed = false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆'),
                const SizedBox(width: 6),
                Icon(Icons.expand_less, size: 16, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final phase = widget.competition.phaseAt(now);

    return Container(
      width: widget.maxWidth,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _openDetail,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '🏆 ${widget.competition.displayTitle}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _collapsed = true),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _PhaseLine(phase: phase),
                const SizedBox(height: 6),
                Text(
                  _summaryLine(widget.competition, now, phase),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: _openDetail,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Sıralamayı gör'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _summaryLine(
    WeeklyBroadcasterCompetition competition,
    DateTime now,
    WeeklyCompetitionPhase phase,
  ) {
    final count = '👥 ${competition.participants.length}';
    if (phase == WeeklyCompetitionPhase.finished) return count;
    final left = competition.remainingAt(now);
    if (left == null) return count;
    final label = left.inDays >= 1
        ? '${left.inDays}g'
        : left.inHours >= 1
            ? '${left.inHours}s'
            : '${left.inMinutes}dk';
    return '$count  ·  ⏱ $label';
  }
}

class _PhaseLine extends StatelessWidget {
  const _PhaseLine({required this.phase});

  final WeeklyCompetitionPhase phase;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (phase) {
      WeeklyCompetitionPhase.upcoming => ('Yakında', scheme.tertiary),
      WeeklyCompetitionPhase.running => ('Devam ediyor', scheme.primary),
      WeeklyCompetitionPhase.finished => ('Sona erdi', scheme.outline),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
