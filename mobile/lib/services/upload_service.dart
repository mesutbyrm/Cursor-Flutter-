import 'dart:io';

import 'package:dio/dio.dart';

import '../core/network/api_endpoints.dart';
import '../core/network/api_exception.dart';
import '../core/network/dio_provider.dart';
import '../core/util/json_util.dart';

/// Presigned dosya yükleme — `POST /api/upload/presigned` + PUT.
class UploadResult {
  const UploadResult({
    required this.uploadUrl,
    required this.fileUrl,
    this.key,
  });

  final String uploadUrl;
  final String fileUrl;
  final String? key;
}

class UploadService {
  UploadService({required Dio Function() resolveAuthedDio})
      : _resolveAuthedDio = resolveAuthedDio;

  final Dio Function() _resolveAuthedDio;
  Dio get _dio => _resolveAuthedDio();

  /// `POST /api/upload/presigned`
  Future<UploadResult> getUploadUrl({
    required String fileName,
    required String contentType,
  }) async {
    final res = await _dio.safePost<dynamic>(
      ApiEndpoints.uploadPresigned,
      data: {
        'fileName': fileName,
        'filename': fileName,
        'contentType': contentType,
        'mimeType': contentType,
      },
    );
    final map = _unwrap(res.data);
    final uploadUrl = pick(map, [
      'uploadUrl',
      'presignedUrl',
      'signedUrl',
      'url',
    ])?.toString() ??
        '';
    final fileUrl = pick(map, [
      'fileUrl',
      'publicUrl',
      'cdnUrl',
      'key',
    ])?.toString() ??
        '';
    if (uploadUrl.isEmpty) {
      throw const ApiException('Presigned upload URL alınamadı');
    }
    return UploadResult(
      uploadUrl: uploadUrl,
      fileUrl: fileUrl.isNotEmpty ? fileUrl : uploadUrl.split('?').first,
      key: map['key']?.toString(),
    );
  }

  /// Presigned URL'ye ham PUT yükleme.
  Future<void> putFile({
    required String uploadUrl,
    required File file,
    required String contentType,
  }) async {
    final bytes = await file.readAsBytes();
    final raw = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 5),
        sendTimeout: const Duration(minutes: 5),
      ),
    );
    try {
      await raw.put<void>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    } finally {
      raw.close(force: true);
    }
  }

  static Map<String, dynamic> _unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return {};
  }
}
