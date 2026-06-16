import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../domain/entities/room_playback_sync.dart';

class RoomMusicRemoteDataSource {
  RoomMusicRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<YoutubeSearchHit>> searchSongs(String query, {int limit = 5}) async {
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

  Future<String?> resolveStreamUrl({
    required String roomId,
    required String videoId,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        ApiEndpoints.chatRoomMusicStream(roomId),
        data: {'videoId': videoId},
      );
      final data = res.data;
      if (data is Map) {
        final url = data['streamUrl'] ?? data['url'];
        if (url is String && url.startsWith('http')) return url;
      }
    } catch (_) {}
    try {
      final res = await _dio.get<dynamic>(
        ApiEndpoints.chatYoutubeStream,
        queryParameters: {'videoId': videoId},
      );
      final data = res.data;
      if (data is Map) {
        final url = data['streamUrl'] ?? data['url'];
        if (url is String && url.startsWith('http')) return url;
      }
    } catch (_) {}
    return null;
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
    };
    final res = await _dio.post<dynamic>(
      '/api/chat/rooms/$roomId/song-request',
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
      queuePosition: map['queuePosition'] as int?,
      streamUrl: map['musicUrl']?.toString(),
      playing: map['playing'] == true,
      newBalance: map['newBalance'] as int? ?? map['coinBalance'] as int?,
    );
  }

  Future<RoomPlaybackSync?> fetchDjSync(String roomId) async {
    final res = await _dio.get<dynamic>('/api/chat/rooms/$roomId/music-queue');
    final data = res.data;
    if (data is! Map) return null;
    return RoomPlaybackSync.fromPayload(Map<String, dynamic>.from(data));
  }

  Future<void> pauseDj(String roomId) async {
    await _dio.post<dynamic>('/api/chat/rooms/$roomId/dj', data: {'playing': false});
  }

  Future<void> resumeDj(String roomId, {String? musicUrl}) async {
    await _dio.post<dynamic>(
      '/api/chat/rooms/$roomId/dj',
      data: {
        'playing': true,
        if (musicUrl != null) 'musicUrl': musicUrl,
      },
    );
  }

  Future<void> skipQueue(String roomId) async {
    await _dio.post<dynamic>('/api/chat/rooms/$roomId/music-queue/advance');
  }

  Future<void> stopQueue(String roomId) async {
    await _dio.delete<dynamic>('/api/chat/rooms/$roomId/music-queue');
  }
}
