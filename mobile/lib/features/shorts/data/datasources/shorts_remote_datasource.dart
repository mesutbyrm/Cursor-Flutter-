import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/short_comment_entity.dart';
import '../../domain/entities/short_video_entity.dart';

class ShortsRemoteDataSource {
  ShortsRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is! Map) return null;
    final m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data']);
    }
    return m;
  }

  ShortVideoAuthor _authorFrom(Map<String, dynamic> json) {
    final authorRaw = pick(json, ['author', 'user']);
    final m = authorRaw is Map ? asJsonMap(authorRaw) : json;
    final id = (pick(m, ['id', 'userId']) ?? '').toString();
    final username = (pick(m, ['username', 'handle']) ?? 'kullanici').toString();
    return ShortVideoAuthor(
      id: id,
      username: username,
      displayName: pick(m, ['displayName', 'name'])?.toString(),
      avatarUrl: pick(m, ['avatarUrl', 'avatar', 'image'])?.toString(),
    );
  }

  ShortVideoEntity _videoFrom(Map<String, dynamic> json) {
    final authorRaw = pick(json, ['author', 'user']);
    final author = authorRaw is Map
        ? _authorFrom(asJsonMap(authorRaw))
        : ShortVideoAuthor(
            id: (pick(json, ['userId']) ?? '').toString(),
            username: 'kullanici',
          );

    final createdRaw = pick(json, ['createdAt', 'created_at']);
    DateTime? createdAt;
    if (createdRaw != null) {
      createdAt = DateTime.tryParse(createdRaw.toString());
    }

    return ShortVideoEntity(
      id: (pick(json, ['id']) ?? '').toString(),
      userId: (pick(json, ['userId', 'user_id']) ?? author.id).toString(),
      videoUrl: (pick(json, ['videoUrl', 'video_url']) ?? '').toString(),
      thumbnailUrl: pick(json, ['thumbnailUrl', 'thumbnail_url'])?.toString(),
      description: pick(json, ['description', 'caption'])?.toString(),
      viewsCount: asInt(pick(json, ['viewsCount', 'views_count'])),
      likesCount: asInt(pick(json, ['likesCount', 'likes_count'])),
      commentsCount: asInt(pick(json, ['commentsCount', 'comments_count'])),
      durationSec: () {
        final v = pick(json, ['durationSec', 'duration_sec']);
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      createdAt: createdAt,
      author: author,
      likedByMe: asBool(pick(json, ['likedByMe', 'liked_by_me'])),
      viewedByMe: asBool(pick(json, ['viewedByMe', 'viewed_by_me'])),
    );
  }

  Future<({List<ShortVideoEntity> videos, String? nextCursor, bool hasMore})>
      fetchFeed({
    String? cursor,
    int limit = 10,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideos,
      query: {
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );
    final m = _unwrap(res.data);
    if (m == null) {
      return (
        videos: <ShortVideoEntity>[],
        nextCursor: null,
        hasMore: false,
      );
    }
    final raw = m['videos'];
    final videos = raw is List
        ? asJsonList(raw).map(_videoFrom).where((v) => v.id.isNotEmpty).toList()
        : <ShortVideoEntity>[];
    return (
      videos: videos,
      nextCursor: m['nextCursor']?.toString(),
      hasMore: m['hasMore'] == true || m['nextCursor'] != null,
    );
  }

  Future<ShortVideoEntity> uploadVideo({
    required String videoPath,
    String? thumbnailPath,
    String? description,
  }) async {
    final form = FormData.fromMap({
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'video': await MultipartFile.fromFile(
        videoPath,
        filename: 'short_${DateTime.now().millisecondsSinceEpoch}.mp4',
        contentType: DioMediaType.parse('video/mp4'),
      ),
      if (thumbnailPath != null)
        'thumbnail': await MultipartFile.fromFile(
          thumbnailPath,
          filename: 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
    });

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosUpload,
      data: form,
      options: Options(
        contentType: 'multipart/form-data',
        sendTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 2),
      ),
    );
    final m = _unwrap(res.data);
    final raw = m != null ? pick(m, ['video', 'item']) : null;
    if (raw is Map) return _videoFrom(asJsonMap(raw));
    if (m != null && m.containsKey('id')) return _videoFrom(m);
    throw ApiException('Video yükleme yanıtı okunamadı.');
  }

  Future<({bool liked, int likesCount})> toggleLike(String videoId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoLike(videoId),
    );
    final m = _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) return (liked: true, likesCount: 0);
    return (
      liked: asBool(pick(m, ['liked', 'isLiked', 'likedByMe'])),
      likesCount: asInt(pick(m, ['likesCount', 'likeCount', 'likes'])),
    );
  }

  Future<List<ShortCommentEntity>> fetchComments(String videoId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideoComments(videoId),
    );
    final m = _unwrap(res.data);
    final raw = m?['comments'];
    if (raw is! List) return const [];
    return asJsonList(raw).map((j) {
      final createdRaw = pick(j, ['createdAt']);
      return ShortCommentEntity(
        id: (pick(j, ['id']) ?? '').toString(),
        content: (pick(j, ['content', 'text']) ?? '').toString(),
        createdAt: DateTime.tryParse(createdRaw?.toString() ?? '') ??
            DateTime.now(),
        author: _authorFrom(j),
      );
    }).where((c) => c.id.isNotEmpty).toList();
  }

  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoComments(videoId),
      data: {'content': content.trim()},
    );
    final m = _unwrap(res.data);
    if (m == null) throw ApiException('Yorum yanıtı okunamadı.');
    final raw = pick(m, ['comment']);
    if (raw is! Map) throw ApiException('Yorum yanıtı okunamadı.');
    final j = asJsonMap(raw);
    final comment = ShortCommentEntity(
      id: (pick(j, ['id']) ?? '').toString(),
      content: (pick(j, ['content']) ?? content).toString(),
      createdAt: DateTime.tryParse(
            pick(j, ['createdAt'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      author: _authorFrom(j),
    );
    return (
      comment: comment,
      commentsCount: asInt(pick(m, ['commentsCount'])),
    );
  }

  Future<({bool counted, int viewsCount})> recordView(
    String videoId, {
    required double watchedSec,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoView(videoId),
      data: {'watchedSec': watchedSec},
    );
    final m = _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) return (counted: false, viewsCount: 0);
    return (
      counted: asBool(pick(m, ['counted'])),
      viewsCount: asInt(pick(m, ['viewsCount'])),
    );
  }

  Future<void> deleteVideo(String videoId) async {
    await _dio.safeDelete(ApiEndpoints.shortVideoDelete(videoId));
  }

  Future<List<ShortVideoEntity>> fetchByUser(String userId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosByUser(userId),
    );
    final m = _unwrap(res.data);
    final raw = m?['videos'];
    if (raw is! List) return const [];
    return asJsonList(raw).map(_videoFrom).where((v) => v.id.isNotEmpty).toList();
  }
}
