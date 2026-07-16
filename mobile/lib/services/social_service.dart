import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';

/// Sosyal post API — kılavuz §9.10 `SocialRepository`.
class SocialService {
  SocialService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/social/posts`
  Future<ApiResponse<List<Map<String, dynamic>>>> getPosts({
    int page = 1,
    int limit = 20,
    String? feed,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPosts,
      query: {
        ...apiPageQuery(page: page, limit: limit),
        if (feed != null && feed.isNotEmpty) 'feed': feed,
      },
    );
    return parseResponse<List<Map<String, dynamic>>>(
      res.data,
      fromData: (data) => ServiceUtils.extractList(
        data,
        keys: const ['posts', 'items', 'data'],
      ),
    );
  }

  /// `POST /api/social/posts`
  Future<Map<String, dynamic>> createPost({
    required String content,
    List<String>? images,
    String? imageUrl,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPosts,
      data: {
        'content': content,
        if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
        if (images != null && images.isNotEmpty) 'images': images,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `GET /api/social/posts/{postId}/comments`
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.socialPostComments(postId),
    );
    return ServiceUtils.extractList(
      res.data,
      keys: const ['comments', 'items', 'data'],
    );
  }

  /// `POST /api/social/posts/{postId}/comments`
  Future<Map<String, dynamic>> comment(
    String postId, {
    required String text,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPostComments(postId),
      data: {'content': text.trim()},
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/social/posts/{postId}/likes`
  Future<Map<String, dynamic>> like(String postId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.socialPostLikes(postId),
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
