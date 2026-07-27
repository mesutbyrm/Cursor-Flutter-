import 'package:flutter/material.dart';

import '../../../voice_hub/presentation/providers/voice_seat_gift_totals_provider.dart';
import 'seat_gift_breakdown_sheet.dart';

/// Koltuk altı toplam hediye jeton rozeti — tıklanınca gönderici dökümü açılır.
class SeatGiftBadge extends StatelessWidget {
  const SeatGiftBadge({
    super.key,
    required this.aggregate,
    required this.receiverName,
    this.compact = false,
  });

  final SeatGiftAggregate? aggregate;
  final String receiverName;
  final bool compact;

  static String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    final agg = aggregate;
    if (agg == null || agg.totalCoins <= 0) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 0 : 2),
      child: GestureDetector(
        onTap: () => showSeatGiftBreakdownSheet(
          context,
          receiverName: receiverName,
          aggregate: agg,
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 4 : 6,
            vertical: compact ? 0 : 1,
          ),
          decoration: BoxDecoration(
            color: const Color(0x33FFC107),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x66FFC107)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on_rounded,
                color: const Color(0xFFFFD54F),
                size: compact ? 9 : 10,
              ),
              const SizedBox(width: 3),
              Text(
                compact ? _fmt(agg.totalCoins) : _fmt(agg.totalCoins),
                style: TextStyle(
                  color: const Color(0xFFFFE082),
                  fontSize: compact ? 8 : 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider map'inden alıcı için aggregate seçer.
SeatGiftAggregate? selectSeatGiftAggregate(
  Map<String, SeatGiftAggregate> map, {
  String? userId,
  String? displayName,
}) {
  final id = userId?.trim();
  if (id != null && id.isNotEmpty) {
    final byId = map[VoiceSeatGiftTotals.idKey(id)];
    if (byId != null) return byId;
  }
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) {
    return map[VoiceSeatGiftTotals.nameKey(name)];
  }
  return null;
}
