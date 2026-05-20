import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../feed/data/models/post_dto.dart';
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
    if (body is! Map) {
      return (posts: const <PostDto>[], hasMore: false);
    }
    final m = Map<String, dynamic>.from(body);
    final rawPosts = m['posts'];
    if (rawPosts is! List) {
      return (posts: const <PostDto>[], hasMore: false);
    }

    final posts = asJsonList(rawPosts)
        .map(PostDto.fromJson)
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
