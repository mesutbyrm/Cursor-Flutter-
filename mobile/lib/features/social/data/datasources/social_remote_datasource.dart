import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../../feed/data/models/post_dto.dart';

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
}
