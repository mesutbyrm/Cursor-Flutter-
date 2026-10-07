import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/content_detail_models.dart';

/// İçerik detay uçları — blog, burç blogu, rüya sembolü, TikTok videoları.
class ContentDetailRemoteDataSource {
  ContentDetailRemoteDataSource(this._dio);

  final Dio _dio;

  /// `GET /api/blog?slug=` → `{post}`.
  Future<BlogPostItem> fetchBlogPost(String slug) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.blog,
      query: {'slug': slug},
    );
    final body = unwrapContentBody(res.data);
    return BlogPostItem.fromJson(asJsonMap(body['post'] ?? body));
  }

  /// `GET /api/blog/related?slug=&limit=` → `{posts}`.
  Future<List<BlogPostItem>> fetchRelatedPosts(String slug, {int limit = 4}) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.blogRelated,
      query: {'slug': slug, 'limit': limit},
    );
    return _posts(res.data);
  }

  /// `GET /api/blog/interactions?postId=`.
  Future<BlogInteractions> fetchInteractions(String postId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.blogInteractions,
      query: {'postId': postId},
    );
    return BlogInteractions.fromJson(unwrapContentBody(res.data));
  }

  /// `POST /api/blog/like {postId}` → `{liked}` (aç/kapa).
  Future<bool> toggleLike(String postId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.blogLike,
      data: {'postId': postId},
    );
    return asBool(unwrapContentBody(res.data)['liked']);
  }

  /// `POST /api/blog/favorite {postId}` → `{favorited}` (aç/kapa).
  Future<bool> toggleFavorite(String postId) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.blogFavorite,
      data: {'postId': postId},
    );
    return asBool(unwrapContentBody(res.data)['favorited']);
  }

  /// `GET /api/blog/zodiac` → `{signs}`.
  Future<List<ZodiacBlogSign>> fetchZodiacSigns() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.blogZodiac);
    return asJsonList(unwrapContentBody(res.data)['signs'])
        .map(ZodiacBlogSign.fromJson)
        .where((s) => s.sign.isNotEmpty)
        .toList();
  }

  /// `GET /api/blog/zodiac?sign=` → `{posts, sign}`.
  Future<List<BlogPostItem>> fetchZodiacPosts(String sign) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.blogZodiac,
      query: {'sign': sign},
    );
    return _posts(res.data);
  }

  /// `GET /api/dream-symbols/{slug}`.
  Future<DreamSymbolDetail> fetchDreamSymbol(String slug) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.dreamSymbol(slug));
    return DreamSymbolDetail.fromJson(unwrapContentBody(res.data));
  }

  /// `GET /api/tiktok-videos` → `{videos, categories}`.
  Future<List<TiktokVideoItem>> fetchTiktokVideos() async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.tiktokVideos);
    return asJsonList(unwrapContentBody(res.data)['videos'])
        .map(TiktokVideoItem.fromJson)
        .where((v) => v.id.isNotEmpty)
        .toList();
  }

  /// `GET /api/tiktok-videos/{id}` → `{video, related}`.
  Future<TiktokVideoDetail> fetchTiktokVideo(String id) async {
    final res = await _dio.safeGet<dynamic>(ApiEndpoints.tiktokVideo(id));
    return TiktokVideoDetail.fromJson(unwrapContentBody(res.data));
  }

  List<BlogPostItem> _posts(dynamic body) =>
      asJsonList(unwrapContentBody(body)['posts'])
          .map(BlogPostItem.fromJson)
          .where((p) => p.slug.isNotEmpty)
          .toList();
}

final contentDetailRemoteProvider = Provider<ContentDetailRemoteDataSource>(
  (ref) => ContentDetailRemoteDataSource(ref.watch(dioProvider)),
);

final blogPostProvider =
    FutureProvider.autoDispose.family<BlogPostItem, String>(
  (ref, slug) => ref.watch(contentDetailRemoteProvider).fetchBlogPost(slug),
);

final blogRelatedProvider =
    FutureProvider.autoDispose.family<List<BlogPostItem>, String>(
  (ref, slug) => ref.watch(contentDetailRemoteProvider).fetchRelatedPosts(slug),
);

final blogZodiacSignsProvider =
    FutureProvider.autoDispose<List<ZodiacBlogSign>>(
  (ref) => ref.watch(contentDetailRemoteProvider).fetchZodiacSigns(),
);

final blogZodiacPostsProvider =
    FutureProvider.autoDispose.family<List<BlogPostItem>, String>(
  (ref, sign) => ref.watch(contentDetailRemoteProvider).fetchZodiacPosts(sign),
);

final dreamSymbolProvider =
    FutureProvider.autoDispose.family<DreamSymbolDetail, String>(
  (ref, slug) => ref.watch(contentDetailRemoteProvider).fetchDreamSymbol(slug),
);

final tiktokVideosProvider = FutureProvider.autoDispose<List<TiktokVideoItem>>(
  (ref) => ref.watch(contentDetailRemoteProvider).fetchTiktokVideos(),
);

final tiktokVideoProvider =
    FutureProvider.autoDispose.family<TiktokVideoDetail, String>(
  (ref, id) => ref.watch(contentDetailRemoteProvider).fetchTiktokVideo(id),
);
