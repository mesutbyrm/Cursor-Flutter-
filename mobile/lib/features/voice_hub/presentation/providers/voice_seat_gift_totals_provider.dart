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

/// Oturum boyunca alıcı kimliği/adına göre gelen hediyeleri biriktirir.
class VoiceSeatGiftTotals extends Notifier<Map<String, SeatGiftAggregate>> {
  StreamSubscription<LiveGiftEvent>? _sub;

  @override
  Map<String, SeatGiftAggregate> build() {
    final service = ref.watch(voiceRoomGiftRealtimeProvider);
    _sub = service.events.listen(_record);
    ref.onDispose(() => _sub?.cancel());
    return const {};
  }

  static String idKey(String userId) => 'id:${userId.trim()}';

  static String nameKey(String receiverName) =>
      'name:${receiverName.trim().toLowerCase()}';

  void _record(LiveGiftEvent ev) {
    final receiverId = ev.receiverId?.trim();
    final receiver = ev.receiverName.trim();
    if (receiver.isEmpty &&
        (receiverId == null || receiverId.isEmpty)) {
      return;
    }
    final coins = ev.coinCost * (ev.quantity <= 0 ? 1 : ev.quantity);
    final count = ev.quantity <= 0 ? 1 : ev.quantity;
    final sender =
        ev.senderName.trim().isNotEmpty ? ev.senderName.trim() : 'Bilinmeyen';

    final keys = <String>{
      if (receiverId != null && receiverId.isNotEmpty) idKey(receiverId),
      if (receiver.isNotEmpty) nameKey(receiver),
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

  SeatGiftAggregate? forReceiver({
    String? userId,
    String? displayName,
  }) {
    final id = userId?.trim();
    if (id != null && id.isNotEmpty) {
      final byId = state[idKey(id)];
      if (byId != null) return byId;
    }
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return state[nameKey(name)];
    }
    return null;
  }
}

final voiceSeatGiftTotalsProvider =
    NotifierProvider<VoiceSeatGiftTotals, Map<String, SeatGiftAggregate>>(
  VoiceSeatGiftTotals.new,
);
