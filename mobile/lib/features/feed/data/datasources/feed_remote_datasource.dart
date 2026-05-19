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
    final body = res.data;
    dynamic list;
    if (body is Map<String, dynamic>) {
      list = pick(body, ['items', 'data', 'posts', 'results', 'feed']);
    } else {
      list = body;
    }
    return asJsonList(list).map(PostDto.fromJson).toList();
  }
}
