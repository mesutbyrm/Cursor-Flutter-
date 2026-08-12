import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice_hub/music/domain/song_playback_fields.dart';

/// Canlı yayın müzik videosu — yalnızca gerçek `videoUrl` / stream.
class LiveRoomMusicState extends Equatable {
  const LiveRoomMusicState({
    this.videoUrl,
    this.title,
    this.trackKey,
    this.playing = false,
    this.hasError = false,
  });

  final String? videoUrl;
  final String? title;
  final String? trackKey;
  final bool playing;
  final bool hasError;

  bool get hasActiveVideo =>
      videoUrl != null && videoUrl!.trim().isNotEmpty && !hasError;

  LiveRoomMusicState copyWith({
    String? videoUrl,
    String? title,
    String? trackKey,
    bool? playing,
    bool? hasError,
    bool clearVideo = false,
  }) {
    return LiveRoomMusicState(
      videoUrl: clearVideo ? null : (videoUrl ?? this.videoUrl),
      title: title ?? this.title,
      trackKey: trackKey ?? this.trackKey,
      playing: playing ?? this.playing,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  List<Object?> get props => [videoUrl, title, trackKey, playing, hasError];
}

class LiveRoomMusicController extends AutoDisposeFamilyNotifier<LiveRoomMusicState, String> {
  String? _lastTrackKey;

  @override
  LiveRoomMusicState build(String streamId) {
    ref.onDispose(() {
      _lastTrackKey = null;
    });
    return const LiveRoomMusicState();
  }

  void applyDjPayload(Map<String, dynamic> payload) {
    final fields = SongPlaybackFields.parseQuiet(payload);
    if (!fields.isVideoRequest) {
      if (state.hasActiveVideo) {
        state = const LiveRoomMusicState();
      }
      return;
    }

    final videoUrl = fields.resolvedVideoStreamUrl;
    if (videoUrl == null || videoUrl.isEmpty) {
      state = state.copyWith(hasError: true, playing: false);
      return;
    }

    final playing = payload['playing'] == true ||
        payload['isPlaying'] == true ||
        fields.isVideoRequest;
    final trackKey = payload['queueId']?.toString() ??
        fields.videoId ??
        videoUrl;
    if (_lastTrackKey == trackKey && state.videoUrl == videoUrl) {
      if (state.playing != playing) {
        state = state.copyWith(playing: playing);
      }
      return;
    }
    _lastTrackKey = trackKey;
    state = LiveRoomMusicState(
      videoUrl: videoUrl,
      title: fields.title,
      trackKey: trackKey,
      playing: playing,
    );
  }

  void stop() {
    _lastTrackKey = null;
    state = const LiveRoomMusicState();
  }

  void markPlaybackError() {
    state = state.copyWith(hasError: true, playing: false);
  }
}

final liveRoomMusicProvider = AutoDisposeNotifierProviderFamily<
    LiveRoomMusicController, LiveRoomMusicState, String>(
  LiveRoomMusicController.new,
);
