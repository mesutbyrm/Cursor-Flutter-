import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../domain/session_gift_summary.dart';

/// Yayın / oda çıkışında hediye özeti — kimden ne kadar, misafir payı, kalan net.
Future<void> showSessionGiftSummarySheet(
  BuildContext context, {
  required SessionGiftSummary summary,
}) async {
  if (!summary.hasData) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _SessionGiftSummaryBody(summary: summary),
  );
}

class _SessionGiftSummaryBody extends ConsumerWidget {
  const _SessionGiftSummaryBody({required this.summary});

  final SessionGiftSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              summary.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            if (summary.duration != null ||
                summary.peakViewerCount > 0 ||
                summary.likeCount > 0) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (summary.duration != null)
                    _chip(
                      Icons.timer_outlined,
                      'Süre',
                      summary.formatDuration(summary.duration),
                    ),
                  if (summary.peakViewerCount > 0)
                    _chip(
                      Icons.visibility_rounded,
                      'İzleyici',
                      '${summary.peakViewerCount}',
                    ),
                  if (summary.likeCount > 0)
                    _chip(
                      Icons.favorite_rounded,
                      'Beğeni',
                      '${summary.likeCount}',
                    ),
                  if (summary.giftEventCount > 0)
                    _chip(
                      Icons.redeem_rounded,
                      'Hediye',
                      '${summary.giftEventCount}',
                    ),
                  if (summary.fortuneRequestCount > 0)
                    _chip(
                      Icons.auto_awesome_rounded,
                      'Fal isteği',
                      '${summary.fortuneAcceptedCount}/${summary.fortuneRequestCount}',
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            _metricTile(
              'Toplam atılan hediye',
              summary.formatJetonWithTl(summary.totalGrossJeton, label: jetonLabel),
              Icons.card_giftcard_rounded,
              const Color(0xFFFF8EC7),
            ),
            if (summary.isHostOrOwner && summary.guestNetJeton > 0) ...[
              const SizedBox(height: 10),
              _metricTile(
                'Misafirlere giden pay',
                summary.formatJetonWithTl(summary.guestNetJeton, label: jetonLabel),
                Icons.people_rounded,
                const Color(0xFF66E36F),
              ),
            ],
            const SizedBox(height: 10),
            _metricTile(
              summary.recipientOnly ? 'Size kalan pay' : 'Size kalan net',
              summary.formatJetonWithTl(summary.myNetJeton, label: jetonLabel),
              Icons.monetization_on_rounded,
              const Color(0xFFFFD54F),
            ),
            if (summary.senders.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Kim ne kadar hediye attı',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.28,
                ),
                child: ListView.separated(
                  itemCount: summary.senders.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    color: Color(0x22FFFFFF),
                  ),
                  itemBuilder: (_, i) {
                    final row = summary.senders[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        row.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: row.giftCount > 0
                          ? Text(
                              '${row.giftCount} hediye',
                              style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: Text(
                        summary.formatJetonWithTl(row.grossJeton, label: jetonLabel),
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Color(0x99FFFFFF)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0x99FFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
