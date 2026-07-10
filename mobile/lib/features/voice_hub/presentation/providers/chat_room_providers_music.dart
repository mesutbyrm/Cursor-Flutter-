part of 'chat_room_providers.dart';

/// Sesli oda müzik ve DJ kontrol API'si — [VoiceRoomLiveController]'dan ayrıldı.
/// `part` olduğundan aynı kütüphanededir: private alan/metotlara erişir ve
/// davranış birebir korunur (yalnızca fiziksel konum değişti).
extension VoiceRoomMusicControls on VoiceRoomLiveController {
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

  /// X / kapat — yalnızca yetkili kullanıcılar sunucu kuyruğunu durdurur.
  Future<void> closeMusicPlayer() async {
    if (!_canStopMusic()) {
      ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
      ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
      return;
    }
    ref.read(voiceRoomMusicSessionProvider.notifier).markUserDismissed();
    await ref.read(voiceRoomDjPlayerProvider).stop();
    try {
      final result = await ref.read(chatRoomRemoteProvider).clearMusicQueue(
        roomKey: _roomKey,
        alternateKey: _musicAlternateKey,
      );
      if (result.autoAdvanced) {
        await refresh();
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
    if (_roomKey.isNotEmpty) {
      ref.read(roomVideoControllerProvider(_roomKey).notifier).clear();
    }
    ref.read(voiceRoomMusicSessionProvider.notifier).dismissAfterClose();
  }

  Future<String?> updateMusicSettings({
    bool? musicEnabled,
    int? musicRequestCost,
    int? maxMusicQueue,
  }) async {
    try {
      await ref
          .read(chatRoomRemoteProvider)
          .updateMusicSettings(
            roomKey: _roomKey,
            musicEnabled: musicEnabled,
            musicRequestCost: musicRequestCost,
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
