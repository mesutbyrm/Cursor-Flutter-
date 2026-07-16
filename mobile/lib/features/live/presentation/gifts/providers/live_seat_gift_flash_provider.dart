import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_gift_event.dart';
import 'live_gift_providers.dart';

/// Koltuk altında 3 sn gösterilen hediye flaşı.
class LiveSeatGiftFlash {
  const LiveSeatGiftFlash({
    required this.id,
    required this.receiverKey,
    required this.giftName,
    required this.quantity,
    required this.jeton,
    required this.expiresAt,
    this.imageUrl,
  });

  final String id;
  final String receiverKey;
  final String giftName;
  final int quantity;
  final int jeton;
  final DateTime expiresAt;
  final String? imageUrl;

  bool get expired => DateTime.now().isAfter(expiresAt);
}

class LiveSeatGiftFlashNotifier extends Notifier<Map<String, List<LiveSeatGiftFlash>>> {
  final Map<String, Timer> _timers = {};
  StreamSubscription<LiveGiftEvent>? _sub;

  static const _ttl = Duration(seconds: 3);

  @override
  Map<String, List<LiveSeatGiftFlash>> build() {
    final service = ref.watch(liveGiftRealtimeProvider);
    _sub = service.events.listen(_onGift);
    ref.onDispose(() {
      _sub?.cancel();
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  static String receiverKey({String? userId, String? displayName}) {
    final id = userId?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';
    final name = displayName?.trim().toLowerCase() ?? '';
    return 'name:$name';
  }

  void _onGift(LiveGiftEvent ev) {
    final keys = <String>{
      if (ev.receiverId != null && ev.receiverId!.trim().isNotEmpty)
        receiverKey(userId: ev.receiverId),
      if (ev.receiverName.trim().isNotEmpty)
        receiverKey(displayName: ev.receiverName),
    };
    if (keys.isEmpty) return;

    final flash = LiveSeatGiftFlash(
      id: ev.id,
      receiverKey: keys.first,
      giftName: ev.giftName,
      quantity: ev.quantity,
      jeton: ev.jetonAmount,
      imageUrl: ev.displayImageUrl,
      expiresAt: DateTime.now().add(_ttl),
    );

    final patch = <String, List<LiveSeatGiftFlash>>{...state};
    for (final k in keys) {
      final list = [...(patch[k] ?? const []), flash.copyWith(receiverKey: k)];
      patch[k] = list;
    }
    state = patch;

    for (final k in keys) {
      _timers[k]?.cancel();
      _timers[k] = Timer(_ttl, () => _prune(k));
    }
  }

  void _prune(String key) {
    final now = DateTime.now();
    final list = (state[key] ?? const [])
        .where((f) => f.expiresAt.isAfter(now))
        .toList();
    if (list.isEmpty) {
      final patch = {...state}..remove(key);
      state = patch;
    } else {
      state = {...state, key: list};
    }
    _timers.remove(key);
  }

  List<LiveSeatGiftFlash> forReceiver({
    String? userId,
    String? displayName,
  }) {
    final keys = <String>[
      if (userId != null && userId.trim().isNotEmpty)
        receiverKey(userId: userId),
      if (displayName != null && displayName.trim().isNotEmpty)
        receiverKey(displayName: displayName),
    ];
    final out = <LiveSeatGiftFlash>[];
    final seen = <String>{};
    for (final k in keys) {
      for (final f in state[k] ?? const []) {
        if (f.expired || seen.contains(f.id)) continue;
        seen.add(f.id);
        out.add(f);
      }
    }
    return out;
  }
}

extension on LiveSeatGiftFlash {
  LiveSeatGiftFlash copyWith({required String receiverKey}) {
    return LiveSeatGiftFlash(
      id: id,
      receiverKey: receiverKey,
      giftName: giftName,
      quantity: quantity,
      jeton: jeton,
      expiresAt: expiresAt,
      imageUrl: imageUrl,
    );
  }
}

final liveSeatGiftFlashProvider =
    NotifierProvider<LiveSeatGiftFlashNotifier, Map<String, List<LiveSeatGiftFlash>>>(
  LiveSeatGiftFlashNotifier.new,
);
