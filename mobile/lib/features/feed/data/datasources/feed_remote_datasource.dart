import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/post_dto.dart';

class FeedRemoteDataSource {
  FeedRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PostDto>> fetch({int page = 1, String? currentUserId}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.feed,
      query: {'page': page, 'limit': 20},
    );
    var posts = _parseFeed(res.data, currentUserId: currentUserId);
    if (posts.isEmpty) {
      try {
        final alt = await _dio.safeGet<dynamic>(
          ApiEndpoints.socialPosts,
          query: {'page': page, 'limit': 20},
        );
        posts = _parseSocialPosts(alt.data, currentUserId: currentUserId);
      } catch (_) {}
    }
    return posts;
  }

  List<PostDto> _parseSocialPosts(dynamic body, {String? currentUserId}) {
    if (body is! Map) return const [];
    final m = asJsonMap(body);
    final raw = m['posts'];
    if (raw is! List) return const [];
    return asJsonList(raw)
        .map((j) => PostDto.fromApiMap(j, currentUserId: currentUserId))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  /// canlifal.com `/api/stories` → `{ "storyGroups": [ { user, stories: [...] } ] }`
  /// Ayrıca klasik `{ "posts": [...] }` ve HTML (oturumsuz) yanıtları.
  List<PostDto> _parseFeed(dynamic body, {String? currentUserId}) {
    if (body is String) {
      final t = body.trimLeft();
      if (t.startsWith('<!DOCTYPE') || t.toLowerCase().startsWith('<html')) {
        return const [];
      }
      return const [];
    }

    if (body is List) {
      return asJsonList(body)
          .map((j) => PostDto.fromApiMap(j, currentUserId: currentUserId))
          .where((p) => p.id.isNotEmpty)
          .toList();
    }

    if (body is! Map) return const [];

    final m = Map<String, dynamic>.from(body);

    final fromStories =
        _postsFromStoryGroups(m['storyGroups'], currentUserId: currentUserId);
    if (fromStories.isNotEmpty) return fromStories;

    final list = pick(m, ['items', 'data', 'posts', 'results', 'feed', 'reels']);
    return asJsonList(list)
        .map((j) => PostDto.fromApiMap(j, currentUserId: currentUserId))
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  List<PostDto> _postsFromStoryGroups(dynamic sg, {String? currentUserId}) {
    if (sg is! List || sg.isEmpty) return const [];

    final out = <PostDto>[];
    for (final g in sg) {
      final gm = g is Map<String, dynamic> ? g : asJsonMap(g);
      if (gm.isEmpty) continue;

      final user = asJsonMap(pick(gm, ['user', 'author', 'owner', 'profile']));
      final storiesRaw = pick(gm, ['stories', 'items', 'data', 'posts']);
      if (storiesRaw is! List) continue;

      for (final st in storiesRaw) {
        final sm = asJsonMap(st);
        if (sm.isEmpty) continue;

        final merged = Map<String, dynamic>.from(sm);
        merged.putIfAbsent(
          'author',
          () => user.isNotEmpty
              ? user
              : asJsonMap(pick(sm, ['user', 'author', 'owner'])),
        );

        final p = PostDto.fromApiMap(merged, currentUserId: currentUserId);
        if (p.id.isNotEmpty) out.add(p);
      }
    }
    return out;
  }
}
