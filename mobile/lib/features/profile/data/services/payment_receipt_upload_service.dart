import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_provider.dart';

/// Ödeme dekontu — `POST /api/upload/presigned` + PUT (R2 / üretim medya).
class PaymentReceiptUploadService {
  PaymentReceiptUploadService(this._dio);

  final Dio _dio;

  Future<String> uploadFile(File file) async {
    final contentType = _contentType(file.path);
    final fileName = file.path.split(Platform.pathSeparator).last;

    final presigned = await _dio.safePost<dynamic>(
      ApiEndpoints.uploadPresigned,
      data: {
        'fileName': fileName,
        'contentType': contentType,
        'isPublic': false,
        'folder': 'payment-receipts',
      },
    );

    final map = presigned.data is Map
        ? Map<String, dynamic>.from(presigned.data as Map)
        : <String, dynamic>{};
    if (map['success'] == true && map['data'] is Map) {
      map.addAll(Map<String, dynamic>.from(map['data'] as Map));
    }

    final uploadUrl = map['uploadUrl']?.toString();
    final cloudPath = map['cloud_storage_path']?.toString() ??
        map['publicUrl']?.toString() ??
        map['url']?.toString();
    if (uploadUrl == null ||
        uploadUrl.isEmpty ||
        cloudPath == null ||
        cloudPath.isEmpty) {
      throw const ApiException('Dekont yükleme bağlantısı alınamadı');
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
        options: Options(headers: {'Content-Type': contentType}),
      );
      if (putRes.statusCode == null ||
          putRes.statusCode! < 200 ||
          putRes.statusCode! >= 300) {
        throw const ApiException('Dekont yüklenemedi');
      }
    } finally {
      putDio.close(force: true);
    }

    return cloudPath;
  }

  static String _contentType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.heic')) return 'image/heic';
    if (lower.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}

final paymentReceiptUploadServiceProvider = Provider<PaymentReceiptUploadService>(
  (ref) => PaymentReceiptUploadService(ref.watch(dioProvider)),
);
