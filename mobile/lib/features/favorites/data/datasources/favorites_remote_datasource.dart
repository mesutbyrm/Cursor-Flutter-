import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/pagination/paged_result.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/user_fortune_entity.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PagedResult<UserFortuneEntity>> fortuneHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.userFortunes,
        query: {'page': page, 'limit': limit},
      );
      final parsed = _parseFortunes(res.data, page, limit);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Fal geçmişi için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const PagedResult(items: [], hasMore: false);
  }

  PagedResult<UserFortuneEntity>? _parseFortunes(
    dynamic body,
    int page,
    int limit,
  ) {
    if (body is String) return null;
    if (body is! Map && body is! List) return null;

    List<dynamic> raw = [];
    int? total;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'];
      if (err != null) throw ApiException(err.toString());
      raw = asJsonList(pick(map, ['fortunes', 'items', 'data']) ?? []);
      total = asInt(pick(map, ['total', 'count']));
    } else {
      raw = asJsonList(body);
    }

    final items = raw.map(_row).where((f) => f.id.isNotEmpty).toList();
    final hasMore = total != null
        ? page * limit < total
        : items.length >= limit;

    return PagedResult(items: items, hasMore: hasMore);
  }

  UserFortuneEntity _row(dynamic json) {
    final m = asJsonMap(json);
    return UserFortuneEntity(
      id: pick(m, ['id', '_id'])?.toString() ?? '',
      type: pick(m, ['type', 'fortuneType', 'slug'])?.toString() ?? '',
      question: pick(m, ['question', 'title'])?.toString(),
      answer: pick(m, ['answer', 'result', 'summary'])?.toString(),
      createdAt: DateTime.tryParse(
        pick(m, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
    );
  }
}
