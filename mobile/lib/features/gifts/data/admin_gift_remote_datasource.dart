import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/admin_gift_stats.dart';
import '../domain/admin_gift_type.dart';

class AdminGiftUploadedAsset {
  const AdminGiftUploadedAsset({required this.cloudPath, this.publicUrl});

  /// R2/S3 nesne anahtarı; create/update DTO'daki `*CloudPath` alanına gider.
  final String cloudPath;

  /// Kullanıcı önizlemesi için CDN URL'si; DTO'ya cloud path diye yazılmaz.
  final String? publicUrl;

  String get previewUrl => publicUrl ?? cloudPath;
}

/// Admin hediye yönetimi — `/api/admin/gifts/*`. Yalnızca site admin.
class AdminGiftRemoteDataSource {
  AdminGiftRemoteDataSource(
    this._dio, {
    Duration operationTimeout = const Duration(seconds: 25),
    Dio Function()? uploadDioFactory,
  }) : _operationTimeout = operationTimeout,
       _uploadDioFactory = uploadDioFactory ?? _defaultUploadDio;

  final Dio _dio;
  final Duration _operationTimeout;
  final Dio Function() _uploadDioFactory;

  /// Tüm hediyeler (pasifler dahil).
  Future<List<AdminGiftType>> listGifts() async {
    final res = await _dio.safeGet<dynamic>('/api/admin/gifts');
    dynamic raw = res.data;
    if (raw is Map) {
      raw =
          asJsonMap(raw)['gifts'] ??
          asJsonMap(raw)['data'] ??
          asJsonMap(raw)['items'];
    }
    if (raw is! List) return const [];
    final out = <AdminGiftType>[];
    for (final e in raw) {
      if (e is Map) out.add(AdminGiftType.fromJson(asJsonMap(e)));
    }
    out.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return out;
  }

  /// Yeni hediye ekle. body = CreateGiftTypeDto alanları.
  Future<AdminGiftType> createGift(Map<String, dynamic> body) async {
    final stopwatch = Stopwatch()..start();
    _log('POST /api/admin/gifts start fields=${body.keys.toList()..sort()}');
    final cancel = CancelToken();
    try {
      final res = await _withTimeout(
        () => _dio.safePost<dynamic>(
          '/api/admin/gifts',
          data: body,
          cancelToken: cancel,
          options: Options(
            sendTimeout: _operationTimeout,
            receiveTimeout: _operationTimeout,
          ),
        ),
        cancel,
        operation: 'Hediye kaydetme',
      );
      _expectMutationStatus(res);
      final gift = _requireGift(res.data, operation: 'Hediye oluşturma');
      _log(
        'POST /api/admin/gifts success status=${res.statusCode} '
        'giftId=${gift.id} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      return gift;
    } catch (error) {
      _log(
        'POST /api/admin/gifts failed elapsedMs=${stopwatch.elapsedMilliseconds} '
        'error=${ApiException.userMessage(error)}',
      );
      rethrow;
    }
  }

  /// Hediye güncelle (kısmi). body = UpdateGiftTypeDto alanları.
  Future<AdminGiftType?> updateGift(
    String id,
    Map<String, dynamic> body,
  ) async {
    final cancel = CancelToken();
    final res = await _withTimeout(
      () => _dio.safePatch<dynamic>(
        '/api/admin/gifts/$id',
        data: body,
        cancelToken: cancel,
        options: Options(
          sendTimeout: _operationTimeout,
          receiveTimeout: _operationTimeout,
        ),
      ),
      cancel,
      operation: 'Hediye güncelleme',
    );
    _expectMutationStatus(res);
    // Bazı eski PATCH sürümleri yalnızca `{success:true}` döndürüyor.
    // Mevcut toggle/düzenleme uyumluluğunu koru; create ise id zorunlu.
    return _parseOne(res.data);
  }

  /// Hediye sil (depodaki dosyaları da siler).
  Future<void> deleteGift(String id) async {
    await _dio.safeDelete<dynamic>('/api/admin/gifts/$id');
  }

  /// İstatistikler.
  Future<AdminGiftStats> statistics({String period = 'all'}) async {
    final res = await _dio.safeGet<dynamic>(
      '/api/admin/gifts/statistics',
      query: {'period': period},
    );
    final body = res.data;
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['data'] is Map ? asJsonMap(m['data']) : m;
      return AdminGiftStats.fromJson(data);
    }
    return const AdminGiftStats();
  }

