import 'package:dio/dio.dart';

import '../../../../../core/network/api_endpoints.dart';
import '../dto/room_song_dto.dart';

/// SongQueueService HTTP — stream URL üretmez; yalnızca videoId senkronu.
class RoomSongRemoteDataSource {
  RoomSongRemoteDataSource(this._dio);

  final Dio _dio;

  Future<RoomSongDto?> fetchCurrentSong(String roomId) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.chatRoomCurrentSong(roomId));
    final data = res.data;
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    Map<String, dynamic>? raw;
    for (final key in const ['currentSong', 'current', 'nowPlaying']) {
      final candidate = map[key];
      if (candidate is Map) {
        raw = Map<String, dynamic>.from(candidate);
        break;
      }
    }
    raw ??= map;
    return RoomSongDto.fromJson(raw);
  }

  Future<({RoomSongDto? current, List<RoomSongQueueItemDto> queue})> fetchQueue(
    String roomId,
  ) async {
    final res = await _dio.get<dynamic>(ApiEndpoints.chatRoomSongQueue(roomId));
    final data = res.data;
    if (data is! Map) {
      return (current: null, queue: const <RoomSongQueueItemDto>[]);
    }
    final map = Map<String, dynamic>.from(data);
    RoomSongDto? current;
    final cur = map['currentSong'];
    if (cur is Map) {
      current = RoomSongDto.fromJson(Map<String, dynamic>.from(cur));
    }
    final queue = <RoomSongQueueItemDto>[];
    final rawQ = map['queue'];
    if (rawQ is List) {
      for (final e in rawQ) {
        if (e is Map) {
          queue.add(RoomSongQueueItemDto.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }
    return (current: current, queue: queue);
  }

  Future<List<YoutubeSearchResultDto>> search(String query, {int limit = 12}) async {
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
        .map((e) => YoutubeSearchResultDto.fromJson(Map<String, dynamic>.from(e)))
        .where((h) => h.videoId.isNotEmpty)
        .take(limit)
        .toList();
  }

  Future<void> requestSong({
    required String roomId,
    required String videoId,
    required String title,
    String? thumbnail,
    String? duration,
    String? channel,
    bool priority = false,
  }) async {
    await _dio.post<dynamic>(
      ApiEndpoints.chatRoomSongRequest(roomId),
      data: {
        'videoId': videoId,
        'title': title,
        if (thumbnail != null) 'thumbUrl': thumbnail,
        if (duration != null) 'duration': duration,
        if (channel != null) 'artist': channel,
        'priority': priority,
      },
    );
  }

  Future<void> skip(String roomId) async {
    await _dio.post<dynamic>(ApiEndpoints.chatRoomSongSkip(roomId));
  }

  Future<void> pause(String roomId) async {
    await _dio.post<dynamic>(ApiEndpoints.chatRoomSongPause(roomId));
  }

  Future<void> resume(String roomId) async {
    await _dio.post<dynamic>(ApiEndpoints.chatRoomSongResume(roomId));
  }

  Future<void> removeFromQueue(String roomId, String queueId) async {
    await _dio.delete<dynamic>(ApiEndpoints.chatRoomSongRemove(roomId, queueId));
  }
}
