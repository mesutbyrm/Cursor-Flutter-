import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../gifts/domain/session_gift_summary.dart';
import '../../../../gifts/presentation/widgets/session_gift_summary_sheet.dart';
import '../../../../core/economy/presentation/providers/economy_providers.dart';

/// Yayın sona erdi — izleyici/yayıncı için kapanış ekranı + istatistik özeti.
Future<void> showLiveBroadcastEndedFlow({
  required BuildContext context,
  required bool isHost,
  String? streamerName,
  SessionGiftSummary? summary,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF12082A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.live_tv_rounded, color: Color(0xFFB832FF)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isHost ? 'Yayın sona erdi' : 'Yayın bitti',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHost
                  ? 'Canlı yayınınız sonlandı. Özetiniz aşağıda.'
                  : '${streamerName ?? 'Yayıncı'} yayını sona erdi.',
              style: const TextStyle(color: Colors.white70, height: 1.35),
            ),
            if (summary != null) ...[
              const SizedBox(height: 16),
              _EndedStatsPreview(summary: summary),
            ],
          ],
        ),
      ),
      actions: [
        if (summary != null && summary.hasData)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await showSessionGiftSummarySheet(context, summary: summary);
            },
            child: const Text('Detaylı özet'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
          ),
          child: const Text('Tamam'),
        ),
      ],
    ),
  );

  if (summary != null && summary.hasData && isHost) {
    await showSessionGiftSummarySheet(context, summary: summary);
  }
}

class _EndedStatsPreview extends ConsumerWidget {
  const _EndedStatsPreview({required this.summary});

  final SessionGiftSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.duration != null)
          _row('Süre', summary.formatDuration(summary.duration)),
        if (summary.peakViewerCount > 0)
          _row('İzleyici (tepe)', '${summary.peakViewerCount}'),
        if (summary.likeCount > 0) _row('Beğeni', '${summary.likeCount}'),
        if (summary.totalGrossJeton > 0)
          _row(
            'Hediye',
            summary.formatJetonWithTl(summary.totalGrossJeton, label: jetonLabel),
          ),
        if (summary.isHostOrOwner && summary.myNetJeton > 0)
          _row(
            'Kazanç (net)',
            summary.formatJetonWithTl(summary.myNetJeton, label: jetonLabel),
          ),
        if (summary.fortuneRequestCount > 0)
          _row(
            'Fal istekleri',
            '${summary.fortuneAcceptedCount}/${summary.fortuneRequestCount}',
          ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