  /// Gelir paylaşım kuralları.
  Future<List<AdminRevenueRule>> revenueRules() async {
    final res = await _dio.safeGet<dynamic>('/api/admin/gifts/revenue/rules');
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['rules'] ?? asJsonMap(raw)['data'] ?? raw;
    }
    if (raw is! List) return const [];
    final out = <AdminRevenueRule>[];
    for (final e in raw) {
      if (e is Map) out.add(AdminRevenueRule.fromJson(asJsonMap(e)));
    }
    return out;
  }

  /// Bir bağlamın gelir kuralını güncelle.
  Future<void> updateRevenueRule(
    String context,
    Map<String, dynamic> body,
  ) async {
    await _dio.safePatch<dynamic>(
      '/api/admin/gifts/revenue/rules/$context',
      data: body,
    );
  }

  /// Hediye dosyası/küçük resim yükle → okunabilir/cloud path döner.
  /// kind: 'icon' | 'thumbnail' | 'asset' | 'sound' (backend sözleşmesi).
  Future<AdminGiftUploadedAsset> uploadAsset(
    File file, {
    required String kind,
  }) async {
    if (!await file.exists()) {
      throw const ApiException('Yüklenecek hediye dosyası bulunamadı.');
    }
    final fileName = file.path.split(Platform.pathSeparator).last;
    final contentType = _contentType(fileName);
    _log(
      'POST /api/admin/gifts/upload-url start '
      'kind=$kind contentType=$contentType',
    );
    final cancel = CancelToken();
    final res = await _withTimeout(
      () => _dio.safePost<dynamic>(
        '/api/admin/gifts/upload-url',
        data: {'fileName': fileName, 'contentType': contentType, 'kind': kind},
        cancelToken: cancel,
        options: Options(
          sendTimeout: _operationTimeout,
          receiveTimeout: _operationTimeout,
        ),
      ),
      cancel,
      operation: 'Hediye yükleme bağlantısı',
    );
    _expectMutationStatus(res);
    final map = res.data is Map ? asJsonMap(res.data) : <String, dynamic>{};
    final inner = map['data'] is Map ? asJsonMap(map['data']) : map;
    final uploadUrl = pick(inner, [
      'uploadUrl',
      'url',
      'signedUrl',
      'putUrl',
    ])?.toString();
    final cloudPath = pick(inner, [
      'cloud_storage_path',
      'cloudPath',
      'path',
      'key',
      'objectKey',
    ])?.toString();
    final publicUrl = pick(inner, [
      'publicUrl',
      'readUrl',
      'fileUrl',
    ])?.toString();
    if (uploadUrl == null || uploadUrl.trim().isEmpty) {
      throw const ApiException(
        'Hediye yükleme bağlantısı sunucudan alınamadı.',
      );
    }
    if (cloudPath == null || cloudPath.trim().isEmpty) {
      throw const ApiException(
        'Hediye dosyasının R2/S3 kayıt yolu sunucudan alınamadı.',
      );
    }

    final putDio = _uploadDioFactory();
    try {
      final length = await file.length();
      final putCancel = CancelToken();
      final put = await _withTimeout(
        () => putDio.put<dynamic>(
          uploadUrl,
          data: file.openRead(),
          cancelToken: putCancel,
          options: Options(
            headers: {
              'Content-Type': contentType,
              Headers.contentLengthHeader: length,
            },
          ),
        ),
        putCancel,
        operation: 'R2/S3 hediye dosyası yükleme',
      );
      final code = put.statusCode ?? 0;
      if (code < 200 || code >= 300) {
        throw ApiException(
          'Hediye dosyası R2/S3 deposuna yüklenemedi (HTTP $code).',
          statusCode: code,
        );
      }
      _log(
        'R2/S3 PUT success status=$code kind=$kind bytes=$length '
        'cloudPath=$cloudPath',
      );
    } finally {
      putDio.close(force: true);
    }
    return AdminGiftUploadedAsset(
      cloudPath: cloudPath.trim(),
      publicUrl: publicUrl != null && publicUrl.trim().isNotEmpty
          ? publicUrl.trim()
          : null,
    );
  }

  AdminGiftType _requireGift(dynamic body, {required String operation}) {
    final gift = _parseOne(body);
    if (gift == null || gift.id.trim().isEmpty) {
      throw ApiException(
        '$operation tamamlandı ancak sunucu geçerli hediye kaydı döndürmedi.',
      );
    }
    return gift;
  }

  AdminGiftType? _parseOne(dynamic body) {
    if (body is Map) {
      final m = asJsonMap(body);
      final data = m['gift'] is Map
          ? asJsonMap(m['gift'])
          : (m['data'] is Map ? asJsonMap(m['data']) : m);
      return AdminGiftType.fromJson(data);
    }
    return null;
  }

  void _expectMutationStatus(Response<dynamic> response) {
    final code = response.statusCode ?? 0;
    if (code != 200 && code != 201) {
      throw ApiException(
        'Hediye işlemi beklenmeyen HTTP $code yanıtı döndürdü.',
        statusCode: code,
      );
    }
  }

  Future<Response<T>> _withTimeout<T>(
    Future<Response<T>> Function() request,
    CancelToken cancel, {
    required String operation,
  }) async {
    try {
      return await request().timeout(
        _operationTimeout,
        onTimeout: () {
          cancel.cancel('$operation zaman aşımı');
          throw ApiException(
            '$operation zaman aşımına uğradı. Lütfen tekrar deneyin.',
          );
        },
      );
    } on TimeoutException {
      cancel.cancel('$operation zaman aşımı');
      throw ApiException(
        '$operation zaman aşımına uğradı. Lütfen tekrar deneyin.',
      );
    }
  }

  static Dio _defaultUploadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 25),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 25),
      ),
    );
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint('[AdminGift] $message');
  }

  String _contentType(String fileName) {
    final f = fileName.toLowerCase();
    if (f.endsWith('.png')) return 'image/png';
    if (f.endsWith('.jpg') || f.endsWith('.jpeg')) return 'image/jpeg';
    if (f.endsWith('.gif')) return 'image/gif';
    if (f.endsWith('.webp')) return 'image/webp';
    if (f.endsWith('.mp4')) return 'video/mp4';
    if (f.endsWith('.webm')) return 'video/webm';
    if (f.endsWith('.json')) return 'application/json';
    if (f.endsWith('.riv')) return 'application/octet-stream';
    if (f.endsWith('.svga')) return 'application/octet-stream';
    if (f.endsWith('.mp3')) return 'audio/mpeg';
    if (f.endsWith('.wav')) return 'audio/wav';
    return 'application/octet-stream';
  }
}
