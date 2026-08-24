import 'dart:async';

import '../../domain/entities/music_queue_item.dart';
import '../../music/domain/song_playback_fields.dart';
import 'room_music_playback_dedupe.dart';
import 'voice_room_dj_player.dart';

/// Tek global müzik oynatıcı — [VoiceRoomDjPlayer] üzerinden `just_audio`.
///
/// Oda değişince eski oda olayları yok sayılır; aynı parça iki kez başlatılmaz.
class RoomMusicService {
  RoomMusicService(this._player);

  final VoiceRoomDjPlayer _player;
  final RoomMusicPlaybackDedupe _dedupe = RoomMusicPlaybackDedupe();

  String? _activeRoomId;

  VoiceRoomDjPlayer get player => _player;

  void bindRoom(String? roomId) {
    final next = roomId?.trim();
    if (next == _activeRoomId) return;
    if (_activeRoomId != null && _activeRoomId!.isNotEmpty) {
      unawaited(stop());
    }
    _activeRoomId = next;
    _dedupe.clear();
  }

  bool _roomMatches(String? roomId) {
    final active = _activeRoomId?.trim() ?? '';
    if (active.isEmpty) return true;
    final incoming = roomId?.trim() ?? '';
    return incoming.isEmpty || incoming == active;
  }

  /// Sesli oda — yalnızca gerçek audio stream URL (YouTube watch değil).
  Future<bool> playVoiceRoomAudio({
    required String roomId,
    required Map<String, dynamic> payload,
    MusicQueueItem? nowPlaying,
    bool playing = true,
    bool muted = false,
    Duration startPosition = Duration.zero,
  }) async {
    if (!_roomMatches(roomId)) return false;
    bindRoom(roomId);

    final fields = SongPlaybackFields.parseQuiet(payload);
    final audioUrl = fields.resolvedAudioStreamUrl;
    if (audioUrl == null || audioUrl.isEmpty) return false;

    if (_dedupe.isDuplicate(
      queueId: payload['queueId']?.toString(),
      videoId: fields.videoId,
      streamUrl: audioUrl,
      eventId: payload['eventId']?.toString() ?? payload['id']?.toString(),
    )) {
      return true;
    }

    if (!playing) {
      await stop();
      return true;
    }

    return _player.playServerStream(
      streamUrl: audioUrl,
      playing: true,
      startPosition: startPosition,
      nowPlaying: nowPlaying,
      muted: muted,
      videoId: fields.videoId,
    );
  }

  Future<bool> syncDj({
    required String roomId,
    String? musicUrl,
    String? resolveSeed,
    String? fallbackYoutubeUrl,
    MusicQueueItem? nowPlaying,
    bool playing = true,
    bool muted = false,
    String? serverStreamUrl,
    Duration startPosition = Duration.zero,
  }) async {
    if (!_roomMatches(roomId)) return false;
    bindRoom(roomId);

    final url = serverStreamUrl ?? musicUrl;
    if (url != null &&
        _dedupe.isDuplicate(
          streamUrl: url,
          videoId: nowPlaying?.videoIdField,
          queueId: nowPlaying?.id,
        )) {
      if (!playing) await stop();
      return playing;
    }

    if (!playing) {
      await stop();
      return true;
    }

    return _player.sync(
      musicUrl: musicUrl,
      resolveSeed: resolveSeed,
      fallbackYoutubeUrl: fallbackYoutubeUrl,
      nowPlaying: nowPlaying,
      playing: playing,
      muted: muted,
      serverStreamUrl: serverStreamUrl,
      startPosition: startPosition,
    );
  }

  Future<void> stop() async {
    _dedupe.clear();
    await _player.stop();
  }

  Future<void> pause() => _player.pause();

  Future<void> shutdown() async {
    _activeRoomId = null;
    _dedupe.clear();
    await _player.shutdown();
  }

  void dispose() {
    _activeRoomId = null;
    _dedupe.clear();
    _player.dispose();
  }
}
