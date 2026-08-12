part of 'chat_room_providers.dart';

/// DJ / SongQueue SSE senkronu — [VoiceRoomLiveController] monolith'ten ayrıldı.
mixin VoiceRoomDjSyncMixin on AutoDisposeFamilyNotifier<VoiceRoomLiveState, String> {
  VoiceRoomLiveController get _live => this as VoiceRoomLiveController;

  void _syncRoomSongBloc() {
    final key = _live._roomKey;
    if (key.isEmpty) return;
    ref.read(roomSongBlocProvider(key)).add(RoomSongJoinSync(key));
  }

  Future<void> _handleMusicStoppedFromSse() async {
    final key = _live._roomKey;
    VoiceRoomDebugLog.log('music.sse.stopped', {'room': key});
    await ref.read(voiceRoomDjPlayerProvider).stop();
    ref.read(voiceRoomMusicSessionProvider.notifier).dismissFromServerStop();
    ref.read(roomVideoControllerProvider(key).notifier).clear();
    state = state.copyWith(
      dj: state.dj.copyWith(
        playing: false,
        clearNowPlaying: true,
        clearMusicUrl: true,
        musicQueue: const [],
      ),
      musicLikeCount: 0,
    );
    _live._lastDjPlaybackSignature = '';
  }

  Future<void> _applyDjRealtimePayload(Map<String, dynamic> payload) async {
    final key = _live._roomKey;
    final map = unwrapVoiceSseDjPayload(payload);
    final signal = voiceSseMusicSignal(map);
    if (signal == VoiceSseMusicSignal.stopped) {
      await _handleMusicStoppedFromSse();
      return;
    }
    if (signal == VoiceSseMusicSignal.started) {
      ref.read(voiceRoomMusicSessionProvider.notifier).onMusicStartedFromServer();
      ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
      VoiceRoomDebugLog.log('music.sse.started', {
        'room': key,
        'musicUrl': map['musicUrl']?.toString(),
      });
    }
    final likes = voiceSseLikeCount(map);
    final np = map['nowPlaying'];
    String? title;
    String? eventVideoId;
    if (np is Map) {
      title = np['title']?.toString();
      eventVideoId = np['videoId']?.toString() ?? np['youtubeUrl']?.toString();
    }
    eventVideoId ??= map['currentVideoId']?.toString() ?? map['videoId']?.toString();
    VoiceRoomDebugLog.djUpdate(
      roomId: key,
      playing: voiceSseDjIsPlaying(map),
      musicUrl: map['musicUrl']?.toString(),
      videoId: eventVideoId,
      title: title,
      source: map['type']?.toString() ?? 'realtime',
    );
    VoiceRoomDebugLog.log('music.realtime.recv', {
      'playing': map['playing'],
      'isPlaying': map['isPlaying'],
      'hasUrl': map['musicUrl'] != null,
      'hasQueue': map['queue'] != null,
      'type': map['type'],
    });
    var dj = state.dj;
    final isPlaying = voiceSseDjIsPlaying(map);
    if (map.containsKey('playing') ||
        map.containsKey('isPlaying') ||
        isPlaying) {
      dj = dj.copyWith(playing: isPlaying);
    }
    if (map['musicUrl'] != null) {
      final url = map['musicUrl'].toString().trim();
      if (url.isNotEmpty) dj = dj.copyWith(musicUrl: url);
    }
    if (map['nowPlaying'] is Map) {
      dj = dj.copyWith(
        nowPlaying: _live._mergeNowPlayingFromSse(
          Map<String, dynamic>.from(map['nowPlaying'] as Map),
          previous: state.dj.nowPlaying,
        ),
        playing: isPlaying || dj.playing,
      );
    } else if (isPlaying && dj.nowPlaying == null) {
      final queueRaw = map['queue'] ?? map['musicQueue'];
      if (queueRaw is List && queueRaw.isNotEmpty && queueRaw.first is Map) {
        dj = dj.copyWith(
          nowPlaying: MusicQueueItem.fromJson(
            Map<String, dynamic>.from(queueRaw.first as Map),
          ),
          playing: true,
        );
      }
    }
    final queueRaw = map['queue'] ?? map['musicQueue'];
    if (queueRaw is List) {
      final queue = queueRaw
          .whereType<Map>()
          .map((e) => MusicQueueItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      final songActive =
          key.isNotEmpty && ref.read(roomSongBlocProvider(key)).state.hasTrack;
      final musicActive = dj.playing || state.dj.playing || songActive;
      if (queue.isNotEmpty || !musicActive) {
        dj = dj.copyWith(musicQueue: queue);
      } else if (state.dj.musicQueue.isNotEmpty) {
        dj = dj.copyWith(musicQueue: state.dj.musicQueue);
      }
    }
    if (map['djUserIds'] is List) {
      final ids = (map['djUserIds'] as List)
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      dj = _live._enrichDjUsers(
        dj.copyWith(
          djUsers: ids
              .map(
                (id) => dj.djUsers.where((u) => u.id == id).firstOrNull ??
                    ChatRoomUserRef(
                      id: id,
                      name: _live._djChatLabel(id) ?? 'DJ',
                      chatRole: 'dj',
                    ),
              )
              .toList(),
        ),
        state.presence,
      );
    } else if (map['djUsers'] is List) {
      final users = (map['djUsers'] as List)
          .whereType<Map>()
          .map(
            (e) => ChatRoomUserRef(
              id: (e['id'] ?? e['userId'] ?? '').toString(),
              name: (e['name'] ?? e['displayName'] ?? 'DJ').toString(),
              nickname: e['nickname']?.toString(),
              image: e['image']?.toString() ?? e['avatarUrl']?.toString(),
              chatRole: (e['chatRole'] ?? 'dj').toString(),
            ),
          )
          .where((u) => u.id.isNotEmpty)
          .toList();
      if (users.isNotEmpty) {
        dj = dj.copyWith(djUsers: users);
      }
    } else if (state.dj.djUsers.isNotEmpty) {
      dj = dj.copyWith(djUsers: state.dj.djUsers);
    }
    _live._commitDjUi(dj);
    if (likes != null) {
      state = state.copyWith(musicLikeCount: likes);
    }
    final blocEv = RoomSongBloc.eventFromSse(map);
    if (blocEv != null && key.isNotEmpty) {
      ref.read(roomSongBlocProvider(key)).add(blocEv);
    }
    final sync = RoomPlaybackSync.fromPayload(map);
    final ui = ref.read(voiceRoomUiProvider);
    final sig = _live._djPlaybackSignature(dj, muted: ui.effectiveMusicMuted);
    final wantsPlay = (dj.playing || sync.isPlaying) &&
        _live._hasDjPlayableSource(
          dj,
          sync: sync,
          videoId: eventVideoId,
        );
    final isVideoRequest = dj.nowPlaying?.isVideoRequest == true;
    final playerActive = ref.read(voiceRoomDjPlayerProvider).playback.value.playing;
    final videoActive = key.isNotEmpty &&
        ref.read(roomVideoControllerProvider(key)).hasActiveVideo;
    // RoomSongBloc her modda parça tutar; yalnızca video iframe aktifken
    // just_audio yolunu atla. Ses modunda oynatıcı durmuşsa SSE tekrarında yeniden dene.
    final needsLocalPlayback = wantsPlay &&
        (isVideoRequest ? !videoActive : !playerActive);
    if (sig != _live._lastDjPlaybackSignature || needsLocalPlayback) {
      unawaited(_live._playDjInBackground(dj, sync: sync));
      return;
    }
    if (!wantsPlay && (map['queue'] != null || map['musicQueue'] != null)) {
      unawaited(_syncMusicFromServerIfNeeded(force: true));
    }
    if (!sync.isPlaying) {
      return;
    }
    _syncRoomSongBloc();
  }

  ChatRoomDjState _djWithQueuePlaybackFallback(ChatRoomDjState dj) {
    if (dj.playing) return dj;
    if (dj.musicQueue.isEmpty && dj.nowPlaying == null) return dj;
    if (!_live._hasDjPlayableSource(dj)) return dj;
    return dj.copyWith(playing: true);
  }

  Future<ChatRoomDjState> _applyDjPlayback(
    ChatRoomDjState dj, {
    RoomPlaybackSync? sync,
  }) async {
    final key = _live._roomKey;
    final ui = ref.read(voiceRoomUiProvider);
    final muted = ui.effectiveMusicMuted;
    final session = ref.read(voiceRoomMusicSessionProvider);
    final player = ref.read(voiceRoomDjPlayerProvider);

    if (session.userDismissedPlayer) {
      _live._lastDjPlaybackSignature =
          _live._djPlaybackSignature(dj, muted: muted);
      return dj;
    }

    if (!dj.musicEnabled) {
      _live._lastDjPlaybackSignature =
          _live._djPlaybackSignature(dj, muted: muted);
      return dj.copyWith(playing: false);
    }

    final effectiveDj = dj;
    final isVideoMode = effectiveDj.nowPlaying?.isVideoRequest == true;
    final videoId = YoutubeVideoId.fromDj(
      currentVideoId: sync?.currentVideoId,
      nowPlayingUrl: effectiveDj.nowPlaying?.youtubeUrl,
    );
    final shouldPlay = (sync?.isPlaying ?? effectiveDj.playing) &&
        _live._hasDjPlayableSource(effectiveDj, sync: sync, videoId: videoId);
    final sig = _live._djPlaybackSignature(effectiveDj, muted: muted);
    final startPosition = sync != null
        ? Duration(
            milliseconds: sync.resolvedPositionMs().clamp(0, 86400000),
          )
        : Duration.zero;

    if (shouldPlay) {
      await VoiceRoomMusicAudioSession.activateForPlayback();
      _syncRoomSongBloc();

      if (isVideoMode) {
        VoiceRoomMusicPipelineLog.songEvent(
          event: 'starting_video',
          parsedVideoId: videoId,
          parsedMusicUrl: sync?.streamUrl ?? effectiveDj.musicUrl,
        );
        _live._syncRoomVideo(effectiveDj, sync: sync);
        final musicUrl = sync?.streamUrl ?? effectiveDj.musicUrl;
        final audioStarted = await player.sync(
          musicUrl: musicUrl,
          resolveSeed: effectiveDj.playbackResolveSeed,
          fallbackYoutubeUrl: effectiveDj.youtubeFallbackSource,
          nowPlaying: effectiveDj.nowPlaying,
          playing: true,
          muted: muted,
          serverStreamUrl: musicUrl,
          startPosition: startPosition,
        );
        if (!audioStarted) {
          VoiceRoomMusicPipelineLog.songEvent(
            event: 'player_error',
            detail: 'video_mode audio sync returned false',
            parsedMusicUrl: musicUrl,
          );
        }
      } else {
        VoiceRoomMusicPipelineLog.songEvent(
          event: 'starting_audio',
          parsedMusicUrl: sync?.streamUrl ?? effectiveDj.musicUrl,
          parsedVideoId: videoId,
        );
        if (key.isNotEmpty) {
          ref.read(roomVideoControllerProvider(key).notifier).clear();
        }
        final musicUrl = sync?.streamUrl ?? effectiveDj.musicUrl;
        final started = await player.sync(
          musicUrl: musicUrl,
          resolveSeed: effectiveDj.playbackResolveSeed,
          fallbackYoutubeUrl: effectiveDj.youtubeFallbackSource,
          nowPlaying: effectiveDj.nowPlaying,
          playing: true,
          muted: muted,
          serverStreamUrl: musicUrl,
          startPosition: startPosition,
        );
        if (started) {
          VoiceRoomMusicPipelineLog.songEvent(event: 'player_ready');
        } else {
          VoiceRoomMusicPipelineLog.songEvent(
            event: 'player_error',
            detail: 'just_audio sync returned false',
            parsedMusicUrl: musicUrl,
          );
        }
      }

      await _syncTrtcMusicPublish(
        playing: true,
        videoId: videoId,
        sync: sync,
        dj: effectiveDj,
      );
      _live._lastDjPlaybackSignature = sig;
      return effectiveDj;
    }

    await _syncTrtcMusicPublish(
      playing: false,
      videoId: videoId,
      sync: sync,
      dj: effectiveDj,
    );
    await player.stop();
    if (key.isNotEmpty) {
      ref.read(roomVideoControllerProvider(key).notifier).clear();
    }

    _live._lastDjPlaybackSignature =
        _live._djPlaybackSignature(effectiveDj, muted: muted);
    return effectiveDj.copyWith(playing: false);
  }

  Future<void> _syncMusicFromServer({bool optimisticUi = true}) async {
    final key = _live._roomKey;
    if (key.isEmpty) return;
    try {
      VoiceRoomDebugLog.log('music.sync.start', {'room': key});
      final pair = await Future.wait([
        ref.read(chatRoomRemoteProvider).fetchDj(
          key,
          alternateKey: _live._musicAlternateKey,
        ),
        ref.read(chatRoomRemoteProvider).fetchMusicQueue(
          key,
          alternateKey: _live._musicAlternateKey,
        ),
      ]);
      var dj = _live._mergeMusicQueueRecord(
        pair[0] as ChatRoomDjState,
        pair[1]
            as ({
              List<MusicQueueItem> queue,
              int cost,
              int videoRequestCost,
              int maxMusicQueue,
              bool musicEnabled,
              MusicQueueItem? nowPlaying,
              bool? playing,
              bool? canRequestMusic,
              String? musicUrl,
            }),
      );
      if (optimisticUi) {
        _live._commitDjUi(dj);
        unawaited(_live._playDjInBackground(dj));
      } else {
        dj = await _applyDjPlayback(dj);
        state = state.copyWith(dj: dj, clearError: true);
      }
      invalidateWalletCacheFromRef(ref);
      VoiceRoomDebugLog.log('music.sync.ok', {
        'playing': dj.playing,
        'queue': dj.musicQueue.length,
      });
    } catch (e) {
      VoiceRoomDebugLog.log('music.sync.fail', {'error': '$e'});
    }
  }

  Future<void> _syncMusicFromServerIfNeeded({bool force = false}) async {
    final key = _live._roomKey;
    if (!force) {
      final songActive =
          key.isNotEmpty && ref.read(roomSongBlocProvider(key)).state.hasTrack;
      if (songActive) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (key.isNotEmpty &&
          ref.read(roomSongBlocProvider(key)).state.hasTrack) {
        return;
      }
    }
    await _syncMusicFromServer();
  }

  /// DJ / oda sahibi — müziği TRTC uplink'e karıştır (uzak dinleyiciler).
  Future<void> _syncTrtcMusicPublish({
    required bool playing,
    required String? videoId,
    RoomPlaybackSync? sync,
    required ChatRoomDjState dj,
  }) async {
    if (!_live._canControlMusic()) {
      ref.read(voiceRoomTrtcMusicMixerProvider).stop();
      return;
    }
    final key = _live._roomKey;
    if (key.isEmpty) return;
    await ref.read(voiceRoomTrtcMusicMixerProvider).sync(
          enabled: dj.musicEnabled,
          playing: playing,
          roomId: key,
          videoId: videoId ?? sync?.currentVideoId ?? dj.nowPlaying?.videoIdField,
          remote: ref.read(roomMusicRemoteProvider),
          startMs: sync?.resolvedPositionMs(),
          onError: _live.pulseMusicRequestFlash,
        );
  }
}
