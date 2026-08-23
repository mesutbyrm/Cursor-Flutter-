part of 'chat_room_providers.dart';

// Extension methods on Notifier access `state` in the same library.
// Analyzer still flags @protected/@visibleForTesting across extensions.
// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Sesli oda müzik ve DJ kontrol API'si — [VoiceRoomLiveController]'dan ayrıldı.
/// `part` olduğundan aynı kütüphanededir: private alan/metotlara erişir ve
/// davranış birebir korunur (yalnızca fiziksel konum değişti).
extension VoiceRoomMusicControls on VoiceRoomLiveController {
  /// Hoparlör / video çıkışını anında kes — sunucu kuyruğuna dokunmaz.
  void _haltLocalMusicPlaybackImmediate() {
    unawaited(ref.read(voiceRoomDjPlayerProvider).stop());
    if (_roomKey.isEmpty) return;
    ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserPause());
    ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
  }

  bool _isLocalMusicOutputActive() {
    if (_roomKey.isEmpty) return false;
    final playerActive =
        ref.read(roomMusicServiceProvider).player.playback.value.playing;
    final videoActive =
        ref.read(roomVideoControllerProvider(_roomKey)).hasActiveVideo;
    return playerActive || videoActive;
  }

  Future<String?> _resolvePlaybackStreamUrl({
    required String videoId,
    String? serverUrl,
  }) async {
    final fields = SongPlaybackFields.parseQuiet({
      'musicUrl': serverUrl,
      'videoId': videoId,
    });
    final direct = fields.resolvedAudioStreamUrl;
    if (direct != null && direct.isNotEmpty) return direct;
    final vid = videoId.trim();
    if (vid.isEmpty || _roomKey.isEmpty) return null;
    try {
      return await ref
          .read(resolveStreamUseCaseProvider)(
            roomId: _roomKey,
            videoId: vid,
          )
          .timeout(const Duration(seconds: 12));
    } catch (_) {
      return null;
    }
  }

  void _applyMusicRequestUi({
    required ChatRoomDjState dj,
    required bool shouldPlay,
    bool withVideo = false,
  }) {
    // Provider güncellemesi sheet/pop animasyonu sırasında gelirse oda ANR yapar.
    unawaited(
      Future<void>.microtask(() {
        if (!_sessionActive || _roomKey.isEmpty) return;
        _markLocalMusicRequestGrace();
        ref
            .read(voiceRoomMusicSessionProvider.notifier)
            .onMusicStartedFromServer();
        ref.read(voiceRoomMusicSessionProvider.notifier).clearUserDismissed();
        ref.read(voiceRoomUiProvider.notifier).ensureMusicAudible();
        _commitDjUi(dj);
        if (!shouldPlay) return;
        unawaited(_startDjPlaybackNonBlocking(dj, preferVideo: withVideo));
      }),
    );
  }

  Future<void> _startDjPlaybackNonBlocking(
    ChatRoomDjState dj, {
    bool preferVideo = false,
  }) async {
    await Future<void>.delayed(Duration.zero);
    if (!_sessionActive || _roomKey.isEmpty) return;

    final isVideo = preferVideo || dj.nowPlaying?.isVideoRequest == true;
    if (isVideo) {
      _syncRoomVideo(dj);
    }

    if (!_sessionActive) return;
    unawaited(_playDjInBackground(dj));
  }

  /// Hoparlör aç/kapa — müzik çıkışını anında kes veya (kullanıcı isterse) sürdür.
  Future<void> applyAudioOutputGate({required bool speakerOn}) async {
    if (!speakerOn) {
      await ref.read(voiceRoomDjPlayerProvider).stop();
      if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserPause());
        ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
      }
      return;
    }
    final ui = ref.read(voiceRoomUiProvider);
    if (!ui.backgroundMusicEnabled) return;
    final dj = state.dj;
    if (!_hasDjPlayableSource(dj)) return;
    unawaited(_playDjInBackground(dj));
  }

  Future<List<YoutubeSearchHit>> searchYoutube(String query) =>
      ref.read(chatRoomRemoteProvider).searchYoutube(query);

  Future<
    ({
      List<MusicQueueItem> queue,
      int cost,
      int videoRequestCost,
      int maxMusicQueue,
      bool musicEnabled,
      MusicQueueItem? nowPlaying,
      bool? playing,
      bool? canRequestMusic,
      String? musicUrl,
    })
  >
  fetchMusicQueue() =>
      ref.read(chatRoomRemoteProvider).fetchMusicQueue(_roomKey);

  Future<List<PopularMusicSuggestion>> fetchPopularMusic() =>
      ref.read(chatRoomRemoteProvider).fetchPopularMusic();

  /// Video yüklenemezse — ses moduna geç (IFrame mini player).
  Future<void> fallbackVideoToAudioOnly() async {
    final np = state.dj.nowPlaying;
    if (np == null || !np.isVideoRequest) return;
    ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
    final audioNp = np.asAudioRequest();
    final dj = state.dj.copyWith(nowPlaying: audioNp);
    _lastDjPlaybackSignature = '';
    state = state.copyWith(dj: dj);
    _syncRoomSongBloc();
    _showMusicRequestFlashLine('📺 Video açılamadı — ses moduna geçildi.');
  }

  Future<String?> skipMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    try {
      await ref.read(chatRoomRemoteProvider).skipMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> replayMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    if (state.dj.nowPlaying == null) {
      return 'Tekrar çalınacak parça yok.';
    }
    try {
      _lastDjPlaybackSignature = '';
      final dj = state.dj.copyWith(playing: true);
      final applied = await _applyDjPlayback(dj);
      state = state.copyWith(dj: applied);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> reorderMusicQueue(List<String> orderedItemIds) async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    if (orderedItemIds.isEmpty) return null;
    try {
      await ref.read(chatRoomRemoteProvider).reorderMusicQueue(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            orderedItemIds: orderedItemIds,
          );
      await refresh(includeDj: true);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeQueueItem(String itemId) async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .removeMusicQueueItem(roomKey: _roomKey, itemId: itemId);
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> clearMusicQueue() async {
    if (!_canStopMusic()) {
      return 'Müziği yalnızca oda sahibi, admin veya şarkıyı isteyen durdurabilir.';
    }
    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      if (result.autoAdvanced) {
        await refresh();
        return null;
      }
      await ref.read(voiceRoomDjPlayerProvider).stop();
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  /// Durdur / kapat — her kullanıcıda yerel çıkış anında kesilir; sunucu
  /// kuyruğu yalnızca yetkili kullanıcılar için temizlenir.
  Future<void> closeMusicPlayer() async {
    ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
    _haltLocalMusicPlaybackImmediate();

    if (!_canStopMusic()) {
      ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
      return;
    }

    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      if (result.autoAdvanced) {
        await refresh();
        ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
        return;
      }
      await refresh();
    } catch (_) {
      state = state.copyWith(
        dj: state.dj.copyWith(
          playing: false,
          clearNowPlaying: true,
          clearMusicUrl: true,
          musicQueue: const [],
        ),
      );
    }
    ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
  }

  Future<String?> updateMusicSettings({
    bool? musicEnabled,
    int? musicRequestCost,
    int? videoRequestCost,
    int? maxMusicQueue,
  }) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .updateMusicSettings(
            roomKey: _roomKey,
            musicEnabled: musicEnabled,
            musicRequestCost: musicRequestCost,
            videoRequestCost: videoRequestCost,
            maxMusicQueue: maxMusicQueue,
          );
      await refresh();
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> addRoomDj(String targetUserId) async {
    try {
      final label = _djChatLabel(targetUserId);
      final ids = await ref.read(chatRoomRemoteProvider).addRoomDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            targetUserId: targetUserId,
            targetLabel: label,
          );
      final enriched = _enrichDjUsers(
        state.dj,
        state.presence,
      ).copyWith(
        djUsers: ids
            .map(
              (id) => state.dj.djUsers
                      .where((u) => u.id == id)
                      .firstOrNull ??
                  ChatRoomUserRef(
                    id: id,
                    name: _djChatLabel(id) ?? 'DJ',
                    chatRole: 'dj',
                  ),
            )
            .toList(),
      );
      state = state.copyWith(dj: enriched);
      await refresh(includeDj: true);
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> removeRoomDj(String targetUserId) async {
    try {
      final label = _djChatLabel(targetUserId);
      await ref.read(chatRoomRemoteProvider).removeRoomDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            targetUserId: targetUserId,
            targetLabel: label,
          );
      await refresh();
      ref.invalidate(voiceRoomsProvider);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> setActiveDj(String? targetUserId) async {
    try {
      await ref.read(chatRoomRemoteProvider).setActiveDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            userId: targetUserId,
          );
      await refresh(includeDj: true);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }
}
