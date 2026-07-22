import 'package:flutter/material.dart';

import '../../../voice_hub/presentation/providers/voice_seat_gift_totals_provider.dart';

/// Koltuk altı toplam hediyeye tıklanınca açılan gönderici dökümü.
void showSeatGiftBreakdownSheet(
  BuildContext context, {
  required String receiverName,
  required SeatGiftAggregate aggregate,
}) {
  final contributors = aggregate.topContributors;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1E1030),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.monetization_on_rounded,
                    color: Color(0xFFFFD54F), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$receiverName — Toplam Hediye',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  '${aggregate.totalCoins} Jeton',
                  style: const TextStyle(
                    color: Color(0xFFFFE082),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contributors.isEmpty)
              const Text(
                'Henüz hediye yok.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: contributors.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Colors.white12,
                    height: 1,
                  ),
                  itemBuilder: (_, i) {
                    final c = contributors[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0x33FFC107),
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Color(0xFFFFE082),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      title: Text(
                        c.senderName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        '${c.giftCount} hediye',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Text(
                        '${c.coins} Jeton',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
