import 'package:flutter/foundation.dart';

import '../../domain/entities/chat_room_dj_state.dart';
import '../../domain/entities/music_queue_item.dart';

/// `!istek` → API → `musicUrl` → `playbackSource` → `setAudioSource` veri hattı logları.
///
/// Release APK'da da yazılır — web ile Flutter karşılaştırması için.
abstract final class VoiceRoomMusicPipelineLog {
  static const _tag = '[MusicPipeline]';

  static void _emit(String phase, Map<String, Object?> data) {
    final extra = data.entries
        .where((e) => e.value != null)
        .map((e) => '${e.key}=${_short(e.value)}')
        .join(' ');
    debugPrint('$_tag $phase $extra');
  }

  static String _short(Object? v) {
    final s = '$v';
    if (s.length <= 160) return s;
    return '${s.substring(0, 157)}…';
  }

  /// HTTP yanıtı — hangi endpoint, ham `musicUrl`.
  static void apiResponse({
    required String endpoint,
    required String method,
    required String caller,
    int? statusCode,
    String? musicUrl,
    String? videoId,
    bool? playing,
    String? nowPlayingTitle,
    String? nowPlayingYoutube,
    int? queueLen,
    String? rawPlayingField,
  }) {
    _emit('api.response', {
      'endpoint': endpoint,
      'method': method,
      'caller': caller,
      if (statusCode != null) 'status': statusCode,
      'musicUrl': musicUrl ?? '(null)',
      if (videoId != null) 'videoId': videoId,
      if (playing != null) 'playing': playing,
      if (rawPlayingField != null) 'rawPlaying': rawPlayingField,
      if (nowPlayingTitle != null) 'nowPlaying': nowPlayingTitle,
      if (nowPlayingYoutube != null) 'npYoutube': nowPlayingYoutube,
      if (queueLen != null) 'queueLen': queueLen,
    });
    if (musicUrl == null || musicUrl.isEmpty) {
      nullMusicUrl(
        reason: 'api_response_missing_musicUrl',
        endpoint: endpoint,
        caller: caller,
        playing: playing,
        queueLen: queueLen,
        hasNowPlaying: nowPlayingTitle != null,
      );
    }
  }

  /// `musicUrl` neden null/boş — teşhis kodu.
  static void nullMusicUrl({
    required String reason,
    String? endpoint,
    String? caller,
    bool? playing,
    int? queueLen,
    bool? hasNowPlaying,
    String? detail,
  }) {
    _emit('musicUrl.null', {
      'reason': reason,
      if (endpoint != null) 'endpoint': endpoint,
      if (caller != null) 'caller': caller,
      if (playing != null) 'playing': playing,
      if (queueLen != null) 'queueLen': queueLen,
      if (hasNowPlaying != null) 'hasNowPlaying': hasNowPlaying,
      if (detail != null) 'detail': detail,
    });
  }

  /// Web ile aynı alanların karşılaştırması (mobil state).
  static void compareFields({
    required String stage,
    required String roomId,
    String? endpoint,
    String? serverMusicUrl,
    String? mergedMusicUrl,
    String? nowPlayingYoutube,
    String? videoId,
    String? playbackSource,
    String? youtubeFallback,
    bool? playing,
    bool? shouldPlay,
    String? resolvedStreamUrl,
  }) {
    _emit('fields.compare', {
      'stage': stage,
      'room': roomId,
      if (endpoint != null) 'endpoint': endpoint,
      'serverMusicUrl': serverMusicUrl ?? '(null)',
      'mergedMusicUrl': mergedMusicUrl ?? '(null)',
      'nowPlayingYoutube': nowPlayingYoutube ?? '(null)',
      'videoId': videoId ?? '(null)',
      'playbackSource': playbackSource ?? '(null)',
      'youtubeFallback': youtubeFallback ?? '(null)',
      if (playing != null) 'playing': playing,
      if (shouldPlay != null) 'shouldPlay': shouldPlay,
      if (resolvedStreamUrl != null) 'resolvedStream': resolvedStreamUrl,
    });
  }

