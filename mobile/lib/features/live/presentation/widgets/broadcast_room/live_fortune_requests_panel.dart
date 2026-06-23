import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../../../live_psychics/presentation/widgets/psychic_fortune_types.dart';

/// Yayıncı — fal istekleri kuyruğu paneli.
class LiveFortuneRequestsPanel extends StatelessWidget {
  const LiveFortuneRequestsPanel({
    super.key,
    required this.requests,
    required this.onStatusChange,
    this.loading = false,
  });

  final List<LiveFortuneRequestEntity> requests;
  final void Function(String id, LiveFortuneRequestStatus status) onStatusChange;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final sorted = sortFortuneRequestQueue(requests);
    final timeFmt = DateFormat('HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scroll) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF12101F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
                child: Row(
                  children: [
                    Text(
                      'Fal İstekleri (${sorted.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    if (loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: sorted.isEmpty
                    ? Center(
                        child: Text(
                          'Henüz fal isteği yok',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scroll,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: sorted.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final r = sorted[i];
                          return _RequestCard(
                            request: r,
                            timeLabel: timeFmt.format(r.createdAt.toLocal()),
                            onStatusChange: onStatusChange,
                          )
                              .animate(delay: (i * 60).ms)
                              .fadeIn(duration: 300.ms)
                              .slideY(begin: 0.06, end: 0);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.timeLabel,
    required this.onStatusChange,
  });

  final LiveFortuneRequestEntity request;
  final String timeLabel;
  final void Function(String id, LiveFortuneRequestStatus status) onStatusChange;

  @override
  Widget build(BuildContext context) {
    final typeLabel = psychicFortuneTypes
            .where((t) => t.key == request.fortuneType)
            .map((t) => t.label)
            .firstOrNull ??
        request.fortuneType;

    final glow = request.isPremiumTier
        ? const Color(0xFFFFD700)
        : const Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: glow.withValues(alpha: 0.45)),
        gradient: LinearGradient(
          colors: [
            glow.withValues(alpha: request.isPremiumTier ? 0.18 : 0.08),
            Colors.black.withValues(alpha: 0.35),
          ],
        ),
        boxShadow: request.isPremiumTier
            ? [
                BoxShadow(
                  color: glow.withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (request.isPremiumTier)
                Icon(Icons.star_rounded, color: glow, size: 18),
              Text(
                request.priority.label.toUpperCase(),
                style: TextStyle(
                  color: glow,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                timeLabel,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            typeLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            request.question,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _statusChip(
                'Beklemede',
                request.status == LiveFortuneRequestStatus.pending,
                () => onStatusChange(request.id, LiveFortuneRequestStatus.pending),
              ),
              _statusChip(
                'Beklet',
                request.status == LiveFortuneRequestStatus.held,
                () => onStatusChange(request.id, LiveFortuneRequestStatus.held),
              ),
              _statusChip(
                'İnceleniyor',
                request.status == LiveFortuneRequestStatus.reviewing,
                () => onStatusChange(request.id, LiveFortuneRequestStatus.reviewing),
              ),
              _statusChip(
                'Yanıtlandı',
                request.status == LiveFortuneRequestStatus.answered,
                () => onStatusChange(request.id, LiveFortuneRequestStatus.answered),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, bool active, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      backgroundColor: active
          ? const Color(0xFF7C3AED).withValues(alpha: 0.45)
          : Colors.white.withValues(alpha: 0.08),
      labelStyle: TextStyle(
        color: active ? Colors.white : Colors.white70,
        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
      ),
      side: BorderSide(
        color: active ? const Color(0xFFB832FF) : Colors.white24,
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
