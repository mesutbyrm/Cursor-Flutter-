import 'dart:io';

import 'package:dio/dio.dart';

import '../config/env.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_provider.dart';
import '../util/json_util.dart';

/// R2/S3 presigned yükleme + okunabilir URL çözümleme.
///
/// Sesli oda arka planı gibi sunucunun yalnızca `canlifal.com` kökenli URL
/// kabul ettiği durumlarda [requireSiteOrigin] kullanın.
class CloudMediaUploadService {
  CloudMediaUploadService(this._dio);

  final Dio _dio;

  Future<String> uploadImageFile(
    File file, {
    required String folder,
    bool isPublic = true,
    bool requireSiteOrigin = false,
  }) async {
    final contentType = _contentType(file.path);
    final fileName = file.path.split(Platform.pathSeparator).last;

    final presigned = await _dio.safePost<dynamic>(
      ApiEndpoints.uploadPresigned,
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'isPublic': isPublic,
        'folder': folder,
      },
    );

    final map = presigned.data is Map
        ? Map<String, dynamic>.from(presigned.data as Map)
        : <String, dynamic>{};
    if (map['success'] == true && map['data'] is Map) {
      map.addAll(Map<String, dynamic>.from(map['data'] as Map));
    }

    final uploadUrl = map['uploadUrl']?.toString();
    final cloudPath = map['cloud_storage_path']?.toString();
    if (uploadUrl == null ||
        uploadUrl.isEmpty ||
        cloudPath == null ||
        cloudPath.isEmpty) {
      throw const ApiException('Yükleme bağlantısı alınamadı');
    }

    final bytes = await file.readAsBytes();
    final putDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 45),
        sendTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 45),
      ),
    );
    try {
      final putRes = await putDio.put<dynamic>(
        uploadUrl,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Disposition': 'attachment',
          },
        ),
      );
      if (putRes.statusCode == null ||
          putRes.statusCode! < 200 ||
          putRes.statusCode! >= 300) {
        throw const ApiException('Görsel yüklenemedi');
      }
    } finally {
      putDio.close(force: true);
    }

    return resolveReadableUrl(
      cloudPath,
      isPublic: isPublic,
      requireSiteOrigin: requireSiteOrigin,
    );
  }

  /// Yüklenen dosya için oynatma/görüntüleme URL'si üretir.
  Future<String> resolveReadableUrl(
    String cloudPath, {
    bool isPublic = true,
    bool requireSiteOrigin = false,
  }) async {
    final trimmed = cloudPath.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('Dosya yolu boş');
    }

    if (trimmed.startsWith('http')) {
      if (!requireSiteOrigin || _isSiteOriginUrl(trimmed)) {
        return trimmed;
      }
    }

    final signed = await _fetchSignedUrl(trimmed, isPublic: isPublic);
    if (signed != null && signed.isNotEmpty) {
      if (!requireSiteOrigin || _isSiteOriginUrl(signed)) {
        return signed;
      }
    }

    if (requireSiteOrigin) {
      return '${Env.siteOrigin}/api/upload/get-url?path=${Uri.encodeComponent(trimmed)}';
    }

    return signed ??
        '${Env.siteOrigin}/api/upload/get-url?path=${Uri.encodeComponent(trimmed)}';
  }

  Future<String?> _fetchSignedUrl(String cloudPath, {required bool isPublic}) async {
    try {
      final res = await _dio.safePost<dynamic>(
        ApiEndpoints.uploadGetUrl,
        data: {
          'cloud_storage_path': cloudPath,
          'isPublic': isPublic,
        },
      );
      final body = res.data;
      if (body is! Map) return null;
      final m = Map<String, dynamic>.from(body);
      if (m['success'] == true && m['data'] is Map) {
        m.addAll(Map<String, dynamic>.from(m['data'] as Map));
      }
      return pick(m, ['url', 'signedUrl', 'downloadUrl', 'publicUrl'])
          ?.toString();
    } catch (_) {
      return null;
    }
  }

  static bool _isSiteOriginUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 'canlifal.com' || host == 'www.canlifal.com';
  }

  static String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