  static void compareDjState({
    required String stage,
    required String roomId,
    required ChatRoomDjState dj,
    String? endpoint,
    String? resolvedStreamUrl,
    bool? shouldPlay,
  }) {
    final np = dj.nowPlaying;
    final videoId = videoIdFromItem(np) ??
        (dj.musicUrl != null ? videoIdFromUrl(dj.musicUrl!) : null);
    compareFields(
      stage: stage,
      roomId: roomId,
      endpoint: endpoint,
      serverMusicUrl: dj.musicUrl,
      mergedMusicUrl: dj.musicUrl,
      nowPlayingYoutube: np?.youtubeUrl,
      videoId: videoId,
      playbackSource: dj.playbackSource,
      youtubeFallback: dj.youtubeFallbackSource,
      playing: dj.playing,
      shouldPlay: shouldPlay,
      resolvedStreamUrl: resolvedStreamUrl,
    );
  }

  static void istekSubmitted({
    required String song,
    required String roomId,
    String? requestEndpoint,
    String? responseMusicUrl,
    bool? responsePlaying,
    int? queuePosition,
  }) {
    _emit('istek.done', {
      'song': song,
      'room': roomId,
      if (requestEndpoint != null) 'endpoint': requestEndpoint,
      'responseMusicUrl': responseMusicUrl ?? '(null)',
      if (responsePlaying != null) 'playing': responsePlaying,
      if (queuePosition != null) 'queuePos': queuePosition,
    });
  }

  static void beforeSetAudioSource({
    required String sourceUrl,
    required String sourceType,
    String? metadataTitle,
    String? roomId,
  }) {
    _emit('setAudioSource.before', {
      if (roomId != null) 'room': roomId,
      'type': sourceType,
      'url': sourceUrl,
      if (metadataTitle != null) 'title': metadataTitle,
    });
  }

  static void playEntered({
    required String sourceUrl,
    String? roomId,
  }) {
    _emit('play.entered', {
      if (roomId != null) 'room': roomId,
      'url': sourceUrl,
    });
  }

  static void justAudioError(
    Object error,
    StackTrace? stack, {
    String? phase,
    String? url,
  }) {
    _emit('just_audio.error', {
      if (phase != null) 'phase': phase,
      if (url != null) 'url': url,
      'type': error.runtimeType.toString(),
      'message': error.toString(),
      if (stack != null)
        'stack': stack.toString().split('\n').take(4).join(' | '),
    });
  }

  static void exoProbeResult({
    required String url,
    required bool ok,
    String? errorCode,
    String? errorMessage,
    int? elapsedMs,
  }) {
    _emit('exo.probe', {
      'url': url,
      'ok': ok,
      if (errorCode != null) 'code': errorCode,
      if (errorMessage != null) 'error': errorMessage,
      if (elapsedMs != null) 'ms': elapsedMs,
    });
  }

  static void mergeWarning({
    required String roomId,
    required String message,
    String? fetchDjMusicUrl,
    String? fetchQueueMusicUrl,
    bool? fetchDjPlaying,
    bool? fetchQueuePlaying,
  }) {
    _emit('merge.warn', {
      'room': roomId,
      'msg': message,
      'djMusicUrl': fetchDjMusicUrl ?? '(null)',
      'queueMusicUrl': fetchQueueMusicUrl ?? '(null)',
      if (fetchDjPlaying != null) 'djPlaying': fetchDjPlaying,
      if (fetchQueuePlaying != null) 'queuePlaying': fetchQueuePlaying,
    });
  }

  static String? videoIdFromItem(MusicQueueItem? item) {
    if (item == null) return null;
    return videoIdFromUrl(item.youtubeUrl);
  }

  static String? videoIdFromUrl(String url) {
    final id = url.trim();
    if (id.isEmpty) return null;
    if (id.length <= 15 && !id.contains('/')) return id;
    final m = RegExp(r'(?:v=|youtu\.be/)([a-zA-Z0-9_-]{6,})').firstMatch(id);
    return m?.group(1);
  }
}
