import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../data/services/voice_room_debug_log.dart';
import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';
import '../../video/domain/youtube_video_id.dart';
import '../audio/voice_room_music_audio_session.dart';
import 'voice_room_music_control_delegate.dart';

/// Oda müziği — tek YouTube IFrame oynatıcı (stream / yt-dlp yok).
class VoiceRoomDjPlayer {
  YoutubePlayerController? _controller;
  StreamSubscription<YoutubePlayerValue>? _valueSub;
  StreamSubscription<YoutubeVideoState>? _videoStateSub;
  Timer? _progressTimer;
  String? _loadedVideoId;
  var _showVideo = false;
  var _muted = false;
  void Function()? _onTrackComplete;
  void Function()? _onUnplayable;

  final ValueNotifier<VoiceRoomDjPlayback> playback =
      ValueNotifier(const VoiceRoomDjPlayback());
  final ValueNotifier<VoiceRoomMusicDiagnostics> diagnostics =
      ValueNotifier(const VoiceRoomMusicDiagnostics());
  final ValueNotifier<VoiceRoomEmbedUiState> embedUi =
      ValueNotifier(const VoiceRoomEmbedUiState());

  VoiceRoomMusicControlDelegate? controlDelegate;

  YoutubePlayerController get youtubeController => _ensureController();

  bool get showVideo => _showVideo;

  String? get loadedVideoId => _loadedVideoId;

  void Function()? get onTrackComplete => _onTrackComplete;

  set onTrackComplete(void Function()? value) => _onTrackComplete = value;

  set onUnplayable(void Function()? value) => _onUnplayable = value;

  YoutubePlayerController _ensureController() {
    final existing = _controller;
    if (existing != null) return existing;

    final ctrl = YoutubePlayerController(
      params: const YoutubePlayerParams(
        mute: false,
        showControls: false,
        showFullscreenButton: false,
        enableCaption: false,
        playsInline: true,
        strictRelatedVideos: true,
        loop: false,
      ),
    );
    _controller = ctrl;
    _valueSub = ctrl.listen(_onYoutubeValue);
    _videoStateSub = ctrl.videoStateStream.listen(_onVideoState);
    return ctrl;
  }

  void _onYoutubeValue(YoutubePlayerValue value) {
    if (value.hasError) {
      _handleUnplayable(value.error);
      return;
    }

    final playing = value.playerState == PlayerState.playing ||
        value.playerState == PlayerState.buffering;
    playback.value = playback.value.copyWith(playing: playing);

    if (value.playerState == PlayerState.ended) {
      VoiceRoomDebugLog.log('music.embed.ended', {'videoId': _loadedVideoId});
      _onTrackComplete?.call();
    }
  }

  void _onVideoState(YoutubeVideoState state) {
    final durationMs = _controller?.metadata.duration.inMilliseconds ?? 0;
    playback.value = playback.value.copyWith(
      position: state.position,
      duration: durationMs > 0
          ? Duration(milliseconds: durationMs)
          : playback.value.duration,
    );
  }

  void _handleUnplayable(Object? error) {
    VoiceRoomDebugLog.musicError(phase: 'embed.unplayable', error: error);
    embedUi.value = embedUi.value.copyWith(unplayable: true);
    diagnostics.value = diagnostics.value.copyWith(
      lastError: 'Bu şarkı çalınamıyor',
      lastPhase: 'unplayable',
    );
    unawaited(_controller?.pauseVideo());
    _onUnplayable?.call();
  }

  void clearUnplayable() {
    embedUi.value = embedUi.value.copyWith(unplayable: false);
  }

  /// SSE / DJ senkron — `videoId` + `startSeconds` (elapsedSeconds).
  Future<bool> sync({
    String? musicUrl,
    String? resolveSeed,
    String? fallbackYoutubeUrl,
    MusicQueueItem? nowPlaying,
    required bool playing,
    bool muted = false,
    String? serverStreamUrl,
    String? preResolvedStream,
    Duration? startPosition,
    String? videoId,
    bool withVideo = false,
  }) async {
    _muted = muted;
    _showVideo = withVideo;

    if (!playing) {
      await stop();
      return false;
    }

    final id = YoutubeVideoId.normalize(
          videoId ??
              nowPlaying?.resolvedVideoId ??
              ChatRoomDjState.videoIdFromLoose(
                musicUrl ?? serverStreamUrl ?? fallbackYoutubeUrl ?? '',
              ),
        ) ??
        YoutubeVideoId.normalize(nowPlaying?.youtubeUrl);

    if (id == null || id.isEmpty) {
      VoiceRoomDebugLog.musicError(
        phase: 'embed.missing_video_id',
        url: musicUrl,
      );
      await stop();
      return false;
    }

    await VoiceRoomMusicAudioSession.ensureConfigured();
    await VoiceRoomMusicAudioSession.activateForPlayback();

    final startSec =
        (startPosition?.inSeconds ?? 0).toDouble().clamp(0.0, 86400.0);
    final ctrl = _ensureController();

    embedUi.value = VoiceRoomEmbedUiState(
      showVideo: withVideo,
      videoId: id,
      unplayable: false,
    );

    if (_loadedVideoId == id) {
      if (muted) {
        await ctrl.mute();
      } else {
        await ctrl.unMute();
      }
      final currentSec = playback.value.position.inSeconds.toDouble();
      if ((startSec - currentSec).abs() > 2.5) {
        await ctrl.seekTo(seconds: startSec.toDouble(), allowSeekAhead: true);
      }
      if (ctrl.value.playerState != PlayerState.playing &&
          ctrl.value.playerState != PlayerState.buffering) {
        await ctrl.playVideo();
      }
      diagnostics.value = diagnostics.value.copyWith(
        playbackSource: 'embed:$id',
        isPlaying: true,
        muted: muted,
        lastPhase: 'embed_resync',
      );
      return true;
    }

    _loadedVideoId = id;
    clearUnplayable();
    VoiceRoomDebugLog.log('music.embed.load', {
      'videoId': id,
      'startSec': startSec,
      'withVideo': withVideo,
    });

    await ctrl.loadVideoById(videoId: id, startSeconds: startSec.toDouble());
    if (muted) {
      await ctrl.mute();
    } else {
      await ctrl.unMute();
    }

    diagnostics.value = diagnostics.value.copyWith(
      playbackSource: 'embed:$id',
      isPlaying: true,
      muted: muted,
      lastPhase: 'embed_load',
      serverMusicUrl: musicUrl,
    );
    return true;
  }

