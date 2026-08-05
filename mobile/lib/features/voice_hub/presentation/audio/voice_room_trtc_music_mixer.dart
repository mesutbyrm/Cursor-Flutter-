import 'dart:async';

import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../data/services/voice_room_debug_log.dart';
import '../../music/data/datasources/room_music_remote_datasource.dart';

/// !istek / DJ müziğini TRTC ses kanalına karıştırır (IFrame yerel senkron kalır).
class VoiceRoomTrtcMusicMixer {
  TrtcRoomManager? _manager;
  String? _lastVideoId;
  String? _lastStreamUrl;
  var _paused = false;

  void bind(TrtcRoomManager? manager) {
    if (identical(_manager, manager)) return;
    if (_manager != null && manager == null) {
      stop();
    }
    _manager = manager;
  }

  Future<void> sync({
    required bool enabled,
    required bool playing,
    required String roomId,
    required String? videoId,
    required RoomMusicRemoteDataSource remote,
    int? startMs,
    void Function(String message)? onError,
  }) async {
    final mgr = _manager;
    if (!enabled || mgr == null || !mgr.inRoom) {
      stop();
      return;
    }
    if (!playing) {
      if (_lastStreamUrl != null && !_paused) {
        mgr.pausePublishedMusic();
        _paused = true;
      }
      return;
    }
    final vid = videoId?.trim() ?? '';
    if (vid.isEmpty) return;

    if (vid == _lastVideoId && _lastStreamUrl != null) {
      if (_paused) {
        mgr.resumePublishedMusic();
        _paused = false;
      }
      return;
    }

    try {
      final url = await remote.resolveStreamUrl(roomId: roomId, videoId: vid);
      if (url == null || url.isEmpty) {
        VoiceRoomDebugLog.log('trtc.music.mix.skip', {
          'reason': 'no_stream_url',
          'videoId': vid,
        });
        onError?.call('🎵 Müzik TRTC kanalına karıştırılamadı — akış URL yok');
        return;
      }
      _lastVideoId = vid;
      _lastStreamUrl = url;
      _paused = false;
      await mgr.playPublishedMusic(url, startMs: startMs ?? 0);
    } catch (e) {
      VoiceRoomDebugLog.log('trtc.music.mix.error', {
        'videoId': vid,
        'error': e.toString(),
      });
      onError?.call('🎵 Müzik TRTC kanalına karıştırılamadı');
    }
  }

  void stop() {
    _lastVideoId = null;
    _lastStreamUrl = null;
    _paused = false;
    _manager?.stopPublishedMusic();
  }

  void dispose() => stop();
}
