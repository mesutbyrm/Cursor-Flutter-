import 'dart:io';

import 'package:dio/dio.dart';

import '../core/api_response.dart';
import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';
import 'service_utils.dart';
import 'upload_service.dart';

/// Kısa video API — kılavuz §9.11 `ShortVideoRepository`.
class ShortVideoService {
  ShortVideoService({
    required Dio Function() resolveAuthedDio,
    UploadService? uploadService,
  })  : _resolveAuthedDio = resolveAuthedDio,
        _upload = uploadService;

  final Dio Function() _resolveAuthedDio;
  final UploadService? _upload;

  Dio get _dio => _resolveAuthedDio();

  /// `GET /api/short-videos`
  Future<ApiResponse<List<Map<String, dynamic>>>> getVideos({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.safeGet<dynamic>(
      ApiEndpoints.shortVideos,
      query: apiPageQuery(page: page, limit: limit),
    );
    return parseResponse<List<Map<String, dynamic>>>(
      res.data,
      fromData: (data) => ServiceUtils.extractList(
        data,
        keys: const ['videos', 'items', 'data'],
      ),
    );
  }

  /// `POST upload-url` → PUT → `POST /api/short-videos`
  Future<Map<String, dynamic>> uploadVideo({
    required String videoFilePath,
    String? thumbnailPath,
    String? description,
    String contentType = 'video/mp4',
  }) async {
    final upload = _upload;
    if (upload == null) {
      throw StateError(
        'Video yüklemek için ShortVideoService\'e UploadService verilmelidir.',
      );
    }
    final fileName = videoFilePath.split('/').last;
    final presigned = await upload.getUploadUrl(
      fileName: fileName,
      contentType: contentType,
    );
    final uploadUrl = presigned.uploadUrl;
    final fileUrl = presigned.fileUrl;
    if (uploadUrl.isEmpty || fileUrl.isEmpty) {
      throw const ApiException('Yükleme URL\'si alınamadı');
    }

    await upload.putFile(
      uploadUrl: uploadUrl,
      file: File(videoFilePath),
      contentType: contentType,
    );

    String? thumbUrl;
    if (thumbnailPath != null && thumbnailPath.isNotEmpty) {
      final thumbName = thumbnailPath.split('/').last;
      final thumbPresigned = await upload.getUploadUrl(
        fileName: thumbName,
        contentType: 'image/jpeg',
      );
      if (thumbPresigned.uploadUrl.isNotEmpty) {
        await upload.putFile(
          uploadUrl: thumbPresigned.uploadUrl,
          file: File(thumbnailPath),
          contentType: 'image/jpeg',
        );
        thumbUrl = thumbPresigned.fileUrl;
      }
    }

    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideos,
      data: {
        'videoUrl': fileUrl,
        if (thumbUrl != null) 'thumbnailUrl': thumbUrl,
        if (description != null && description.isNotEmpty)
          'description': description,
      },
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/short-videos/{id}/like`
  Future<Map<String, dynamic>> like(String id) async {
    final res = await _dio.safePost<dynamic>(ApiEndpoints.shortVideoLike(id));
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }

  /// `POST /api/short-videos/{id}/comments`
  Future<Map<String, dynamic>> comment(
    String id, {
    required String text,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.shortVideoComments(id),
      data: {'content': text.trim()},
    );
    return ServiceUtils.unwrapMap(res.data) ?? asJsonMap(res.data);
  }
}
