import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/chat_room_message.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../domain/entities/voice_room_seat_slot.dart';
import '../../domain/entities/voice_room_realtime_event.dart';
import 'chat_room_providers.dart';

/// Parçalı oda state — heartbeat/gift/chat/seat ayrı rebuild.
typedef VoiceRoomChatSlice = ({
  List<ChatRoomMessage> messages,
  String? pinnedAnnouncement,
  bool isAnyoneTyping,
  List<String> typingUsers,
});

typedef VoiceRoomSeatSlice = ({
  List<VoiceRoomSeatSlot> seatSlots,
  List<ChatRoomPresence> presence,
});

typedef VoiceRoomMusicSlice = ChatRoomDjState;

final voiceRoomChatSliceProvider = Provider.autoDispose
    .family<VoiceRoomChatSlice, String>((ref, roomKey) {
  return ref.watch(
    voiceRoomLiveProvider(roomKey).select(
      (s) => (
        messages: s.messages,
        pinnedAnnouncement: s.pinnedAnnouncement,
        isAnyoneTyping: s.isAnyoneTyping,
        typingUsers: s.typingUsers,
      ),
    ),
  );
});

final voiceRoomSeatSliceProvider = Provider.autoDispose
    .family<VoiceRoomSeatSlice, String>((ref, roomKey) {
  return ref.watch(
    voiceRoomLiveProvider(roomKey).select(
      (s) => (
        seatSlots: s.seatSlots,
        presence: s.presence,
      ),
    ),
  );
});

final voiceRoomMusicSliceProvider = Provider.autoDispose
    .family<VoiceRoomMusicSlice, String>((ref, roomKey) {
  return ref.watch(voiceRoomLiveProvider(roomKey).select((s) => s.dj));
});

final voiceRoomGiftEventsProvider = Provider.autoDispose
    .family<List<VoiceRoomRealtimeEvent>, String>((ref, roomKey) {
  return ref.watch(
    voiceRoomLiveProvider(roomKey).select((s) => s.realtimeEvents),
  );
});

String voiceRoomSpeakingSignature(List<ChatRoomPresence> presence) {
  final ids = [for (final p in presence) if (p.isSpeaking) p.id]..sort();
  return ids.join('|');
}

/// Konuşma göstergesi — yalnızca speaking id seti değişince rebuild.
final voiceRoomSpeakingSignatureProvider = Provider.autoDispose
    .family<String, String>((ref, roomKey) {
  return ref.watch(
    voiceRoomLiveProvider(roomKey).select(
      (s) => voiceRoomSpeakingSignature(s.presence),
    ),
  );
});

final voiceRoomConnectionSliceProvider = Provider.autoDispose
    .family<({bool loading, bool sseConnected, bool selfInRoom}), String>(
  (ref, roomKey) {
    return ref.watch(
      voiceRoomLiveProvider(roomKey).select(
        (s) => (
          loading: s.loading,
          sseConnected: s.sseConnected,
          selfInRoom: s.selfInRoom,
        ),
      ),
    );
  },
);
