import '../../domain/entities/voice_room_realtime_event.dart';
import 'chat_room_providers.dart';

/// Zorunlu oturum çıkışı sinyalleri — chat/presence güncellemelerinde tetiklenmez.
typedef VoiceRoomExitSignalsSlice = ({
  String? error,
  bool selfInRoom,
  int presenceCount,
  int realtimeEventCount,
  VoiceRoomRealtimeKind? headEventKind,
  String? headEventMessage,
});

VoiceRoomExitSignalsSlice voiceRoomExitSignalsSlice(VoiceRoomLiveState state) {
  final head = state.realtimeEvents.isEmpty ? null : state.realtimeEvents.first;
  return (
    error: state.error,
    selfInRoom: state.selfInRoom,
    presenceCount: state.presence.length,
    realtimeEventCount: state.realtimeEvents.length,
    headEventKind: head?.kind,
    headEventMessage: head?.message,
  );
}

/// Moderasyon toast / kick uyarısı.
typedef VoiceRoomModerationSignalsSlice = ({
  String? moderationToast,
  String? kickStrikeWarning,
  int kickStrikeCount,
});

VoiceRoomModerationSignalsSlice voiceRoomModerationSignalsSlice(
  VoiceRoomLiveState state,
) =>
    (
      moderationToast: state.moderationToast,
      kickStrikeWarning: state.kickStrikeWarning,
      kickStrikeCount: state.kickStrikeCount,
    );

/// Bekleyen müzik arama sheet tetikleyicisi.
typedef VoiceRoomMusicSearchRequestSlice = ({
  String? query,
  bool skipPayment,
});

VoiceRoomMusicSearchRequestSlice voiceRoomMusicSearchRequestSlice(
  VoiceRoomLiveState state,
) =>
    (
      query: state.pendingMusicSearchQuery,
      skipPayment: state.pendingMusicSearchSkipPayment,
    );

/// DJ çalma durumu — müzik başladığında mic otomatik kapatma (RTC).
typedef VoiceRoomDjPlaybackSignalsSlice = ({
  bool playing,
  String? nowPlayingVideoId,
});

VoiceRoomDjPlaybackSignalsSlice voiceRoomDjPlaybackSignalsSlice(
  VoiceRoomLiveState state,
) =>
    (
      playing: state.dj.playing,
      nowPlayingVideoId: state.dj.nowPlaying?.videoIdField,
    );

/// Konuşma yetkisi mic gate — yalnızca self presence + izinler.
typedef VoiceRoomMicGateSlice = ({
  String? selfUserId,
  bool selfCanSpeak,
});
