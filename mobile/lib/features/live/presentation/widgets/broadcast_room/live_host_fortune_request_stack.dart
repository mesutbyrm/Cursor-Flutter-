import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_fortune_request_entity.dart';
import '../../providers/live_fortune_request_provider.dart';

/// Yayıncı ekranı — sağ üstte en fazla 3 fal isteği kartı (SSE + REST).
class LiveHostFortuneRequestStack extends ConsumerWidget {
  const LiveHostFortuneRequestStack({
    super.key,
    required this.streamId,
    this.topInset = 0,
  });

  final String streamId;
  final double topInset;

  static const int maxVisible = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveFortuneRequestsProvider(streamId));
    final pending = state.requests
        .where(
          (r) =>
              r.status == LiveFortuneRequestStatus.pending ||
              r.status == LiveFortuneRequestStatus.held ||
              r.status == LiveFortuneRequestStatus.reviewing,
        )
        .toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final sorted = sortFortuneRequestQueue(pending);
    final visible = sorted.length > maxVisible
        ? sorted.sublist(sorted.length - maxVisible)
        : sorted;

    return Positioned(
      top: topInset + 8,
      right: 12,
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final request in visible.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _FortuneHostCard(
                request: request,
                onAnswer: () => ref
                    .read(liveFortuneRequestsProvider(streamId).notifier)
                    .setStatus(request.id, LiveFortuneRequestStatus.reviewing),
                onReject: () => ref
                    .read(liveFortuneRequestsProvider(streamId).notifier)
                    .setStatus(request.id, LiveFortuneRequestStatus.cancelled),
                onHold: () => ref
                    .read(liveFortuneRequestsProvider(streamId).notifier)
                    .setStatus(request.id, LiveFortuneRequestStatus.held),
              ),
            ),
        ],
      ),
    );
  }
}

class _FortuneHostCard extends StatelessWidget {
  const _FortuneHostCard({
    required this.request,
    required this.onAnswer,
    required this.onReject,
    required this.onHold,
  });

  final LiveFortuneRequestEntity request;
  final VoidCallback onAnswer;
  final VoidCallback onReject;
  final VoidCallback onHold;

  @override
  Widget build(BuildContext context) {
    final typeLabel =
        '${request.priority.label} · ${request.fortuneType}';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Text('🔮', style: TextStyle(fontSize: 16)),
                SizedBox(width: 6),
                Text(
                  'Fal İsteği',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              typeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (request.question.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                request.question.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  height: 1.25,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    label: 'Cevapla',
                    color: const Color(0xFF2E7D32),
                    onTap: onAnswer,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionChip(
                    label: 'Reddet',
                    color: const Color(0xFFC62828),
                    onTap: onReject,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionChip(
                    label: 'Beklet',
                    color: const Color(0xFF1565C0),
                    onTap: onHold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
