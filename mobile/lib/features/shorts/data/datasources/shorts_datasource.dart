import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/util/json_util.dart';
import '../models/shorts_dto.dart';

abstract class ShortsDataSource {
  Future<List<ShortVideoDTO>> getShorts({int limit = 20});
  Future<List<ShortVideoDTO>> getTrendingShorts();
  Future<ShortVideoDTO> getShortDetail(String shortId);
  Future<void> likeShort(String shortId);
  Future<void> unlikeShort(String shortId);
  Future<List<ShortVideoRemixDTO>> getRemixes(String originalVideoId);
  Future<ShortVideoRemixDTO> createRemix(String originalVideoId, String remixType);
}

class ShortsDataSourceImpl implements ShortsDataSource {
  final Dio _dio;
  ShortsDataSourceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ShortVideoDTO>> getShorts({int limit = 20}) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.shorts}?limit=$limit');
    final data = asJsonMap(res.data);
    return (data['videos'] as List<dynamic>?)?.map((e) => ShortVideoDTO.fromJson(e is Map<String,dynamic> ? e : asJsonMap(e))).toList() ?? [];
  }

  @override
  Future<List<ShortVideoDTO>> getTrendingShorts() async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.shorts}/trending');
    final data = asJsonMap(res.data);
    return (data['videos'] as List<dynamic>?)?.map((e) => ShortVideoDTO.fromJson(e is Map<String,dynamic> ? e : asJsonMap(e))).toList() ?? [];
  }

  @override
  Future<ShortVideoDTO> getShortDetail(String shortId) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.shorts}/$shortId');
    return ShortVideoDTO.fromJson(asJsonMap(res.data));
  }

  @override
  Future<void> likeShort(String shortId) => _dio.safePost<dynamic>('${ApiEndpoints.shorts}/$shortId/like');

  @override
  Future<void> unlikeShort(String shortId) => _dio.safePost<dynamic>('${ApiEndpoints.shorts}/$shortId/unlike');

  @override
  Future<List<ShortVideoRemixDTO>> getRemixes(String originalVideoId) async {
    final res = await _dio.safeGet<dynamic>('${ApiEndpoints.shorts}/$originalVideoId/remixes');
    final data = asJsonMap(res.data);
    return (data['remixes'] as List<dynamic>?)?.map((e) => ShortVideoRemixDTO.fromJson(e is Map<String,dynamic> ? e : asJsonMap(e))).toList() ?? [];
  }

  @override
  Future<ShortVideoRemixDTO> createRemix(String originalVideoId, String remixType) async {
    final res = await _dio.safePost<dynamic>('${ApiEndpoints.shorts}/$originalVideoId/remix', data: {'remixType': remixType});
    return ShortVideoRemixDTO.fromJson(asJsonMap(res.data));
  }
}
