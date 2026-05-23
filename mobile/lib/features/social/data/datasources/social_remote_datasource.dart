import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../feed/data/models/post_dto.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../../domain/entities/share_fortune_input.dart';
import '../../domain/entities/social_story_ring_entity.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio);

  final Dio _dio;

  /// GET `/api/social/posts` — canlifal.com web `/sosyal` ile aynı JSON.
  Future<({List<PostDto> posts, bool hasMore})> fetch({int page = 1}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPosts,
      query: {'page': page, 'limit': 20},
    );
    final body = res.data;
    if (body is List) {
      final posts = asJsonList(body)
          .map(PostDto.fromApiMap)
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
        .map(PostDto.fromApiMap)
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

  /// GET `/api/stories` — `storyGroups` hikâye halkaları (web ana akış ile aynı).
  Future<List<SocialStoryRingEntity>> fetchStoryRings() async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.feed,
      query: {'page': 1, 'limit': 30},
    );
    return _parseStoryRings(res.data);
  }

  List<SocialStoryRingEntity> _parseStoryRings(dynamic body) {
    if (body is! Map) return const [];
    final m = Map<String, dynamic>.from(body);
    final sg = m['storyGroups'];
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
