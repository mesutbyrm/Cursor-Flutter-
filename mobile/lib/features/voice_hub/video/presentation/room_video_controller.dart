import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/voice_room_debug_log.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../music/domain/entities/room_playback_sync.dart';
import '../domain/room_video_socket_events.dart';
import '../domain/room_video_state.dart';
import '../domain/youtube_video_id.dart';

/// Tam ekran video müzik modu — senkron + oynatıcı komutları.
class RoomVideoController extends AutoDisposeFamilyNotifier<RoomVideoState, String> {
  Timer? _positionTicker;

  @override
  RoomVideoState build(String roomKey) {
    ref.onDispose(_stopTicker);
    return const RoomVideoState();
  }

  void applyDjPayload(Map<String, dynamic> payload) {
    if (!RoomVideoSocketEvents.isVideoPayload(payload)) return;
    final sync = RoomVideoSocketEvents.syncFromPayload(payload);
    final action = RoomVideoSocketEvents.actionFromPayload(payload);
    VoiceRoomDebugLog.log('roomVideo.socket', {
      'room': arg,
      'action': action,
      'videoId': sync?.currentVideoId ?? payload['currentVideoId'],
      'playing': sync?.isPlaying ?? payload['playing'],
    });
    _applySync(sync, payload: payload);
  }

  void applyDjState(ChatRoomDjState dj, {RoomPlaybackSync? sync}) {
    final next = RoomVideoState.fromDjAndSync(dj: dj, sync: sync);
    _applyVideoState(next, logTag: 'roomVideo.sync');
  }

  /// Ses modu — yalnızca YouTube IFrame (gizli 1×1); just_audio stream yokken.
  void applyAudioDjState(ChatRoomDjState dj, {RoomPlaybackSync? sync}) {
    final np = dj.nowPlaying;
    final videoId = YoutubeVideoId.fromDj(
      currentVideoId: sync?.currentVideoId ?? np?.resolvedVideoId,
      nowPlayingUrl: np?.youtubeUrl ?? dj.musicUrl,
    );
    if (videoId == null) {
      if (state.hasActiveVideo) {
        VoiceRoomDebugLog.log('roomVideo.closed', {'room': arg});
      }
      state = const RoomVideoState();
      _stopTicker();
      return;
    }
    final playing = sync?.isPlaying ?? dj.playing;
    final next = RoomVideoState(
      videoId: videoId,
      title: np?.title,
      thumbUrl: np?.thumbUrl,
      isPlaying: playing,
      positionMs: sync?.currentPositionMs ?? 0,
      trackStartedAtMs: sync?.trackStartedAtMs,
      nowPlaying: np,
      audioOnly: true,
    );
    _applyVideoState(next, logTag: 'roomVideo.audio');
  }

  void _applyVideoState(RoomVideoState next, {required String logTag}) {
    if (!next.hasActiveVideo) {
      if (state.hasActiveVideo) {
        VoiceRoomDebugLog.log('roomVideo.closed', {'room': arg});
      }
      state = const RoomVideoState();
      _stopTicker();
      return;
    }
    final changed = state.videoId != next.videoId ||
        state.audioOnly != next.audioOnly ||
        state.isPlaying != next.isPlaying ||
        (next.isPlaying &&
            (next.positionMs - state.resolvedPositionMs()).abs() > 3000);
    if (changed || state.title != next.title) {
      VoiceRoomDebugLog.log(logTag, {
        'room': arg,
        'videoId': next.videoId,
        'playing': next.isPlaying,
        'audioOnly': next.audioOnly,
        'positionMs': next.resolvedPositionMs(),
      });
      state = next;
      _syncTicker(next.isPlaying);
    }
  }

  void _applySync(RoomPlaybackSync? sync, {Map<String, dynamic>? payload}) {
    if (sync == null) {
      final action = payload != null
          ? RoomVideoSocketEvents.actionFromPayload(payload)
          : null;
      if (action == RoomVideoSocketEvents.close) {
        state = const RoomVideoState();
        _stopTicker();
      }
      return;
    }
    final videoId = sync.currentVideoId;
    if (videoId == null || videoId.isEmpty) {
      state = const RoomVideoState();
      _stopTicker();
      return;
    }
    state = state.copyWith(
      videoId: videoId,
      isPlaying: sync.isPlaying,
      positionMs: sync.resolvedPositionMs(),
      trackStartedAtMs: sync.trackStartedAtMs,
      clearTrackStartedAt: !sync.isPlaying,
    );
    _syncTicker(sync.isPlaying);
  }

  void _syncTicker(bool playing) {
    // Video modunda yerel saniye ticker'ı WebView'i yeniden yükletmez;
    // konum senkronu sunucu/SSE üzerinden gelir.
    if (!playing || !state.hasActiveVideo) {
      _stopTicker();
    }
  }

  void _stopTicker() {
    _positionTicker?.cancel();
    _positionTicker = null;
  }

  void clear() {
    state = const RoomVideoState();
    _stopTicker();
  }

  /// Soldan sağa kapanma animasyonu — ardından video durumu temizlenir.
  Future<void> dismissAnimated() async {
    if (!state.hasActiveVideo) {
      clear();
      return;
    }
    state = state.copyWith(isPlaying: false, isDismissing: true);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    clear();
  }
}

final roomVideoControllerProvider = AutoDisposeNotifierProviderFamily<
    RoomVideoController, RoomVideoState, String>(RoomVideoController.new);
