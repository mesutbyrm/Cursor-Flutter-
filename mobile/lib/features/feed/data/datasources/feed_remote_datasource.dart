import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/post_dto.dart';

class FeedRemoteDataSource {
  FeedRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<PostDto>> fetch({int page = 1}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.feed,
      query: {'page': page, 'limit': 20},
    );
    return _parseFeed(res.data);
  }

  /// canlifal.com `/api/stories` → `{ "storyGroups": [ { user, stories: [...] } ] }`
  /// Ayrıca klasik `{ "posts": [...] }` ve HTML (oturumsuz) yanıtları.
  List<PostDto> _parseFeed(dynamic body) {
    if (body is String) {
      final t = body.trimLeft();
      if (t.startsWith('<!DOCTYPE') || t.toLowerCase().startsWith('<html')) {
        return const [];
      }
      return const [];
    }

    if (body is List) {
      return asJsonList(body)
          .map(PostDto.fromApiMap)
          .where((p) => p.id.isNotEmpty)
          .toList();
    }

    if (body is! Map) return const [];

    final m = Map<String, dynamic>.from(body);

    final fromStories = _postsFromStoryGroups(m['storyGroups']);
    if (fromStories.isNotEmpty) return fromStories;

    final list = pick(m, ['items', 'data', 'posts', 'results', 'feed', 'reels']);
    return asJsonList(list)
        .map(PostDto.fromApiMap)
        .where((p) => p.id.isNotEmpty)
        .toList();
  }

  List<PostDto> _postsFromStoryGroups(dynamic sg) {
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
        if (_isFortuneStoryMap(sm)) continue;

        final merged = Map<String, dynamic>.from(sm);
        merged.putIfAbsent(
          'author',
          () => user.isNotEmpty
              ? user
              : asJsonMap(pick(sm, ['user', 'author', 'owner'])),
        );

        final p = PostDto.fromApiMap(merged);
        if (p.id.isNotEmpty) out.add(p);
      }
    }
    return out;
  }

  static bool _isFortuneStoryMap(Map<String, dynamic> sm) {
    final type =
        pick(sm, ['type', 'storyType', 'category', 'kind'])?.toString().toLowerCase() ??
            '';
    if (type.contains('fal') ||
        type.contains('tarot') ||
        type.contains('fortune') ||
        type.contains('kahve')) {
      return true;
    }
    final text = [
      pick(sm, ['caption', 'text', 'title', 'description']),
    ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');
    return text.contains('fal') || text.contains('tarot');
  }
}
