part of 'chat_room_providers.dart';

// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

/// Duraklat / devam — [VoiceRoomLiveController] monolith'ten ayrıldı.
extension VoiceRoomPlaybackControls on VoiceRoomLiveController {
  Future<String?> pauseMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    try {
      if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserPause());
      }
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            musicUrl: state.dj.musicUrl,
            playing: false,
          );
      await ref.read(voiceRoomDjPlayerProvider).pause();
      state = state.copyWith(dj: state.dj.copyWith(playing: false));
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }

  Future<String?> resumeMusic() async {
    if (!_canControlMusic()) {
      return 'Bu işlemi gerçekleştirme yetkiniz bulunmamaktadır.';
    }
    final blocSong = _roomKey.isNotEmpty
        ? ref.read(roomSongBlocProvider(_roomKey)).state.current
        : null;
    final url = state.dj.playbackSource;
    final videoId = blocSong?.videoId ??
        state.dj.nowPlaying?.videoIdField ??
        ChatRoomDjState.videoIdFromLoose(
          state.dj.nowPlaying?.youtubeUrl ?? state.dj.musicUrl ?? '',
        );
    if ((url == null || url.isEmpty) &&
        (videoId == null || videoId.isEmpty) &&
        blocSong == null) {
      return 'Çalınacak şarkı yok';
    }
    try {
      if (_roomKey.isNotEmpty) {
        ref.read(roomSongBlocProvider(_roomKey)).add(const RoomSongUserResume());
      }
      await ref
          .read(chatRoomRemoteProvider)
          .updateDj(
            roomKey: _roomKey,
            alternateKey: _musicAlternateKey,
            musicUrl: state.dj.musicUrl,
            videoId: videoId,
            title: state.dj.nowPlaying?.title ?? blocSong?.title,
            playing: true,
          );
      final dj = await _applyDjPlayback(state.dj.copyWith(playing: true));
      state = state.copyWith(dj: dj);
      return null;
    } catch (e) {
      return ApiException.userMessage(e);
    }
  }
}
