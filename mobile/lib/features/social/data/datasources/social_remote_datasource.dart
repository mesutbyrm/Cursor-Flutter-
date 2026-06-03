import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../feed/data/models/post_dto.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../../domain/entities/share_fortune_input.dart';
import '../../domain/entities/social_comment_entity.dart';
import '../../domain/entities/social_story_ring_entity.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio);

  final Dio _dio;

  /// GET `/api/social/posts` — canlifal.com web `/sosyal` ile aynı JSON.
  Future<({List<PostDto> posts, bool hasMore})> fetch({
    int page = 1,
    String? authorId,
    String? currentUserId,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPosts,
      query: {
        'page': page,
        'limit': 20,
        if (authorId != null && authorId.isNotEmpty) 'authorId': authorId,
      },
    );
    final body = res.data;
    if (body is List) {
      final posts = asJsonList(body)
          .map((j) => PostDto.fromApiMap(j, currentUserId: currentUserId))
          .where((p) => p.id.isNotEmpty)
          .toList();
      return (posts: posts, hasMore: posts.length >= 20);
    }
    final m = _unwrapBody(body);
    if (m == null) {
      return (posts: const <PostDto>[], hasMore: false);
    }
    var rawPosts = m['posts'];
    if (rawPosts is! List && body is List) {
      rawPosts = body;
    }
    if (rawPosts is! List) {
      return (posts: const <PostDto>[], hasMore: false);
    }

    final posts = asJsonList(rawPosts)
        .map((j) => PostDto.fromApiMap(j, currentUserId: currentUserId))
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

    return (posts: posts, hasMore: hasMore);
  }

  /// POST `/api/social/posts` — metin veya görsel paylaşım (multipart / JSON).
  Future<PostDto> createPost(CreateSocialPostInput input) async {
    final caption = input.caption.trim();
    final type = input.hasMedia ? 'image' : 'text';

    Response<dynamic> res;
    if (input.hasMedia) {
      final path = input.imagePath!;
      final form = FormData.fromMap({
        'caption': caption,
        'text': caption,
        'content': caption,
        'description': caption,
        'postType': type,
        'type': type,
        'image': await MultipartFile.fromFile(
          path,
          filename: 'post_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });
      res = await _dio.safePost<dynamic>(
        ApiEndpoints.socialPosts,
        data: form,
        options: Options(contentType: 'multipart/form-data'),
      );
    } else {
      res = await _dio.safePost<dynamic>(
        ApiEndpoints.socialPosts,
        data: {
          'caption': caption,
          'text': caption,
          'content': caption,
          'postType': type,
          'type': type,
        },
      );
    }

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

  /// POST `/api/social/posts/auto-fortune`
  Future<PostDto> shareFortuneAuto(ShareFortuneInput input) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPostsAutoFortune,
      data: {
        'fortuneSlug': input.fortuneSlug,
        'fortuneType': input.fortuneType ?? input.fortuneSlug,
        'summary': input.summary,
        if (input.detail != null && input.detail!.isNotEmpty)
          'detail': input.detail,
      },
    );
    return _parseCreatedPost(res.data, caption: input.summary, type: 'fortune');
  }

  Future<void> deletePost(String postId) async {
    await _dio.safeDelete(ApiEndpoints.socialPostDelete(postId));
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
      liked: m['liked'] == true ||
          m['isLiked'] == true ||
          m['likedByMe'] == true,
      likesCount: asInt(
        pick(m, ['likesCount', 'likeCount', 'likes', 'count']),
      ),
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
    return asJsonList(list).map(_commentFromMap).where((c) => c.id.isNotEmpty).toList();
  }

  SocialCommentEntity _commentFromMap(dynamic raw) {
    final m = asJsonMap(raw);
    final userRaw = pick(m, ['user', 'author', 'profile']);
    final userMap = userRaw is Map ? asJsonMap(userRaw) : <String, dynamic>{};
    return SocialCommentEntity(
      id: pick(m, ['id', '_id'])?.toString() ?? '',
      author: UserDto.fromJson(userMap).toEntity(),
      text: pick(m, ['content', 'text', 'body'])?.toString() ?? '',
      createdAt: DateTime.tryParse(
        pick(m, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
    );
  }

  /// POST `/api/stories` — görsel hikâye (multipart).
  Future<void> createStoryImage(String imagePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: 'story_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
      'media': await MultipartFile.fromFile(
        imagePath,
        filename: 'story_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });
    await _dio.safePost<dynamic>(
      ApiEndpoints.feed,
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
  }

  /// GET `/api/stories` — `storyGroups` hikâye halkaları (web ana akış ile aynı).
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
      final userMap =
          userRaw is Map ? asJsonMap(userRaw) : <String, dynamic>{};
      if (userMap.isEmpty) continue;

      final user = UserDto.fromJson(userMap).toEntity();
      if (user.id.isEmpty) continue;

      String? preview;
      final storiesRaw = pick(gm, ['stories', 'items', 'data', 'posts']);
      if (storiesRaw is List && storiesRaw.isNotEmpty) {
        final first = asJsonMap(storiesRaw.first);
        preview = pick(first, [
          'mediaUrl',
          'media_url',
          'thumbnailUrl',
          'imageUrl',
          'videoUrl',
        ]) as String?;
      }

      rings.add(SocialStoryRingEntity(user: user, previewUrl: preview));
    }
    return rings;
  }
}
