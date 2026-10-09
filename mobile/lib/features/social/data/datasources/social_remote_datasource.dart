import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/media/cloud_upload_service.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/data/models/post_dto.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../../domain/entities/share_fortune_input.dart';
import '../../domain/entities/social_comment_entity.dart';
import '../../domain/entities/social_story_ring_entity.dart';

/// GET `/api/social/fortune-viewers` yanıtı.
class FortuneViewers {
  const FortuneViewers({required this.count, required this.users});
  final int count;
  final List<UserEntity> users;
}

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio, {CloudMediaUploadService? upload})
    : _upload = upload;

  final Dio _dio;
  final CloudMediaUploadService? _upload;

  /// GET `/api/social/fortune-viewers?type=` — bu fal türüne kaç kez
  /// baktırıldığı ve türü herkese açık paylaşan son kullanıcılar.
  /// Uç yoksa / hata olursa `null` (çağıran akıştan türetir).
  Future<FortuneViewers?> fetchFortuneViewers(String type, {int limit = 6}) async {
    final t = type.trim();
    if (t.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.socialFortuneViewers,
        query: {'type': t, 'limit': limit},
      );
      final body = res.data;
      if (body is! Map) return null;
      final data = body['data'];
      if (data is! Map) return null;
      final raw = data['users'];
      final users = <UserEntity>[
        if (raw is List)
          for (final u in raw)
            if (u is Map)
              UserDto.fromApiMap(Map<String, dynamic>.from(u)).toEntity(),
      ];
      final c = data['count'];
      return FortuneViewers(
        count: c is num ? c.toInt() : int.tryParse('$c') ?? 0,
        users: users.where((u) => u.id.isNotEmpty).toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }

  /// GET `/api/social/posts` — canlifal.com web `/sosyal` ile aynı JSON.
  Future<({List<PostEntity> posts, bool hasMore})> fetch({
    int page = 1,
    String? authorId,
    String? currentUserId,
    String feed = 'following',
    bool forceRefresh = false,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPosts,
      forceRefresh: forceRefresh,
      query: {
        'page': page,
        'limit': 20,
        'feed': feed,
        if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
      },
    );
    return _parsePostsPage(res.data, currentUserId: currentUserId);
  }

  /// GET `/api/users/{userId}/posts` — kılavuz §9.10 `getUserPosts`.
  Future<({List<PostEntity> posts, bool hasMore})> fetchUserPosts({
    required String userId,
    int page = 1,
    String? currentUserId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userPosts(userId),
      query: {'page': page, 'limit': 20},
    );
    return _parsePostsPage(res.data, currentUserId: currentUserId);
  }

  ({List<PostEntity> posts, bool hasMore}) _parsePostsPage(
    dynamic body, {
    String? currentUserId,
  }) {
    if (body is List) {
      final posts = asJsonList(body)
          .map((j) => PostDto.entityFromApiMap(j, currentUserId: currentUserId))
          .where((p) => p.id.isNotEmpty)
          .toList();
      return (posts: posts, hasMore: posts.length >= 20);
    }
    final m = _unwrapBody(body);
    if (m == null) {
      return (posts: const <PostEntity>[], hasMore: false);
    }
    var rawPosts = pick(m, ['posts', 'items', 'results', 'data']);
    if (rawPosts is! List && m['posts'] is List) {
      rawPosts = m['posts'];
    }
    if (rawPosts is! List) {
      return (posts: const <PostEntity>[], hasMore: false);
    }
    final posts = asJsonList(rawPosts)
        .map((j) => PostDto.entityFromApiMap(j, currentUserId: currentUserId))
        .where((p) => p.id.isNotEmpty)
        .toList();
    var hasMore = false;
    final pag = m['pagination'];
    if (pag is Map) {
      final pm = Map<String, dynamic>.from(pag);
      final totalPages = asInt(pm['totalPages']);
      final current = asInt(pm['page']);
      if (totalPages > 0) {
        hasMore = current < totalPages;
      }
    }
    if (!hasMore) {
      if (m['hasMore'] == true || m['has_more'] == true) {
        hasMore = true;
      } else if (posts.length >= 20) {
        hasMore = true;
      }
    }
    return (posts: posts, hasMore: hasMore);
  }

  /// GET `/api/social/posts/{postId}` — tek gönderi detayı (kılavuz §9.10).
  Future<PostEntity?> fetchPost(String postId, {String? currentUserId}) async {
    final id = postId.trim();
    if (id.isEmpty) return null;
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.socialPost(id));
      final m = _unwrapBody(res.data);
      if (m == null) return null;
      final postJson = m['post'] is Map ? asJsonMap(m['post']) : m;
      return PostDto.entityFromApiMap(postJson, currentUserId: currentUserId);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// POST `/api/social/posts` — yalnızca JSON okur (`request.json()`):
  /// `{content, postType: text|fortune|horoscope, imageUrl?, youtubeUrl?}`.
  /// Önceden görsel/video multipart gönderiliyordu; sunucu gövdeyi JSON
  /// olarak çözemediği için paylaşım başarısız oluyordu. Görsel önce
  /// `/api/upload/presigned` ile yüklenir, adresi `imageUrl` olarak gider.
  Future<PostDto> createPost(CreateSocialPostInput input) async {
    final caption = input.caption.trim();
    final type = socialPostTypeForBackend(input.resolvedType);

    if (input.hasVideo) {
      throw const ApiException(
        'Video paylaşımı Kısa Videolar bölümünden yapılır.',
      );
    }
    String? imageUrl;
    if (input.hasImage) {
      final upload = _upload;
      if (upload == null) {
        throw const ApiException('Görsel yükleme kullanılamıyor');
      }
      imageUrl = await upload.uploadImageFile(
        File(input.imagePath!),
        folder: 'social',
        isPublic: true,
      );
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPosts,
      data: {
        'content': caption,
        'caption': caption,
        'text': caption,
        'postType': type,
        'type': type,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      },
    );
    return _parseCreatedPost(res.data, caption: caption, type: type);
  }

  PostDto _parseCreatedPost(
    dynamic body, {
    required String caption,
    required String type,
  }) {
    final m = _unwrapBody(body);
    if (m != null) {
      final postRaw = pick(m, ['post', 'item', 'result']) ?? m;
      if (postRaw is Map) {
        return PostDto.fromApiMap(asJsonMap(postRaw));
      }
      if (m.containsKey('id')) {
        return PostDto.fromApiMap(m);
      }
    }
    throw ApiException('Sunucu paylaşım yanıtı okunamadı.');
  }

  Map<String, dynamic>? _unwrapBody(dynamic body) {
    if (body is! Map) return null;
    final m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] is Map) {
      return Map<String, dynamic>.from(m['data']);
    }
    return m;
  }

  /// Fal paylaşımı — kanonik `POST /api/social/posts`.
  Future<PostDto> shareFortuneAuto(ShareFortuneInput input) async {
    // `/api/social/posts/auto-fortune` backend'de yok (`[postId]` ucuna düşüp
    // 405 dönüyordu) — doğrudan `POST /api/social/posts`.
    return _shareFortuneViaCanonicalPost(input);
  }

  Future<PostDto> _shareFortuneViaCanonicalPost(ShareFortuneInput input) async {
    final summary = input.summary.trim();
    final detail = input.detail?.trim() ?? '';
    final caption = detail.isNotEmpty && detail.length > summary.length
        ? detail
        : (detail.isNotEmpty ? '$summary\n\n$detail' : summary);
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPosts,
      data: {
        'caption': caption,
        'text': caption,
        'content': caption,
        'postType': 'fortune',
        'type': 'fortune',
        'fortuneType': input.fortuneType ?? input.fortuneSlug,
        if (detail.isNotEmpty) 'detail': detail,
        if (input.fortuneId != null && input.fortuneId!.isNotEmpty)
          'fortuneId': input.fortuneId,
      },
    );
    return _parseCreatedPost(res.data, caption: caption, type: 'fortune');
  }

  Future<void> deletePost(String postId) async {
    await _dio.safeDelete(ApiEndpoints.socialPostDelete(postId));
  }

  /// POST `/api/social/posts/:id/view` — kılavuz §9.10.
  Future<void> registerPostView(String postId) async {
    if (postId.trim().isEmpty) return;
    try {
      await _dio.safePost<dynamic>(ApiEndpoints.socialPostView(postId));
    } catch (_) {}
  }

  /// POST `/api/social/posts/:id/likes` — beğeni toggle.
  Future<({bool liked, int likesCount})> toggleLike(String postId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPostLikes(postId),
    );
    return _parseLikeResult(res.data);
  }

  ({bool liked, int likesCount}) _parseLikeResult(dynamic body) {
    final m = _unwrapBody(body) ?? (body is Map ? asJsonMap(body) : null);
    if (m == null) return (liked: true, likesCount: 0);
    return (
      liked:
          m['liked'] == true || m['isLiked'] == true || m['likedByMe'] == true,
      likesCount: asInt(pick(m, ['likesCount', 'likeCount', 'likes', 'count'])),
    );
  }

  Future<List<SocialCommentEntity>> fetchComments(String postId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPostComments(postId),
    );
    return _parseComments(res.data);
  }

  Future<SocialCommentEntity> addComment(String postId, String text) async {
    final content = text.trim();
    if (content.isEmpty) {
      throw const ApiException('Yorum boş olamaz');
    }
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPostComments(postId),
      data: {'content': content, 'text': content},
    );
    final list = _parseComments(res.data);
    if (list.isNotEmpty) return list.first;
    final m = _unwrapBody(res.data) ?? asJsonMap(res.data);
    final commentRaw = pick(m, ['comment', 'item', 'data']) ?? m;
    if (commentRaw is Map) {
      final parsed = _parseComments([commentRaw]);
      if (parsed.isNotEmpty) return parsed.first;
    }
    throw const ApiException('Yorum yanıtı okunamadı');
  }

  List<SocialCommentEntity> _parseComments(dynamic body) {
    dynamic list = body;
    if (body is Map) {
      final m = _unwrapBody(body) ?? asJsonMap(body);
      list = pick(m, ['comments', 'items', 'data']) ?? body;
    }
    if (list is! List) return const [];
    return asJsonList(
      list,
    ).map(_commentFromMap).where((c) => c.id.isNotEmpty).toList();
  }

  SocialCommentEntity _commentFromMap(dynamic raw) {
    final m = asJsonMap(raw);
    final userRaw = pick(m, ['user', 'author', 'profile']);
    final userMap = userRaw is Map ? asJsonMap(userRaw) : <String, dynamic>{};
    final authorDto = UserDto.fromJson(userMap);
    return SocialCommentEntity(
      id: pick(m, ['id', '_id'])?.toString() ?? '',
      author: authorDto.toEntity(role: authorDto.roleFrom(userMap)),
      text: pick(m, ['content', 'text', 'body'])?.toString() ?? '',
      createdAt: DateTime.tryParse(
        pick(m, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
    );
  }

  /// POST `/api/stories` — presigned yükleme + JSON (üretim sözleşmesi).
  Future<void> createStoryImage(String imagePath) =>
      _createStory(imagePath, mediaType: 'image');

  /// POST `/api/stories` — video hikâye.
  Future<void> createStoryVideo(String videoPath) =>
      _createStory(videoPath, mediaType: 'video');

  Future<void> _createStory(
    String localPath, {
    required String mediaType,
  }) async {
    final upload = _upload;
    if (upload == null) {
      throw const ApiException('Hikâye yüklemesi kullanılamıyor');
    }
    final file = File(localPath);
    if (!await file.exists()) {
      throw const ApiException('Medya bulunamadı');
    }
    final mediaUrl = await upload.uploadMediaFile(
      file,
      folder: 'stories',
      isPublic: true,
    );
    await _dio.safePost<dynamic>(
      ApiEndpoints.feed,
      data: <String, dynamic>{'mediaUrl': mediaUrl, 'mediaType': mediaType},
    );
  }

  /// DELETE `/api/stories` — `{ storyId }` veya `{ id }`.
  Future<void> deleteStory(String storyId) async {
    final id = storyId.trim();
    if (id.isEmpty) {
      throw const ApiException('Hikâye kimliği boş');
    }
    await _dio.safeDelete<dynamic>(
      ApiEndpoints.feed,
      data: <String, dynamic>{'storyId': id, 'id': id},
    );
  }

  /// GET `/api/stories` — birincil (prod). `/api/social/stories` yalnızca yedek.
  Future<List<SocialStoryRingEntity>> fetchStoryRings() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.feed,
      query: {'page': 1, 'limit': 30},
    );
    var rings = _parseStoryRings(res.data);
    if (rings.isEmpty) {
      try {
        final alt = await _dio.safeGet<dynamic>(
          ApiEndpoints.socialStories,
          query: {'page': 1, 'limit': 30},
        );
        rings = _parseStoryRings(alt.data);
      } catch (_) {}
    }
    return rings;
  }

  List<SocialStoryRingEntity> _parseStoryRings(dynamic body) {
    if (body is String) {
      final t = body.trimLeft();
      if (t.startsWith('<!DOCTYPE') || t.toLowerCase().startsWith('<html')) {
        return const [];
      }
      return const [];
    }
    if (body is! Map) return const [];
    var m = Map<String, dynamic>.from(body);
    if (m['success'] == true && m['data'] != null) {
      final data = m['data'];
      if (data is Map) m = Map<String, dynamic>.from(data);
    }
    final sg = m['storyGroups'] ?? m['groups'] ?? m['rings'];
    if (sg is! List || sg.isEmpty) return const [];

    final rings = <SocialStoryRingEntity>[];
    for (final g in sg) {
      final gm = g is Map<String, dynamic> ? g : asJsonMap(g);
      if (gm.isEmpty) continue;

      final userRaw = pick(gm, ['user', 'author', 'owner', 'profile']);
      final userMap = userRaw is Map ? asJsonMap(userRaw) : <String, dynamic>{};
      if (userMap.isEmpty) continue;

      final authorDto = UserDto.fromJson(userMap);
      final user = authorDto.toEntity(role: authorDto.roleFrom(userMap));
      if (user.id.isEmpty) continue;

      final stories = <SocialStoryItemEntity>[];
      String? preview;
      final storiesRaw = pick(gm, ['stories', 'items', 'data', 'posts']);
      if (storiesRaw is List && storiesRaw.isNotEmpty) {
        for (final raw in storiesRaw) {
          final story = _storyItemFromMap(asJsonMap(raw));
          if (story != null) stories.add(story);
        }
        if (stories.isNotEmpty) preview = stories.first.mediaUrl;
      }

      rings.add(
        SocialStoryRingEntity(
          user: user,
          previewUrl: preview,
          stories: stories,
        ),
      );
    }
    return rings;
  }

  SocialStoryItemEntity? _storyItemFromMap(Map<String, dynamic> json) {
    final media = pick(json, [
      'mediaUrl',
      'media_url',
      'thumbnailUrl',
      'imageUrl',
      'image',
      'videoUrl',
      'url',
    ])?.toString();
    if (media == null || media.trim().isEmpty) return null;
    return SocialStoryItemEntity(
      id:
          pick(json, ['id', '_id', 'storyId'])?.toString() ??
          media.hashCode.toString(),
      mediaUrl: media,
      type: pick(json, ['type', 'mediaType'])?.toString() ?? 'image',
      caption: pick(json, ['caption', 'text', 'content'])?.toString(),
      createdAt: DateTime.tryParse(
        pick(json, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
      durationMs: _storyDurationMs(json),
    );
  }

  int? _storyDurationMs(Map<String, dynamic> json) {
    final raw = pick(json, [
      'durationMs',
      'duration_ms',
      'displayDurationMs',
      'duration',
    ]);
    if (raw == null) return null;
    if (raw is num) {
      final v = raw.toInt();
      return v > 1000 ? v : v * 1000;
    }
    return int.tryParse(raw.toString());
  }
}


/// Backend yalnızca `fortune`, `text`, `horoscope` gönderi türlerini kabul eder.
String socialPostTypeForBackend(String type) {
  final t = type.trim().toLowerCase();
  if (t == 'fortune' || t == 'horoscope') return t;
  return 'text';
}
