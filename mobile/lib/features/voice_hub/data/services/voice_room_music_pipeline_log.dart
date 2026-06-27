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
      'status': ?statusCode,
      'musicUrl': musicUrl ?? '(null)',
      'videoId': ?videoId,
      'playing': ?playing,
      'rawPlaying': ?rawPlayingField,
      'nowPlaying': ?nowPlayingTitle,
      'npYoutube': ?nowPlayingYoutube,
      'queueLen': ?queueLen,
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
      'endpoint': ?endpoint,
      'caller': ?caller,
      'playing': ?playing,
      'queueLen': ?queueLen,
      'hasNowPlaying': ?hasNowPlaying,
      'detail': ?detail,
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
      'endpoint': ?endpoint,
      'serverMusicUrl': serverMusicUrl ?? '(null)',
      'mergedMusicUrl': mergedMusicUrl ?? '(null)',
      'nowPlayingYoutube': nowPlayingYoutube ?? '(null)',
      'videoId': videoId ?? '(null)',
      'playbackSource': playbackSource ?? '(null)',
      'youtubeFallback': youtubeFallback ?? '(null)',
      'playing': ?playing,
      'shouldPlay': ?shouldPlay,
      'resolvedStream': ?resolvedStreamUrl,
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
      'endpoint': ?requestEndpoint,
      'responseMusicUrl': responseMusicUrl ?? '(null)',
      'playing': ?responsePlaying,
      'queuePos': ?queuePosition,
    });
  }

  static void beforeSetAudioSource({
    required String sourceUrl,
    required String sourceType,
    String? metadataTitle,
    String? roomId,
  }) {
    _emit('setAudioSource.before', {
      'room': ?roomId,
      'type': sourceType,
      'url': sourceUrl,
      'title': ?metadataTitle,
    });
  }

  static void playEntered({
    required String sourceUrl,
    String? roomId,
  }) {
    _emit('play.entered', {
      'room': ?roomId,
      'url': sourceUrl,
    });
  }

  static void playState({
    required bool playing,
    required String processingState,
    int? positionMs,
    int? durationMs,
    String? url,
    String? source,
  }) {
    _emit('player.state', {
      'playing': playing,
      'processing': processingState,
      'posMs': ?positionMs,
      'durMs': ?durationMs,
      'url': ?url,
      'via': ?source,
    });
  }

  /// Backend / çözümlenmiş akış URL'si (audioUrl).
  static void backendAudioUrl({
    required String audioUrl,
    String? roomId,
    String? stage,
    String? candidate,
  }) {
    _emit('backend.audioUrl', {
      'room': ?roomId,
      'stage': ?stage,
      'audioUrl': audioUrl,
      'candidate': ?candidate,
    });
  }

  /// `setAudioSource` / `setUrl` tamamlandıktan sonra süre ve durum.
  static void setAudioSourceResult({
    required String url,
    required bool ok,
    String? processingState,
    int? durationMs,
    bool? playing,
    String? error,
  }) {
    _emit('setAudioSource.result', {
      'url': url,
      'ok': ok,
      'processing': ?processingState,
      'durMs': ?durationMs,
      'playing': ?playing,
      'error': ?error,
    });
  }

  static void durationValue({
    required int? durationMs,
    String? url,
    String? source,
  }) {
    _emit('duration', {
      'durMs': durationMs ?? -1,
      'url': ?url,
      'via': ?source,
    });
  }

  static void playbackEvent({
    required String processingState,
    required bool playing,
    int? positionMs,
    int? bufferedMs,
    int? durationMs,
    String? url,
  }) {
    _emit('playbackEvent', {
      'processing': processingState,
      'playing': playing,
      'posMs': ?positionMs,
      'bufMs': ?bufferedMs,
      'durMs': ?durationMs,
      'url': ?url,
    });
  }

  static void playerStateStreamEvent({
    required bool playing,
    required String processingState,
    int? positionMs,
    String? url,
  }) {
    _emit('playerStateStream', {
      'playing': playing,
      'processing': processingState,
      'posMs': ?positionMs,
      'url': ?url,
    });
  }

  static void audioService({
    required String action,
    String? title,
    bool? playing,
    String? processingState,
    int? positionMs,
    int? durationMs,
  }) {
    _emit('audioService', {
      'action': action,
      'title': ?title,
      'playing': ?playing,
      'processing': ?processingState,
      'posMs': ?positionMs,
      'durMs': ?durationMs,
    });
  }

  static void playResult({
    required bool started,
    required String url,
    String? processingState,
    bool? playing,
    int? durationMs,
    String? detail,
  }) {
    _emit('play.result', {
      'started': started,
      'url': url,
      'processing': ?processingState,
      'playing': ?playing,
      'durMs': ?durationMs,
      'detail': ?detail,
    });
  }

  static void justAudioError(
    Object error,
    StackTrace? stack, {
    String? phase,
    String? url,
  }) {
    _emit('just_audio.error', {
      'phase': ?phase,
      'url': ?url,
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
      'code': ?errorCode,
      'error': ?errorMessage,
      'ms': ?elapsedMs,
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
      'djPlaying': ?fetchDjPlaying,
      'queuePlaying': ?fetchQueuePlaying,
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
