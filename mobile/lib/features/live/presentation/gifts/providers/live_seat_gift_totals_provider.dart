import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/live_gift_event.dart';
import '../../../../voice_hub/presentation/providers/voice_seat_gift_totals_provider.dart';
import 'live_gift_providers.dart';

/// Canlı yayın koltukları — oturum boyunca alıcıya gelen hediyeleri biriktirir.
class LiveSeatGiftTotals extends Notifier<Map<String, SeatGiftAggregate>> {
  StreamSubscription<LiveGiftEvent>? _sub;

  @override
  Map<String, SeatGiftAggregate> build() {
    final service = ref.watch(liveGiftRealtimeProvider);
    _sub = service.events.listen(_record);
    ref.onDispose(() => _sub?.cancel());
    return const {};
  }

  void _record(LiveGiftEvent ev) {
    final receiverId = ev.receiverId?.trim();
    final receiver = ev.receiverName.trim();
    if (receiver.isEmpty && (receiverId == null || receiverId.isEmpty)) return;

    final coins = ev.jetonAmount;
    final count = ev.quantity <= 0 ? 1 : ev.quantity;
    final sender =
        ev.senderName.trim().isNotEmpty ? ev.senderName.trim() : 'Bilinmeyen';

    final keys = <String>{
      if (receiverId != null && receiverId.isNotEmpty)
        VoiceSeatGiftTotals.idKey(receiverId),
      if (receiver.isNotEmpty) VoiceSeatGiftTotals.nameKey(receiver),
    };
    if (keys.isEmpty) return;

    SeatGiftAggregate? base;
    for (final k in keys) {
      base = state[k] ?? base;
    }
    final contributors = <String, SeatGiftContributor>{
      ...?base?.contributors,
    };
    final sk = sender.toLowerCase();
    contributors[sk] = (contributors[sk] ??
            SeatGiftContributor(senderName: sender, coins: 0, giftCount: 0))
        .add(coins, count);
    final next = SeatGiftAggregate(
      totalCoins: (base?.totalCoins ?? 0) + coins,
      contributors: contributors,
    );

    final patch = <String, SeatGiftAggregate>{...state};
    for (final k in keys) {
      patch[k] = next;
    }
    state = patch;
  }

  void seedFromEvents(Iterable<LiveGiftEvent> events) {
    for (final ev in events) {
      _record(ev);
    }
  }

  void clear() => state = const {};
}

final liveSeatGiftTotalsProvider =
    NotifierProvider<LiveSeatGiftTotals, Map<String, SeatGiftAggregate>>(
  LiveSeatGiftTotals.new,
);
