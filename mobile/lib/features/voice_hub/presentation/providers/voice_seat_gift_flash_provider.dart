import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';
import 'voice_gift_providers.dart';

/// Koltuk altında 3 sn gösterilen sesli oda hediye flaşı.
class VoiceSeatGiftFlash {
  const VoiceSeatGiftFlash({
    required this.id,
    required this.senderName,
    required this.receiverKey,
    required this.giftName,
    required this.quantity,
    required this.jeton,
    required this.expiresAt,
    this.imageUrl,
    this.receiverId,
    this.receiverName,
  });

  final String id;
  final String senderName;
  final String receiverKey;
  final String? receiverId;
  final String? receiverName;
  final String giftName;
  final int quantity;
  final int jeton;
  final DateTime expiresAt;
  final String? imageUrl;

  bool get expired => DateTime.now().isAfter(expiresAt);

  VoiceSeatGiftFlash copyWith({String? receiverKey}) {
    return VoiceSeatGiftFlash(
      id: id,
      senderName: senderName,
      receiverKey: receiverKey ?? this.receiverKey,
      receiverId: receiverId,
      receiverName: receiverName,
      giftName: giftName,
      quantity: quantity,
      jeton: jeton,
      expiresAt: expiresAt,
      imageUrl: imageUrl,
    );
  }
}

class VoiceSeatGiftFlashNotifier
    extends AutoDisposeFamilyNotifier<List<VoiceSeatGiftFlash>, String> {
  static const maxVisible = 3;
  static const ttl = Duration(seconds: 3);

  final Map<String, Timer> _timers = {};
  StreamSubscription<LiveGiftEvent>? _sub;

  @override
  List<VoiceSeatGiftFlash> build(String roomKey) {
    final service = ref.read(voiceRoomGiftRealtimeProvider);
    _sub?.cancel();
    _sub = service.events.listen(_onGift);
    ref.onDispose(() {
      _sub?.cancel();
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const [];
  }

  static List<String> receiverKeys({
    String? userId,
    String? displayName,
  }) {
    return [
      if (userId != null && userId.trim().isNotEmpty)
        receiverKey(userId: userId),
      if (displayName != null && displayName.trim().isNotEmpty)
        receiverKey(displayName: displayName),
    ];
  }

  /// Koltuk başına rebuild — boş koltuklar `''` döner (liste referansı değişse bile).
  static String flashSignature(
    List<VoiceSeatGiftFlash> state, {
    String? userId,
    String? displayName,
  }) {
    final flashes = flashesForReceiver(
      state,
      userId: userId,
      displayName: displayName,
    );
    if (flashes.isEmpty) return '';
    final parts = flashes.map((f) => '${f.id}:${f.jeton}:${f.quantity}').toList()
      ..sort();
    return parts.join(';');
  }

  static List<VoiceSeatGiftFlash> flashesForReceiver(
    List<VoiceSeatGiftFlash> state, {
    String? userId,
    String? displayName,
  }) {
    final keys = receiverKeys(userId: userId, displayName: displayName);
    if (keys.isEmpty) return const [];
    final out = <VoiceSeatGiftFlash>[];
    final seen = <String>{};
    for (final f in state) {
      if (f.expired || seen.contains(f.id)) continue;
      if (keys.any((k) => f.receiverKey == k)) {
        seen.add(f.id);
        out.add(f);
      }
    }
    return out;
  }

  static String receiverKey({String? userId, String? displayName}) {
    final id = userId?.trim() ?? '';
    if (id.isNotEmpty) return 'id:$id';
    final name = displayName?.trim().toLowerCase() ?? '';
    return 'name:$name';
  }

  void enqueue(LiveGiftEvent ev) {
    final keys = <String>{
      if (ev.receiverId != null && ev.receiverId!.trim().isNotEmpty)
        receiverKey(userId: ev.receiverId),
      if (ev.receiverName.trim().isNotEmpty)
        receiverKey(displayName: ev.receiverName),
    };
    if (keys.isEmpty) return;

    final sender = ev.senderName.trim().isNotEmpty ? ev.senderName.trim() : 'Biri';
    var next = List<VoiceSeatGiftFlash>.from(state);

    for (final key in keys) {
      final flash = VoiceSeatGiftFlash(
        id: '${ev.id}:$key',
        senderName: sender,
        receiverKey: key,
        receiverId: ev.receiverId,
        receiverName: ev.receiverName.trim().isNotEmpty ? ev.receiverName.trim() : null,
        giftName: ev.giftName,
        quantity: ev.quantity,
        jeton: ev.jetonAmount,
        imageUrl: ev.displayImageUrl,
        expiresAt: DateTime.now().add(ttl),
      );

      final forReceiver = [
        ...next.where((f) => f.receiverKey == key),
        flash,
      ];
      while (forReceiver.length > maxVisible) {
        final removed = forReceiver.removeAt(0);
        _timers.remove(removed.id)?.cancel();
      }
      next = [
        ...next.where((f) => f.receiverKey != key),
        ...forReceiver,
      ];

      _timers[flash.id]?.cancel();
      _timers[flash.id] = Timer(ttl, () => _remove(flash.id));
    }

    state = next;
  }

  void _onGift(LiveGiftEvent ev) => enqueue(ev);

  void _remove(String id) {
    _timers.remove(id)?.cancel();
    state = state.where((f) => f.id != id).toList(growable: false);
  }

  void clear() {
    for (final t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
    state = const [];
  }

  List<VoiceSeatGiftFlash> forReceiver({
    String? userId,
    String? displayName,
  }) =>
      flashesForReceiver(
        state,
        userId: userId,
        displayName: displayName,
      );
}

final voiceSeatGiftFlashProvider = NotifierProvider.autoDispose
    .family<VoiceSeatGiftFlashNotifier, List<VoiceSeatGiftFlash>, String>(
  VoiceSeatGiftFlashNotifier.new,
);
