import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../models/search_user_dto.dart';
import '../../domain/entities/search_user_entity.dart';

class SearchRemoteDataSource {
  SearchRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SearchUserEntity>> searchUsers(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];

    try {
      final res = await _dio.safeGet<dynamic>(
        ApiEndpoints.usersSearch(q),
      );
      final parsed = _parseList(res.data);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Arama için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  List<SearchUserEntity>? _parseList(dynamic body) {
    if (body is String) {
      if (body.contains('<!DOCTYPE') || body.contains('<html')) return null;
      return null;
    }

    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'] ?? map['message'];
      if (err != null && err.toString().trim().isNotEmpty) {
        throw ApiException(err.toString());
      }
      if (map['success'] == true && map['data'] != null) {
        return _parseList(map['data']);
      }
      final list = pick(map, ['items', 'data', 'users', 'results']);
      if (list != null) return _mapList(list);
    }

    if (body is List) return _mapList(body);
    return null;
  }

  List<SearchUserEntity> _mapList(dynamic list) {
    return asJsonList(list)
        .map((e) => SearchUserDto.fromJson(asJsonMap(e)).toEntity())
        .where((u) => u.id.isNotEmpty)
        .toList();
  }
}
