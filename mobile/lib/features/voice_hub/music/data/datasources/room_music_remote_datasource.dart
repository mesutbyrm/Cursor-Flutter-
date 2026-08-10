import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../domain/entities/room_playback_sync.dart';
import '../../../presentation/audio/voice_room_dj_stream_loader.dart';
import '../../../data/services/voice_room_music_pipeline_log.dart';

class RoomMusicRemoteDataSource {
  RoomMusicRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<YoutubeSearchHit>> searchSongs(String query, {int limit = 10}) async {
    final q = query.trim();
    if (q.length < 2) return [];
    final res = await _dio.get<dynamic>(
      ApiEndpoints.musicSearch,
      queryParameters: {'q': q, 'limit': limit},
    );
    final data = res.data;
    final raw = data is Map ? (data['items'] ?? data['results']) : data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => YoutubeSearchHit.fromJson(_normalizeSearchRow(e)))
        .where((h) => h.videoId.isNotEmpty)
        .take(limit)
        .toList();
  }

  Map<String, dynamic> _normalizeSearchRow(Map<dynamic, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    if (m['videoId'] == null && m['id'] != null) {
      m['videoId'] = m['id'];
    }
    if (m['thumbUrl'] == null && m['thumbnail'] != null) {
      m['thumbUrl'] = m['thumbnail'];
    }
    if (m['uploader'] == null && m['channelTitle'] != null) {
      m['uploader'] = m['channelTitle'];
    }
    if (m['url'] == null && m['videoId'] != null) {
      m['url'] = 'https://www.youtube.com/watch?v=${m['videoId']}';
    }
    return m;
  }

  /// @deprecated IFrame-only oynatma — yalnızca geriye dönük uyumluluk.
  @Deprecated('RoomSongBloc IFrame oynatma kullanın; stream URL çözümlemesi kaldırıldı')
  Future<String?> resolveStreamUrl({
    required String roomId,
    required String videoId,
  }) async {
    String? raw;
    try {
      final res = await _dio.get<dynamic>(
        ApiEndpoints.chatYoutubeStream,
        queryParameters: {'videoId': videoId},
      );
      final data = res.data;
      if (data is Map) {
        raw = data['streamUrl']?.toString() ?? data['url']?.toString();
      }
      VoiceRoomMusicPipelineLog.apiResponse(
        endpoint: ApiEndpoints.chatYoutubeStream,
        method: 'GET',
        caller: 'resolveStreamUrl',
        statusCode: res.statusCode,
        musicUrl: raw,
        videoId: videoId,
      );
    } catch (e, st) {
      VoiceRoomMusicPipelineLog.justAudioError(
        e,
        st,
        phase: 'resolveStreamUrl.youtube-stream',
        url: videoId,
      );
    }
    if (raw == null || !raw.startsWith('http')) {
      VoiceRoomMusicPipelineLog.nullMusicUrl(
        reason: 'resolveStreamUrl_all_endpoints_failed',
        caller: 'RoomMusicRemoteDataSource',
        detail: videoId,
      );
      return null;
    }
    final clientUrl = VoiceRoomDjStreamLoader.clientPlaybackUrl(raw);
    VoiceRoomMusicPipelineLog.compareFields(
      stage: 'resolveStreamUrl.clientUrl',
      roomId: roomId,
      serverMusicUrl: raw,
      resolvedStreamUrl: clientUrl,
      videoId: videoId,
    );
    return clientUrl;
  }

  Future<({
    MusicQueueItem? item,
    List<MusicQueueItem> queue,
    int? queuePosition,
    String? streamUrl,
    bool playing,
    int? newBalance,
  })> enqueueSong({
    required String roomId,
    required String videoId,
    required String title,
    String? channelTitle,
    String? thumbUrl,
    String? duration,
    bool priority = false,
    bool skipPayment = false,
    bool withVideo = false,
  }) async {
    final body = <String, dynamic>{
      'videoId': videoId,
      'title': title,
      'youtubeUrl': 'https://www.youtube.com/watch?v=$videoId',
      if (channelTitle != null) 'artist': channelTitle,
      if (thumbUrl != null) 'thumbUrl': thumbUrl,
      if (duration != null) 'duration': duration,
      'priority': priority,
      if (skipPayment) 'skipPayment': true,
      'requestType': withVideo ? 'video' : 'audio',
      if (withVideo) 'withVideo': true,
      if (withVideo) 'videoMode': 'video',
      if (!withVideo) 'videoMode': 'audio',
    };
    final res = await _dio.post<dynamic>(
      ApiEndpoints.chatRoomSongRequest(roomId),
      data: body,
    );
    return _parseQueueResponse(res.data);
  }

  ({
    MusicQueueItem? item,
    List<MusicQueueItem> queue,
    int? queuePosition,
    String? streamUrl,
    bool playing,
    int? newBalance,
  }) _parseQueueResponse(dynamic data) {
    if (data is! Map) {
      throw ApiException('Geçersiz sunucu yanıtı');
    }
    final map = Map<String, dynamic>.from(data);
    MusicQueueItem? item;
    final rawItem = map['item'] ?? map['nowPlaying'];
    if (rawItem is Map) {
      item = MusicQueueItem.fromJson(Map<String, dynamic>.from(rawItem));
    }
    final queueRaw = map['queue'] ?? map['musicQueue'];
    final queue = <MusicQueueItem>[];
    if (queueRaw is List) {
      for (final e in queueRaw) {
        if (e is Map) {
          queue.add(MusicQueueItem.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return (
      item: item,
      queue: queue,
      queuePosition: _parseOptionalInt(map['queuePosition']),
      streamUrl: map['musicUrl']?.toString(),
      playing: map['playing'] == true,
      newBalance: _parseOptionalInt(map['newBalance']) ??
          _parseOptionalInt(map['coinBalance']),
    );
  }

  int? _parseOptionalInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse('$raw');
  }

  static String _musicPath(String roomId) => ApiEndpoints.chatRoomMusic(roomId);

  Future<RoomPlaybackSync?> fetchDjSync(String roomId) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.chatRoomMusicQueue(roomId));
    final data = res.data;
    if (data is! Map) return null;
    return RoomPlaybackSync.fromPayload(Map<String, dynamic>.from(data));
  }

  Future<void> pauseDj(String roomId) async {
    try {
      await _dio.post<dynamic>(
        _musicPath(roomId),
        data: const {'action': 'pause'},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        await _dio.delete<dynamic>(_musicPath(roomId));
        return;
      }
      rethrow;
    }
  }

  Future<void> resumeDj(String roomId, {String? musicUrl, String? videoId, String? title}) async {
    final resolvedVideoId = (videoId?.trim().isNotEmpty == true)
        ? videoId!.trim()
        : ChatRoomDjState.videoIdFromLoose(musicUrl ?? '');
    await _dio.post<dynamic>(
      _musicPath(roomId),
      data: {
        'action': 'play',
        if (resolvedVideoId != null && resolvedVideoId.isNotEmpty)
          'videoId': resolvedVideoId,
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (musicUrl != null && musicUrl.isNotEmpty) 'musicUrl': musicUrl,
      },
    );
  }

  Future<void> skipQueue(String roomId) async {
    await _dio.post<dynamic>(ApiEndpoints.chatRoomMusicQueueAdvance(roomId));
  }

  Future<void> stopQueue(String roomId) async {
    await _dio.delete<dynamic>(ApiEndpoints.chatRoomMusicQueue(roomId));
  }
}
