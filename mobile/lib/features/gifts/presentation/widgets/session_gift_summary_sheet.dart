import 'package:flutter/material.dart';

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

class _SessionGiftSummaryBody extends StatelessWidget {
  const _SessionGiftSummaryBody({required this.summary});

  final SessionGiftSummary summary;

  @override
  Widget build(BuildContext context) {
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
            _metricTile(
              'Toplam atılan hediye',
              summary.formatJetonWithTl(summary.totalGrossJeton),
              Icons.card_giftcard_rounded,
              const Color(0xFFFF8EC7),
            ),
            if (summary.isHostOrOwner && summary.guestNetJeton > 0) ...[
              const SizedBox(height: 10),
              _metricTile(
                'Misafirlere giden pay',
                summary.formatJetonWithTl(summary.guestNetJeton),
                Icons.people_rounded,
                const Color(0xFF66E36F),
              ),
            ],
            const SizedBox(height: 10),
            _metricTile(
              summary.recipientOnly ? 'Size kalan pay' : 'Size kalan net',
              summary.formatJetonWithTl(summary.myNetJeton),
              Icons.monetization_on_rounded,
              const Color(0xFFFFD54F),
            ),
            if (summary.senders.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Kimden ne kadar atıldı',
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
                  shrinkWrap: true,
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
                      trailing: Text(
                        summary.formatJetonWithTl(row.grossJeton),
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
