part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda hediye soketi/liderlik tablosu bağlama mantığı —
/// [VoiceRoomLiveController]'dan ayrıldı. `part of` — aynı kütüphane;
/// private alan (_giftSocketStarted) ve metotlara erişir, davranış birebir
/// korunur. Not: hediye state'inin çoğu zaten ayrı provider dosyalarında.
extension VoiceRoomGiftControls on VoiceRoomLiveController {
  /// Hediye olayı — sohbet akışına değil; koltuk altı kutu + kayan duyuru.
  void announceGift(LiveGiftEvent ev) {
    ref.read(voiceRecentGiftsProvider.notifier).record(ev);
  }

  Future<void> _loadGiftLeaderboard() async {
    if (_roomKey.isEmpty) return;
    try {
      final entries = await ref
          .read(chatRoomGiftsRemoteProvider)
          .fetchRoomGiftLeaderboard(roomId: _roomKey);
      if (entries.isNotEmpty) {
        ref.read(voiceSessionGiftLeaderboardProvider.notifier).seedFromApi(entries);
      }
    } catch (_) {}
  }

  void _startGiftSocket() {
    if (_roomKey.isEmpty) return;
    if (_giftSocketStarted) {
      VoiceRoomDebugLog.log('socket.subscribe.skip', {'roomId': _roomKey});
      return;
    }
    _giftSocketStarted = true;
    final storage = ref.read(tokenStorageProvider);
    final alt = _roomMeta.slug.trim();
    ref.read(voiceRoomGiftSocketProvider).connect(
          roomId: _roomKey,
          alternateRoomId: alt.isNotEmpty ? alt : null,
          accessToken: storage.readAccess,
          onEvent: (ev) {
            ref.read(voiceRoomGiftRealtimeProvider).publishRemote(ev);
            if (!state.sseConnected) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(true);
            }
          },
          onPresenceSnapshot: applyPresenceSnapshot,
          onDjUpdate: (payload) {
            // SSE bağlıyken DJ olayları yalnızca SSE'den işlenir (çift oynatma önlenir).
            if (state.sseConnected || payload.isEmpty) return;
            _applyRoomVideoPayload(payload);
            unawaited(_applyDjRealtimePayload(payload));
          },
          onMessage: (msg) {
            if (state.sseConnected) return;
            final exists = state.messages.any((m) => m.id == msg.id);
            if (exists) return;
            state = state.copyWith(messages: [...state.messages, msg]);
          },
          onConnectionChanged: (connected) {
            ref.read(voiceRoomDiagnosticProvider.notifier).setSocket(connected);
            if (connected && !state.sseConnected) {
              ref.read(voiceRoomGiftRealtimeProvider).setSocketPreferred(true);
            }
          },
        );
    VoiceRoomDebugLog.log('socket.subscribe', {'roomId': _roomKey});
  }
}
