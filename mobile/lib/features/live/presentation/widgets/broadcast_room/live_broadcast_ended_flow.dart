import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/domain/session_gift_summary.dart';
import '../../../../gifts/presentation/widgets/session_gift_summary_sheet.dart';
import '../../../../../core/economy/presentation/providers/economy_providers.dart';

/// Yayın sona erdi.
///
/// Yayıncı: «Canlı Yayın Özeti» (süre, maksimum izleyici, beğeni, alınan
/// hediyeler, kazanılan jeton) + [Kapat]. İzleyici: sade «Yayın bitti» kartı.
Future<void> showLiveBroadcastEndedFlow({
  required BuildContext context,
  required bool isHost,
  String? streamerName,
  SessionGiftSummary? summary,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => LiveBroadcastEndedCard(
      isHost: isHost,
      streamerName: streamerName,
      summary: summary,
      onClose: () => Navigator.pop(ctx),
      onDetails: summary != null && summary.hasData && isHost
          ? () async {
              Navigator.pop(ctx);
              if (context.mounted) {
                await showSessionGiftSummarySheet(context, summary: summary);
              }
            }
          : null,
    ),
  );
}

class LiveBroadcastEndedCard extends ConsumerWidget {
  const LiveBroadcastEndedCard({
    super.key,
    required this.isHost,
    required this.onClose,
    this.streamerName,
    this.summary,
    this.onDetails,
  });

  final bool isHost;
  final String? streamerName;
  final SessionGiftSummary? summary;
  final VoidCallback onClose;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = summary;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final showStats = isHost && s != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1250), Color(0xFF12081F)],
          ),
          border: Border.all(
            color: const Color(0xFFB832FF).withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.live_tv_rounded, color: Color(0xFFFF2D7A), size: 34),
            const SizedBox(height: 8),
            Text(
              showStats ? 'Canlı Yayın Özeti' : 'Yayın bitti',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
            if (!showStats) ...[
              const SizedBox(height: 10),
              Text(
                '${streamerName?.trim().isNotEmpty == true ? streamerName : 'Yayıncı'} yayını sona erdi.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
            ] else ...[
              const SizedBox(height: 16),
              _StatTile(
                emoji: '⏱',
                label: 'Yayın süresi',
                value: s.formatDuration(s.duration),
              ),
              _StatTile(
                emoji: '👥',
                label: 'Maksimum izleyici',
                value: '${s.peakViewerCount}',
              ),
              _StatTile(
                emoji: '❤️',
                label: 'Beğeni',
                value: '${s.likeCount}',
              ),
              _StatTile(
                emoji: '🎁',
                label: 'Alınan hediyeler',
                value: '${s.giftEventCount}',
              ),
              _StatTile(
                emoji: '💰',
                label: 'Kazanılan $jetonLabel',
                value: '${s.myNetJeton}',
                highlight: true,
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: onClose,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D7A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Kapat',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (onDetails != null)
              TextButton(
                onPressed: onDetails,
                child: const Text('Detaylı özet'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String emoji;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: highlight ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: highlight
            ? Border.all(color: const Color(0xFFFFD54F).withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD54F) : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
