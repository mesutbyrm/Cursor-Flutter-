import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/live_gift_event.dart';

/// Son hediye atan — koltuk altı kutusu için.
class VoiceRecentGifter {
  const VoiceRecentGifter({
    required this.senderId,
    required this.senderName,
    required this.lastJeton,
    required this.at,
  });

  final String senderId;
  final String senderName;
  final int lastJeton;
  final DateTime at;
}

/// Kayan hediye duyurusu metni.
class VoiceGiftAnnouncement {
  const VoiceGiftAnnouncement({
    required this.id,
    required this.line,
    required this.at,
  });

  final String id;
  final String line;
  final DateTime at;
}

class VoiceRecentGiftsState {
  const VoiceRecentGiftsState({
    this.gifters = const [],
    this.announcements = const [],
  });

  final List<VoiceRecentGifter> gifters;
  final List<VoiceGiftAnnouncement> announcements;
}

/// Oturum içi son hediye gönderenler + kayan duyuru kuyruğu.
class VoiceRecentGiftsController extends Notifier<VoiceRecentGiftsState> {
  static const maxGifters = 5;
  static const maxAnnouncements = 8;

  final _gifters = <String, VoiceRecentGifter>{};
  final _gifterOrder = <String>[];

  @override
  VoiceRecentGiftsState build() => const VoiceRecentGiftsState();

  void record(LiveGiftEvent event) {
    final gross = event.jetonAmount;
    if (gross <= 0) return;

    final senderId = (event.senderId ?? event.senderName).trim();
    if (senderId.isEmpty) return;

    // Sunucu bazen aynı hediyeyi admin + yayıncı satırı olarak iki kez yollar.
    final recent = state.announcements;
    if (recent.isNotEmpty) {
      final last = recent.first;
      final delta = event.timestamp.difference(last.at).inMilliseconds.abs();
      if (delta < 2500 && last.line.contains(event.giftName)) {
        final sender = event.senderName.trim();
        if (sender.isNotEmpty && last.line.startsWith(sender)) return;
      }
    }

    final now = event.timestamp;
    _gifters[senderId] = VoiceRecentGifter(
      senderId: senderId,
      senderName: event.senderName.trim().isNotEmpty
          ? event.senderName.trim()
          : 'Kullanıcı',
      lastJeton: gross,
      at: now,
    );
    _gifterOrder.remove(senderId);
    _gifterOrder.add(senderId);
    while (_gifterOrder.length > 24) {
      final removed = _gifterOrder.removeAt(0);
      _gifters.remove(removed);
    }

    final receiver = event.receiverName.trim().isNotEmpty
        ? event.receiverName.trim()
        : 'kullanıcı';
    final gift = event.giftName.trim().isNotEmpty
        ? event.giftName.trim()
        : 'hediye';
    final sender = event.senderName.trim().isNotEmpty
        ? event.senderName.trim()
        : 'Biri';

    final line =
        '$sender, $receiver kullanıcısına $gift hediyesini attı. 🪙$gross jeton.🎉';
    final announcements = [
      VoiceGiftAnnouncement(
        id: 'gift-${event.id}-${now.microsecondsSinceEpoch}',
        line: line,
        at: now,
      ),
      ...state.announcements,
    ];
    if (announcements.length > maxAnnouncements) {
      announcements.removeRange(maxAnnouncements, announcements.length);
    }

    final ordered = <VoiceRecentGifter>[];
    for (final id in _gifterOrder.reversed) {
      final g = _gifters[id];
      if (g != null) ordered.add(g);
      if (ordered.length >= maxGifters) break;
    }

    state = VoiceRecentGiftsState(
      gifters: ordered,
      announcements: announcements,
    );
  }

  void clear() {
    _gifters.clear();
    _gifterOrder.clear();
    state = const VoiceRecentGiftsState();
  }
}

final voiceRecentGiftsProvider =
    NotifierProvider<VoiceRecentGiftsController, VoiceRecentGiftsState>(
  VoiceRecentGiftsController.new,
);

final voiceRecentGiftersListProvider = Provider<List<VoiceRecentGifter>>((ref) {
  return ref.watch(voiceRecentGiftsProvider).gifters;
});

final voiceGiftAnnouncementsProvider =
    Provider<List<VoiceGiftAnnouncement>>((ref) {
  return ref.watch(voiceRecentGiftsProvider).announcements;
});
