import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/entities/user_favorite_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

class FavoritesRemoteDataSource {
  FavoritesRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<UserFavoriteEntity>> list() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.userFavorites);
      final parsed = _parseList(res.data);
      if (parsed != null) return parsed;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const ApiException(
          'Favoriler için oturum açmanız gerekiyor.',
          statusCode: 401,
        );
      }
      rethrow;
    }
    return const [];
  }

  Future<UserFavoriteEntity> add(AddFavoriteInput input) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.userFavorites,
      data: {
        'targetType': input.targetType,
        'targetId': input.targetId,
        if (input.title != null) 'title': input.title,
        if (input.url != null) 'url': input.url,
        if (input.imageUrl != null) 'imageUrl': input.imageUrl,
      },
    );
    return _row(res.data);
  }

  Future<void> remove(String id) async {
    await _dio.safeDelete(ApiEndpoints.userFavoriteDelete(id));
  }

  List<UserFavoriteEntity>? _parseList(dynamic body) {
    if (body is String) return null;
    if (body is Map) {
      final map = asJsonMap(body);
      final err = map['error'];
      if (err != null) throw ApiException(err.toString());
      if (map['success'] == true && map['data'] != null) {
        return _parseList(map['data']);
      }
      final list = pick(map, ['items', 'data', 'favorites']);
      if (list != null) return _mapList(list);
    }
    if (body is List) return _mapList(body);
    return null;
  }

  List<UserFavoriteEntity> _mapList(dynamic list) {
    return asJsonList(list).map(_row).where((f) => f.id.isNotEmpty).toList();
  }

  UserFavoriteEntity _row(dynamic json) {
    final m = json is Map ? asJsonMap(json) : <String, dynamic>{};
    return UserFavoriteEntity(
      id: pick(m, ['id', '_id'])?.toString() ?? '',
      targetType: pick(m, ['targetType', 'type'])?.toString() ?? '',
      targetId: pick(m, ['targetId', 'refId'])?.toString() ?? '',
      title: pick(m, ['title', 'name'])?.toString(),
      url: pick(m, ['url', 'link'])?.toString(),
      imageUrl: pick(m, ['imageUrl', 'image'])?.toString(),
      createdAt: DateTime.tryParse(
        pick(m, ['createdAt', 'created_at'])?.toString() ?? '',
      ),
    );
  }
}
