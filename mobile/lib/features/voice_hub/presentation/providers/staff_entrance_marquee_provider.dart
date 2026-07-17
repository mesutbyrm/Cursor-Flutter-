import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/voice_official_join.dart';

/// Yetkili giriş duyurusu — sayfa üstünde geçici kayan şerit (kalıcı banner değil).
class StaffEntranceMarqueeState {
  const StaffEntranceMarqueeState({this.message});

  final String? message;

  StaffEntranceMarqueeState copyWith({String? message, bool clear = false}) {
    return StaffEntranceMarqueeState(
      message: clear ? null : (message ?? this.message),
    );
  }
}

class StaffEntranceMarqueeNotifier extends Notifier<StaffEntranceMarqueeState> {
  final _seen = <String>{};
  Timer? _clearTimer;

  @override
  StaffEntranceMarqueeState build() {
    ref.onDispose(() => _clearTimer?.cancel());
    return const StaffEntranceMarqueeState();
  }

  /// Sağdan sola kayan şerit — aynı metin oturumda bir kez.
  void enqueue(String raw, {String? roomName}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    final line = VoiceOfficialJoin.isHomeBannerGiftAnnouncement(trimmed)
        ? (trimmed.startsWith('📣') ? trimmed : '📣 $trimmed')
        : VoiceOfficialJoin.formatEntranceBanner(trimmed, roomName: roomName);
    if (line.isEmpty) return;
    final key = VoiceOfficialJoin.entranceDedupeKey(line, roomName: roomName);
    if (!_seen.add(key)) return;
    _clearTimer?.cancel();
    state = StaffEntranceMarqueeState(message: line);
    _clearTimer = Timer(const Duration(seconds: 12), () {
      state = const StaffEntranceMarqueeState();
    });
  }

  /// 1000+ jeton hediye duyurusu — site geneli kayan şerit.
  void enqueueBigGift({
    required String senderName,
    required String receiverName,
    required int jeton,
    String? giftName,
  }) {
    if (jeton < 1000) return;
    final sender = senderName.trim().isEmpty ? 'Biri' : senderName.trim();
    final receiver =
        receiverName.trim().isEmpty ? 'birine' : receiverName.trim();
    final gift = giftName?.trim();
    final line = (gift != null && gift.isNotEmpty)
        ? '$sender $receiver kullanıcısına $gift hediye etti! 💝 ($jeton jeton)'
        : '$sender $receiver hediye etti! 💝 ($jeton jeton)';
    enqueue(line);
  }

  void clear() {
    _clearTimer?.cancel();
    state = const StaffEntranceMarqueeState();
  }
}

final staffEntranceMarqueeProvider =
    NotifierProvider<StaffEntranceMarqueeNotifier, StaffEntranceMarqueeState>(
  StaffEntranceMarqueeNotifier.new,
);
