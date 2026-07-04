import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import 'voice_gift_providers.dart';

/// Koltuktaki bir kullanıcıya gönderilen hediyelerin göndericiye göre dökümü.
class SeatGiftContributor {
  const SeatGiftContributor({
    required this.senderName,
    required this.coins,
    required this.giftCount,
  });

  final String senderName;
  final int coins;
  final int giftCount;

  SeatGiftContributor add(int coins, int count) => SeatGiftContributor(
        senderName: senderName,
        coins: this.coins + coins,
        giftCount: giftCount + count,
      );
}

/// Bir alıcı için toplam jeton + gönderici dökümü.
class SeatGiftAggregate {
  const SeatGiftAggregate({
    required this.totalCoins,
    required this.contributors,
  });

  final int totalCoins;
  final Map<String, SeatGiftContributor> contributors;

  List<SeatGiftContributor> get topContributors {
    final list = contributors.values.toList()
      ..sort((a, b) => b.coins.compareTo(a.coins));
    return list;
  }
}

/// Oturum boyunca alıcı adına göre gelen hediyeleri biriktirir.
/// Hediye olaylarından (LiveGiftEvent) istemci tarafında toplanır.
class VoiceSeatGiftTotals extends Notifier<Map<String, SeatGiftAggregate>> {
  StreamSubscription<LiveGiftEvent>? _sub;

  @override
  Map<String, SeatGiftAggregate> build() {
    final service = ref.watch(voiceRoomGiftRealtimeProvider);
    _sub = service.events.listen(_record);
    ref.onDispose(() => _sub?.cancel());
    return const {};
  }

  String _key(String receiverName) => receiverName.trim().toLowerCase();

  void _record(LiveGiftEvent ev) {
    final receiver = ev.receiverName.trim();
    if (receiver.isEmpty) return;
    final key = _key(receiver);
    final coins = ev.coinCost * (ev.quantity <= 0 ? 1 : ev.quantity);
    final count = ev.quantity <= 0 ? 1 : ev.quantity;
    final sender =
        ev.senderName.trim().isNotEmpty ? ev.senderName.trim() : 'Bilinmeyen';

    final current = state[key];
    final contributors = <String, SeatGiftContributor>{
      ...?current?.contributors,
    };
    final sk = sender.toLowerCase();
    contributors[sk] = (contributors[sk] ??
            SeatGiftContributor(senderName: sender, coins: 0, giftCount: 0))
        .add(coins, count);

    state = {
      ...state,
      key: SeatGiftAggregate(
        totalCoins: (current?.totalCoins ?? 0) + coins,
        contributors: contributors,
      ),
    };
  }

  /// Belirli bir alıcı için toplu veriyi döndürür.
  SeatGiftAggregate? forReceiver(String receiverName) =>
      state[_key(receiverName)];
}

final voiceSeatGiftTotalsProvider =
    NotifierProvider<VoiceSeatGiftTotals, Map<String, SeatGiftAggregate>>(
  VoiceSeatGiftTotals.new,
);
