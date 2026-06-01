import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/pagination/paged_result.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/user_fortune_entity.dart';
import '../../domain/repositories/fortune_repository.dart';

class FortuneRemoteDataSource {
  FortuneRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PagedResult<UserFortuneEntity>> history({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.userFortunes,
        query: {'page': page, 'limit': limit},
      );
      final parsed = _parseList(res.data, page, limit);
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

  Future<UserFortuneEntity> detail(String fortuneId) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.userFortuneDetail(fortuneId),
    );
    final row = _row(res.data);
    if (row.id.isEmpty) {
      throw const ApiException('Fal kaydı bulunamadı', statusCode: 404);
    }
    return row;
  }

  Future<UserFortuneEntity> save(SaveFortuneInput input) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userFortunes,
      data: {
        'type': input.type,
        if (input.slug != null) 'slug': input.slug,
        if (input.question != null) 'question': input.question,
        if (input.answer != null) 'answer': input.answer,
        if (input.summary != null) 'summary': input.summary,
        if (input.detail != null) 'detail': input.detail,
        if (input.luckyNumber != null) 'luckyNumber': input.luckyNumber,
        if (input.luckyColor != null) 'luckyColor': input.luckyColor,
      },
    );
    return _row(res.data);
  }

  PagedResult<UserFortuneEntity>? _parseList(
    dynamic body,
    int page,
    int limit,
  ) {
    if (body is String) return null;
    List<dynamic> raw = [];
    int? total;

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'];
      if (err != null) throw ApiException(err.toString());
      raw = asJsonList(pick(map, ['fortunes', 'items', 'data']) ?? []);
      total = asInt(pick(map, ['total', 'count']));
    } else if (body is List) {
      raw = asJsonList(body);
    }

    final items = raw.map(_row).where((f) => f.id.isNotEmpty).toList();
    final hasMore =
        total != null ? page * limit < total : items.length >= limit;
    return PagedResult(items: items, hasMore: hasMore);
  }

  int? _optionalInt(dynamic v) {
    if (v == null) return null;
    final n = asInt(v);
    return n == 0 && v.toString() != '0' ? null : n;
  }

  UserFortuneEntity _row(dynamic json) {
    final m = json is Map ? asJsonMap(json) : <String, dynamic>{};
    return UserFortuneEntity(
      id: pick(m, ['id', '_id'])?.toString() ?? '',
      type: pick(m, ['type', 'fortuneType', 'slug'])?.toString() ?? '',
      slug: pick(m, ['slug'])?.toString(),
      question: pick(m, ['question', 'title'])?.toString(),
      answer: pick(m, ['answer', 'result'])?.toString(),
      summary: pick(m, ['summary'])?.toString(),
      detail: pick(m, ['detail'])?.toString(),
      luckyNumber: _optionalInt(pick(m, ['luckyNumber'])),
      luckyColor: pick(m, ['luckyColor'])?.toString(),
      createdAt: DateTime.tryParse(
        pick(m, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
    );
  }
}
