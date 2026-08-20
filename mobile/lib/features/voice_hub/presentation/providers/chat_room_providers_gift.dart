part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda hediye soketi/liderlik tablosu bağlama mantığı —
/// [VoiceRoomLiveController]'dan ayrıldı. `part of` — aynı kütüphane;
/// private alan (_giftSocketStarted) ve metotlara erişir, davranış birebir
/// korunur. Not: hediye state'inin çoğu zaten ayrı provider dosyalarında.
extension VoiceRoomGiftControls on VoiceRoomLiveController {
  /// Hediye olayı — merkezi gift session (host/guest aynı state).
  void announceGift(LiveGiftEvent ev) {
    if (_roomKey.isEmpty) return;
    ref.read(giftSessionProvider(_roomKey).notifier).onVoiceGiftSent(
          ev,
          source: 'voice_announce',
        );
    ref.read(voiceRecentGiftsProvider.notifier).record(ev);
    try {
      ref.read(voiceSeatGiftFlashProvider(_roomKey).notifier).enqueue(ev);
    } catch (_) {}
    appendGiftChatMessage(ev);
  }

  /// Sohbet alanına hediye sistem mesajı ekler.
  void appendGiftChatMessage(LiveGiftEvent ev) {
    if (_roomKey.isEmpty || ev.jetonAmount <= 0) return;
    final msgId = 'gift-${ev.id}';
    if (state.messages.any((m) => m.id == msgId)) return;
    final sender = ev.senderName.trim().isNotEmpty
        ? ev.senderName.trim()
        : 'Biri';
    final line = GiftSystemMessage.format(ev);
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatRoomMessage(
          id: msgId,
          content: line,
          createdAt: ev.timestamp,
          kind: ChatMessageKind.gift,
          user: ChatRoomUserRef(
            id: ev.senderId ?? sender,
            name: sender,
          ),
        ),
      ],
    );
  }

  Future<void> _loadGiftLeaderboard() async {
    if (_roomKey.isEmpty) return;
    try {
      final gifts = ref.read(chatRoomGiftsRemoteProvider);
      final entries =
          await gifts.fetchRoomGiftLeaderboard(roomId: _roomKey);
      if (entries.isNotEmpty) {
        ref.read(voiceSessionGiftLeaderboardProvider.notifier).seedFromApi(entries);
      }
      final events = await gifts.fetchRoomGiftEvents(roomId: _roomKey);
      if (events.isNotEmpty) {
        ref.read(voiceSeatGiftTotalsProvider.notifier).seedFromEvents(events);
      }
    } catch (_) {}
  }
}
