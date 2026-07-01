import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/short_video_analytics.dart';
import '../../domain/entities/short_comment_entity.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_ai_metadata.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../../../live/domain/entities/live_gift_event.dart';

class ShortsRemoteDataSource {
  ShortsRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is! Map) return null;
    final m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data']);
    }
    if (m['success'] == false) {
      final err = m['error'];
      if (err is Map) {
        final msg = pick(asJsonMap(err), ['message', 'code'])?.toString();
        if (msg != null && msg.isNotEmpty) throw ApiException(msg);
      }
      final errStr = err?.toString();
      if (errStr != null && errStr.isNotEmpty && !errStr.startsWith('{')) {
        throw ApiException(errStr);
      }
      throw ApiException('İstek başarısız.');
    }
    return m;
  }

  /// Dış servisler için video parse (register yanıtı vb.).
  ShortVideoEntity parseVideo(Map<String, dynamic> json) => _videoFrom(json);

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
      isVerified: asBool(pick(m, ['isVerified', 'verified', 'is_verified'])),
    );
  }

  ShortVideoMusic? _musicFrom(dynamic raw) {
    if (raw is! Map) return null;
    final m = asJsonMap(raw);
    final id = (pick(m, ['id']) ?? '').toString();
    if (id.isEmpty) return null;
    return ShortVideoMusic(
      id: id,
      title: (pick(m, ['title', 'name']) ?? 'Müzik').toString(),
      artist: pick(m, ['artist', 'author'])?.toString(),
      coverUrl: pick(m, ['coverUrl', 'cover_url', 'thumbnailUrl'])?.toString(),
      audioUrl: pick(m, ['audioUrl', 'audio_url', 'url'])?.toString(),
    );
  }

  List<String> _hashtagsFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) {
          if (e is String) return e;
          if (e is Map) {
            return pick(asJsonMap(e), ['name', 'tag', 'hashtag'])?.toString();
          }
          return e?.toString();
        })
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  ShortVideoEntity _videoFrom(Map<String, dynamic> json) {
    final authorRaw = pick(json, ['author', 'user']);
    final authorMap = authorRaw is Map ? asJsonMap(authorRaw) : null;
    final author = authorMap != null
        ? _authorFrom(authorMap)
        : ShortVideoAuthor(
            id: (pick(json, ['userId']) ?? '').toString(),
            username: 'kullanici',
          );

    final authorFollowedByMe = asBool(
      pick(json, [
        'authorFollowedByMe',
        'author_followed_by_me',
        'isFollowingAuthor',
      ]),
    ) ||
        (authorMap != null &&
            asBool(pick(authorMap, ['isFollowing', 'following', 'followedByMe'])));

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
      sharesCount: asInt(pick(json, ['sharesCount', 'shares_count'])),
      savesCount: asInt(pick(json, ['savesCount', 'saves_count'])),
      durationSec: () {
        final v = pick(json, ['durationSec', 'duration_sec']);
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      createdAt: createdAt,
      author: author,
      likedByMe: asBool(pick(json, ['likedByMe', 'liked_by_me'])),
      viewedByMe: asBool(pick(json, ['viewedByMe', 'viewed_by_me'])),
      savedByMe: asBool(pick(json, ['savedByMe', 'saved_by_me'])),
      authorFollowedByMe: authorFollowedByMe,
      hashtags: _hashtagsFrom(pick(json, ['hashtags', 'tags'])),
      music: _musicFrom(pick(json, ['music'])),
      allowDuet: pick(json, ['allowDuet', 'allow_duet']) != false,
      duetOfId: pick(json, ['duetOfId', 'duet_of_id'])?.toString(),
      replyToVideoId:
          pick(json, ['replyToVideoId', 'reply_to_video_id'])?.toString(),
      contentRating:
          (pick(json, ['contentRating', 'content_rating']) ?? 'all').toString(),
      aiSummary: pick(json, ['aiSummary', 'summary'])?.toString(),
      subtitlesUrl:
          pick(json, ['subtitlesUrl', 'subtitles_url'])?.toString(),
    );
  }

  ShortCommentEntity _commentFrom(Map<String, dynamic> json) {
    final createdRaw = pick(json, ['createdAt']);
    final repliesRaw = pick(json, ['replies']);
    final replies = repliesRaw is List
        ? asJsonList(repliesRaw)
            .map((j) => _commentFrom(asJsonMap(j)))
            .where((c) => c.id.isNotEmpty)
            .toList()
        : const <ShortCommentEntity>[];

    return ShortCommentEntity(
      id: (pick(json, ['id']) ?? '').toString(),
      content: (pick(json, ['content', 'text']) ?? '').toString(),
      createdAt:
          DateTime.tryParse(createdRaw?.toString() ?? '') ?? DateTime.now(),
      author: _authorFrom(json),
      likesCount: asInt(pick(json, ['likesCount', 'likes_count'])),
      likedByMe: asBool(pick(json, ['likedByMe', 'liked_by_me'])),
      isPinned: asBool(pick(json, ['isPinned', 'is_pinned'])),
      parentId: pick(json, ['parentId', 'parent_id'])?.toString(),
      repliesCount: asInt(pick(json, ['repliesCount', 'replies_count'])),
      replies: replies,
    );
  }

  ShortHashtagEntity _hashtagFrom(Map<String, dynamic> json) {
    return ShortHashtagEntity(
      name: (pick(json, ['name', 'tag', 'hashtag']) ?? '').toString(),
      videosCount: asInt(pick(json, ['videosCount', 'videos_count', 'count'])),
      viewsCount: asInt(pick(json, ['viewsCount', 'views_count'])),
    );
  }

  ShortMusicEntity _musicEntityFrom(Map<String, dynamic> json) {
    return ShortMusicEntity(
      id: (pick(json, ['id']) ?? '').toString(),
      title: (pick(json, ['title', 'name']) ?? 'Müzik').toString(),
      artist: pick(json, ['artist', 'author'])?.toString(),
      coverUrl: pick(json, ['coverUrl', 'cover_url', 'thumbnailUrl'])?.toString(),
      audioUrl: pick(json, ['audioUrl', 'audio_url', 'url'])?.toString(),
      usageCount: asInt(pick(json, ['usageCount', 'usage_count', 'count'])),
    );
  }

  List<ShortVideoEntity> _videosFrom(dynamic raw) {
    if (raw is! List) return const [];
    return asJsonList(raw).map(_videoFrom).where((v) => v.id.isNotEmpty).toList();
  }

  Future<({List<ShortVideoEntity> videos, String? nextCursor, bool hasMore})>
      fetchFeed({
    String? cursor,
    int limit = 10,
    ShortsFeedTab tab = ShortsFeedTab.forYou,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideos,
      query: {
        'limit': limit,
        'tab': tab == ShortsFeedTab.following ? 'following' : 'foryou',
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
    final videos = _videosFrom(m['videos']);
    return (
      videos: videos,
      nextCursor: m['nextCursor']?.toString(),
      hasMore: m['hasMore'] == true || m['nextCursor'] != null,
    );
  }

  Future<ShortExplorePage> fetchExplore({
    String? query,
    String? cursor,
    int limit = 12,
    String? section,
    String? location,
    double? lat,
    double? lng,
    String? source,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosExplore,
      query: {
        'limit': limit,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        if (section != null && section.isNotEmpty) 'section': section,
        if (location != null && location.isNotEmpty) 'location': location,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (source != null && source.isNotEmpty) 'source': source,
      },
    );
    return _explorePageFromResponse(_unwrap(res.data));
  }

  Future<ShortExplorePage> fetchExploreHub({
    String? locationLabel,
    double? lat,
    double? lng,
  }) async {
    final trendFuture = fetchExplore(limit: 24);
    final forYouFuture = fetchFeed(tab: ShortsFeedTab.forYou, limit: 12);
    final aiFuture = _fetchAiRecommendations(limit: 12);
    final nearbyFuture = (locationLabel != null && locationLabel.isNotEmpty) ||
            lat != null ||
            lng != null
        ? _fetchLocationVideos(
            location: locationLabel,
            lat: lat,
            lng: lng,
            limit: 12,
          )
        : Future.value(const <ShortVideoEntity>[]);

    final results = await Future.wait([
      trendFuture.catchError((_) => const ShortExplorePage(videos: [])),
      forYouFuture.catchError(
        (_) => (
          videos: <ShortVideoEntity>[],
          nextCursor: null,
          hasMore: false,
        ),
      ),
      aiFuture.catchError((_) => const <ShortVideoEntity>[]),
      nearbyFuture,
    ]);

    final trend = results[0] as ShortExplorePage;
    final forYouPage =
        results[1] as ({List<ShortVideoEntity> videos, String? nextCursor, bool hasMore});
    final aiList = results[2] as List<ShortVideoEntity>;
    final nearbyList = results[3] as List<ShortVideoEntity>;

    var forYou = trend.forYouVideos.isNotEmpty
        ? trend.forYouVideos
        : forYouPage.videos;
    var ai = trend.aiRecommendedVideos.isNotEmpty
        ? trend.aiRecommendedVideos
        : aiList;
    if (ai.isEmpty && forYou.isNotEmpty) {
      ai = forYou.take(8).toList();
    }
    if (forYou.isEmpty && ai.isNotEmpty) {
      forYou = ai;
    }

    final locationVideos = trend.locationVideos.isNotEmpty
        ? trend.locationVideos
        : nearbyList;

    return trend.copyWith(
      forYouVideos: _dedupeVideos(forYou),
      aiRecommendedVideos: _dedupeVideos(ai),
      locationVideos: _dedupeVideos(locationVideos),
      locationLabel: locationLabel ?? trend.locationLabel,
    );
  }

  Future<List<ShortVideoEntity>> _fetchAiRecommendations({int limit = 12}) async {
    for (final path in [
      ApiEndpoints.shortVideosRecommend,
      ApiEndpoints.shortVideosExplore,
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          path,
          query: {
            'limit': limit,
            'source': 'ai',
            'recommendation': 'ai',
          },
        );
        final list = _videosFromExplorePayload(_unwrap(res.data));
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  Future<List<ShortVideoEntity>> _fetchLocationVideos({
    String? location,
    double? lat,
    double? lng,
    int limit = 12,
  }) async {
    for (final entry in [
      (path: ApiEndpoints.shortVideosExploreNearby, extra: <String, dynamic>{}),
      (path: ApiEndpoints.shortVideosExplore, extra: {'section': 'nearby'}),
    ]) {
      try {
        final res = await _dio.safeGet<dynamic>(
          entry.path,
          query: {
            'limit': limit,
            if (location != null && location.isNotEmpty) 'location': location,
            if (lat != null) 'lat': lat,
            if (lng != null) 'lng': lng,
            ...entry.extra,
          },
        );
        final list = _videosFromExplorePayload(_unwrap(res.data));
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return const [];
  }

  List<ShortVideoEntity> _dedupeVideos(List<ShortVideoEntity> input) {
    final seen = <String>{};
    final out = <ShortVideoEntity>[];
    for (final v in input) {
      if (v.id.isEmpty || !seen.add(v.id)) continue;
      out.add(v);
    }
    return out;
  }

  List<ShortVideoEntity> _videosFromExplorePayload(Map<String, dynamic>? m) {
    if (m == null) return const [];
    final raw = pick(m, [
      'videos',
      'forYouVideos',
      'for_you',
      'recommended',
      'aiVideos',
      'aiRecommended',
      'ai_recommended',
      'locationVideos',
      'nearbyVideos',
      'nearby',
      'items',
    ]);
    return _videosFrom(raw);
  }

  ShortExplorePage _explorePageFromResponse(Map<String, dynamic>? m) {
    if (m == null) {
      return const ShortExplorePage(videos: []);
    }
    final hashtagsRaw = m['trendingHashtags'] ?? m['hashtags'];
    final musicRaw = m['popularMusic'] ?? m['music'];
    return ShortExplorePage(
      videos: _videosFrom(m['videos'] ?? m['trendVideos'] ?? m['trending']),
      forYouVideos: _videosFrom(
        m['forYouVideos'] ?? m['for_you'] ?? m['recommended'] ?? m['personalized'],
      ),
      aiRecommendedVideos: _videosFrom(
        m['aiVideos'] ?? m['aiRecommended'] ?? m['ai_recommended'],
      ),
      locationVideos: _videosFrom(
        m['locationVideos'] ?? m['nearbyVideos'] ?? m['nearby'],
      ),
      locationLabel: pick(m, ['locationLabel', 'location', 'city'])?.toString(),
      trendingHashtags: hashtagsRaw is List
          ? asJsonList(hashtagsRaw)
              .map((j) => _hashtagFrom(asJsonMap(j)))
              .where((h) => h.name.isNotEmpty)
              .toList()
          : const [],
      popularMusic: musicRaw is List
          ? asJsonList(musicRaw)
              .map((j) => _musicEntityFrom(asJsonMap(j)))
              .where((m) => m.id.isNotEmpty)
              .toList()
          : const [],
      nextCursor: m['nextCursor']?.toString(),
      hasMore: m['hasMore'] == true || m['nextCursor'] != null,
    );
  }

  Future<ShortVideoEntity> fetchVideo(String videoId) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.shortVideo(videoId));
    final m = _unwrap(res.data);
    final raw = m != null ? pick(m, ['video', 'item']) : null;
    if (raw is Map) return _videoFrom(asJsonMap(raw));
    if (m != null && m.containsKey('id')) return _videoFrom(m);
    throw ApiException('Video bulunamadı.');
  }

  Future<ShortVideoEntity> uploadVideo({
    required String videoPath,
    String? thumbnailPath,
    String? description,
  }) async {
    final videoExt = _videoExtension(videoPath);
    final videoMime = _videoContentType(videoPath);
    final form = FormData.fromMap({
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'video': await MultipartFile.fromFile(
        videoPath,
        filename: 'short_${DateTime.now().millisecondsSinceEpoch}.$videoExt',
        contentType: DioMediaType.parse(videoMime),
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
    final m =
        _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) {
      throw ApiException('Beğeni yanıtı okunamadı.');
    }
    return (
      liked: asBool(pick(m, ['liked', 'isLiked', 'likedByMe'])),
      likesCount: asInt(pick(m, ['likesCount', 'likeCount', 'likes'])),
    );
  }

  Future<({bool saved, int savesCount})> toggleSave(String videoId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoSave(videoId),
    );
    final m =
        _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) {
      throw ApiException('Kaydetme yanıtı okunamadı.');
    }
    return (
      saved: asBool(pick(m, ['saved', 'isSaved', 'savedByMe'])),
      savesCount: asInt(pick(m, ['savesCount', 'saveCount', 'saves'])),
    );
  }

  Future<int> recordShare(String videoId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoShare(videoId),
    );
    final m =
        _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) return 0;
    return asInt(pick(m, ['sharesCount', 'shareCount', 'shares']));
  }

  Future<List<ShortCommentEntity>> fetchComments(String videoId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideoComments(videoId),
    );
    final m = _unwrap(res.data);
    final raw = m?['comments'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => _commentFrom(asJsonMap(j)))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  Future<({ShortCommentEntity comment, int commentsCount})> addComment(
    String videoId,
    String content, {
    String? parentId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoComments(videoId),
      data: {
        'content': content.trim(),
        if (parentId != null && parentId.isNotEmpty) 'parentId': parentId,
      },
    );
    final m = _unwrap(res.data);
    if (m == null) throw ApiException('Yorum yanıtı okunamadı.');
    final raw = pick(m, ['comment']);
    if (raw is! Map) throw ApiException('Yorum yanıtı okunamadı.');
    return (
      comment: _commentFrom(asJsonMap(raw)),
      commentsCount: asInt(pick(m, ['commentsCount'])),
    );
  }

  Future<void> deleteComment(String videoId, String commentId) async {
    await _dio.safeDelete(
      ApiEndpoints.shortVideoComment(videoId, commentId),
    );
  }

  Future<({bool liked, int likesCount})> toggleCommentLike(
    String videoId,
    String commentId,
  ) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoCommentLike(videoId, commentId),
    );
    final m =
        _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) {
      throw ApiException('Yorum beğeni yanıtı okunamadı.');
    }
    return (
      liked: asBool(pick(m, ['liked', 'isLiked', 'likedByMe'])),
      likesCount: asInt(pick(m, ['likesCount', 'likeCount', 'likes'])),
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
    final m =
        _unwrap(res.data) ?? (res.data is Map ? asJsonMap(res.data) : null);
    if (m == null) return (counted: false, viewsCount: 0);
    return (
      counted: asBool(pick(m, ['counted'])),
      viewsCount: asInt(pick(m, ['viewsCount'])),
    );
  }

  Future<void> deleteVideo(String videoId) async {
    await _dio.safeDelete(ApiEndpoints.shortVideoDelete(videoId));
  }

  Future<List<ShortVideoEntity>> fetchByUser(
    String userId, {
    ShortUserVideosTab tab = ShortUserVideosTab.videos,
  }) async {
    final tabName = switch (tab) {
      ShortUserVideosTab.liked => 'liked',
      ShortUserVideosTab.saved => 'saved',
      _ => 'videos',
    };
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosByUser(userId),
      query: {'tab': tabName},
    );
    final m = _unwrap(res.data);
    return _videosFrom(m?['videos']);
  }

  Future<ShortProfileStats> fetchProfileStats(String userId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosProfile(userId),
    );
    final m = _unwrap(res.data);
    if (m == null) return const ShortProfileStats();
    return ShortProfileStats(
      videosCount: asInt(pick(m, ['videosCount', 'videoCount'])),
      totalLikes: asInt(pick(m, ['totalLikes', 'likesCount'])),
      totalViews: asInt(pick(m, ['totalViews', 'viewsCount', 'total_views'])),
      followersCount: asInt(pick(m, ['followersCount', 'followerCount'])),
      followingCount: asInt(pick(m, ['followingCount'])),
      isFollowing: asBool(pick(m, ['isFollowing', 'following'])),
    );
  }

  Future<List<ShortVideoEntity>> fetchViewedByMe({int limit = 20}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosViewedMe,
      query: {'limit': limit},
    );
    final m = _unwrap(res.data);
    return _videosFrom(m?['videos']);
  }

  Future<List<ShortVideoEntity>> fetchDuets(String videoId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideoDuets(videoId),
    );
    final m = _unwrap(res.data);
    return _videosFrom(m?['duets'] ?? m?['videos']);
  }

  Future<List<ShortHashtagEntity>> searchHashtags(String query) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosHashtagsSearch,
      query: {'q': query.trim()},
    );
    final m = _unwrap(res.data);
    final raw = m?['hashtags'] ?? m?['items'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => _hashtagFrom(asJsonMap(j)))
        .where((h) => h.name.isNotEmpty)
        .toList();
  }

  Future<List<ShortHashtagEntity>> fetchTrendingHashtags() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosHashtagsTrending,
    );
    final m = _unwrap(res.data);
    final raw = m?['hashtags'] ?? m?['items'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => _hashtagFrom(asJsonMap(j)))
        .where((h) => h.name.isNotEmpty)
        .toList();
  }

  Future<List<ShortMusicEntity>> searchMusic(String query) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosMusic,
      query: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
      },
    );
    final m = _unwrap(res.data);
    final raw = m?['music'] ?? m?['items'] ?? m?['tracks'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => _musicEntityFrom(asJsonMap(j)))
        .where((m) => m.id.isNotEmpty)
        .toList();
  }

  Future<List<ShortVideoEntity>> fetchHashtagVideos(String name) async {
    final encoded = Uri.encodeComponent(name.replaceAll('#', ''));
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosHashtag(encoded),
    );
    final m = _unwrap(res.data);
    return _videosFrom(m?['videos']);
  }

  Future<List<ShortVideoAuthor>> searchMentions(String query) async {
    if (query.trim().isEmpty) return const [];
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideosMentionsSearch,
      query: {'q': query.trim()},
    );
    final m = _unwrap(res.data);
    final raw = m?['users'] ?? m?['mentions'] ?? m?['items'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => _authorFrom(asJsonMap(j)))
        .where((a) => a.id.isNotEmpty)
        .toList();
  }

  Future<void> pinComment(String videoId, String commentId) async {
    await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoCommentPin(videoId, commentId),
    );
  }

  Future<ShortVideoAnalytics> fetchVideoAnalytics(
    String videoId, {
    ShortVideoEntity? fallback,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.shortVideoAnalytics(videoId),
      );
      final m = _unwrap(res.data);
      if (m != null) {
        return ShortVideoAnalytics.fromJson(videoId, m);
      }
    } catch (_) {}
    if (fallback != null) {
      return ShortVideoAnalytics.fromVideo(
        videoId: videoId,
        viewsCount: fallback.viewsCount,
        likesCount: fallback.likesCount,
        commentsCount: fallback.commentsCount,
        sharesCount: fallback.sharesCount,
        savesCount: fallback.savesCount,
      );
    }
    return ShortVideoAnalytics(videoId: videoId);
  }

  Future<ShortVideoEntity> registerVideo(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosRegister,
      data: body,
    );
    final m = _unwrap(res.data);
    final raw = m != null ? pick(m, ['video', 'item']) : null;
    if (raw is Map) return _videoFrom(asJsonMap(raw));
    if (m != null && m.containsKey('id')) return _videoFrom(m);
    throw ApiException('Video kaydı tamamlanamadı.');
  }

  Future<ShortsAiMetadata> suggestMetadata({
    String? description,
    String? videoKey,
    String? liveClipId,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.shortVideosSuggestMetadata,
        data: {
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          if (videoKey != null && videoKey.isNotEmpty) 'videoKey': videoKey,
          if (liveClipId != null && liveClipId.isNotEmpty)
            'liveClipId': liveClipId,
        },
      );
      final m = _unwrap(res.data);
      if (m != null) return ShortsAiMetadata.fromJson(m);
    } catch (_) {}
    return const ShortsAiMetadata();
  }

  Future<ShortLiveClipSource> fetchLiveClip({
    required String liveClipId,
    String? sessionId,
    String? roomId,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideosLiveClip,
      data: {
        'liveClipId': liveClipId,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
        if (roomId != null && roomId.isNotEmpty) 'roomId': roomId,
      },
    );
    final m = _unwrap(res.data);
    if (m == null) throw ApiException('Canlı klip oluşturulamadı.');
    final clip = ShortLiveClipSource.fromJson(m);
    if (clip.clipUrl.isEmpty) {
      throw ApiException('Klip URL alınamadı.');
    }
    return clip;
  }

  Future<List<ShortMusicEntity>> recommendMusic({
    String? description,
    List<String> hashtags = const [],
    String? videoKey,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.shortVideosMusicRecommend,
        query: {
          if (description != null && description.isNotEmpty)
            'description': description,
          if (hashtags.isNotEmpty) 'hashtags': hashtags.join(','),
          if (videoKey != null && videoKey.isNotEmpty) 'videoKey': videoKey,
        },
      );
      final m = _unwrap(res.data);
      final raw = m?['music'] ?? m?['recommendedMusic'] ?? m?['items'];
      if (raw is List) {
        return asJsonList(raw)
            .map((j) => _musicEntityFrom(asJsonMap(j)))
            .where((e) => e.id.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return searchMusic(description ?? '');
  }

  Future<String?> generateSubtitles({
    required String videoId,
    String? videoKey,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.shortVideoSubtitlesGenerate(videoId),
        data: {if (videoKey != null) 'videoKey': videoKey},
      );
      final m = _unwrap(res.data);
      return pick(m ?? {}, ['subtitles', 'subtitleText', 'srt'])?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<LiveGiftEvent?> sendShortGift({
    required String videoId,
    required String giftTypeId,
    required String senderName,
    int quantity = 1,
    String? senderId,
  }) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.shortVideoGifts(videoId),
        data: {
          'giftTypeId': giftTypeId,
          'quantity': quantity,
          if (senderName.trim().isNotEmpty) 'senderName': senderName.trim(),
        },
      );
      final raw = _unwrap(res.data);
      if (raw is Map) {
        return _parseShortGiftEvent(asJsonMap(raw), videoId: videoId);
      }
    } catch (_) {}
    return null;
  }

  LiveGiftEvent? _parseShortGiftEvent(
    Map<String, dynamic> json, {
    required String videoId,
  }) {
    final giftId = pick(json, ['giftTypeId', 'giftId', 'gift_id'])?.toString();
    if (giftId == null || giftId.isEmpty) return null;
    final ts = DateTime.tryParse(
          pick(json, ['createdAt', 'timestamp'])?.toString() ?? '',
        ) ??
        DateTime.now();
    return LiveGiftEvent(
      id: pick(json, ['id'])?.toString() ??
          '$videoId-${ts.millisecondsSinceEpoch}-$giftId',
      senderId: pick(json, ['senderId', 'userId'])?.toString(),
      senderName:
          pick(json, ['senderName', 'sender_name'])?.toString() ?? 'Kullanıcı',
      receiverName:
          pick(json, ['receiverName', 'receiver_name'])?.toString() ?? 'Yayıncı',
      giftId: giftId,
      giftName: pick(json, ['giftName', 'name'])?.toString() ?? 'Hediye',
      quantity: () {
        final q = asInt(pick(json, ['quantity']));
        return q > 0 ? q : 1;
      }(),
      coinCost: asInt(pick(json, ['coinCost', 'totalCost', 'cost'])),
      timestamp: ts,
      animationKey: giftId,
    );
  }

  static String _videoExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'mov';
    if (lower.endsWith('.webm')) return 'webm';
    return 'mp4';
  }

  static String _videoContentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.webm')) return 'video/webm';
    return 'video/mp4';
  }
}
