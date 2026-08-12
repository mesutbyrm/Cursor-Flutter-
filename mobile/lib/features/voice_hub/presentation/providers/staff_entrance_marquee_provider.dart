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
  /// Hediye duyuruları artık [GlobalGiftOverlay] ile gösterilir; burada atlanır.
  void enqueue(String raw, {String? roomName}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return;
    if (VoiceOfficialJoin.isHomeBannerGiftAnnouncement(trimmed)) return;
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

  /// 1000+ jeton hediye — global overlay kullanır; marquee'ye yazılmaz.
  void enqueueBigGift({
    required String senderName,
    required String receiverName,
    required int jeton,
    String? giftName,
  }) {
    // Legacy çağrılar — StaffEntranceMarquee artık hediye göstermez.
  }

  /// Şanslı hediye JACKPOT — site geneli kayan duyuru.
  void enqueueLuckyJackpot({
    required String userName,
    required String giftName,
    required int multiplier,
    required int wonJetons,
  }) {
    final user = userName.trim().isEmpty ? 'Biri' : userName.trim();
    final gift = giftName.trim().isEmpty ? 'Talih Kutusu' : giftName.trim();
    enqueue(
      '👑 JACKPOT! $user $gift ile ×$multiplier kazandı — $wonJetons jeton!',
    );
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