  Future<bool> playServerStream({
    required String streamUrl,
    required bool playing,
    Duration startPosition = Duration.zero,
    MusicQueueItem? nowPlaying,
    bool muted = false,
    String? videoId,
  }) {
    return sync(
      musicUrl: streamUrl,
      nowPlaying: nowPlaying,
      playing: playing,
      muted: muted,
      startPosition: startPosition,
      videoId: videoId,
      withVideo: nowPlaying?.isVideoRequest == true,
    );
  }

  Future<void> pauseLocal() async {
    await _controller?.pauseVideo();
    playback.value = playback.value.copyWith(playing: false);
  }

  Future<void> resumeLocal() async {
    await _controller?.playVideo();
  }

  Future<void> seekToStart() async {
    await _controller?.seekTo(seconds: 0, allowSeekAhead: true);
  }

  Future<bool> setMuted(bool muted) async {
    _muted = muted;
    final ctrl = _controller;
    if (ctrl == null) return true;
    if (muted) {
      await ctrl.mute();
    } else {
      await ctrl.unMute();
    }
    diagnostics.value = diagnostics.value.copyWith(muted: muted);
    return true;
  }

  /// Web müzik barı ses kaydırıcısı — 0 = mute, >0 = unmute.
  Future<void> setVolumeLevel(double level) async {
    await setMuted(level <= 0.01);
  }

  Future<void> stop() async {
    _progressTimer?.cancel();
    _loadedVideoId = null;
    _showVideo = false;
    embedUi.value = const VoiceRoomEmbedUiState();
    final ctrl = _controller;
    if (ctrl != null) {
      await ctrl.pauseVideo();
      await ctrl.stopVideo();
    }
    playback.value = const VoiceRoomDjPlayback();
    diagnostics.value = diagnostics.value.copyWith(
      isPlaying: false,
      lastPhase: 'stopped',
    );
  }

  Future<void> shutdown() async {
    await stop();
    await _valueSub?.cancel();
    _valueSub = null;
    await _videoStateSub?.cancel();
    _videoStateSub = null;
    await _controller?.close();
    _controller = null;
    _onTrackComplete = null;
    _onUnplayable = null;
  }

  void dispose() {
    unawaited(shutdown());
    playback.dispose();
    diagnostics.dispose();
    embedUi.dispose();
  }
}

class VoiceRoomEmbedUiState {
  const VoiceRoomEmbedUiState({
    this.showVideo = false,
    this.videoId,
    this.unplayable = false,
  });

  final bool showVideo;
  final String? videoId;
  final bool unplayable;

  VoiceRoomEmbedUiState copyWith({
    bool? showVideo,
    String? videoId,
    bool clearVideoId = false,
    bool? unplayable,
  }) {
    return VoiceRoomEmbedUiState(
      showVideo: showVideo ?? this.showVideo,
      videoId: clearVideoId ? null : (videoId ?? this.videoId),
      unplayable: unplayable ?? this.unplayable,
    );
  }
}

class VoiceRoomDjPlayback {
  const VoiceRoomDjPlayback({
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
  });

  final Duration position;
  final Duration duration;
  final bool playing;

  VoiceRoomDjPlayback copyWith({
    Duration? position,
    Duration? duration,
    bool? playing,
  }) {
    return VoiceRoomDjPlayback(
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playing: playing ?? this.playing,
    );
  }

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  Duration get remaining {
    if (duration <= position) return Duration.zero;
    return duration - position;
  }
}

/// Mini player altında gösterilen oynatma teşhis bilgisi.
class VoiceRoomMusicDiagnostics {
  const VoiceRoomMusicDiagnostics({
    this.serverMusicUrl,
    this.playbackSource,
    this.resolvedStreamUrl,
    this.processingState,
    this.isPlaying,
    this.muted,
    this.lastError,
    this.lastPhase,
  });

  final String? serverMusicUrl;
  final String? playbackSource;
  final String? resolvedStreamUrl;
  final String? processingState;
  final bool? isPlaying;
  final bool? muted;
  final String? lastError;
  final String? lastPhase;

  VoiceRoomMusicDiagnostics copyWith({
    String? serverMusicUrl,
    String? playbackSource,
    String? resolvedStreamUrl,
    String? processingState,
    bool? isPlaying,
    bool? muted,
    String? lastError,
    String? lastPhase,
  }) {
    return VoiceRoomMusicDiagnostics(
      serverMusicUrl: serverMusicUrl ?? this.serverMusicUrl,
      playbackSource: playbackSource ?? this.playbackSource,
      resolvedStreamUrl: resolvedStreamUrl ?? this.resolvedStreamUrl,
      processingState: processingState ?? this.processingState,
      isPlaying: isPlaying ?? this.isPlaying,
      muted: muted ?? this.muted,
      lastError: lastError ?? this.lastError,
      lastPhase: lastPhase ?? this.lastPhase,
    );
  }
}
