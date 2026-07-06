import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/dio_provider.dart';
import '../../../core/util/json_util.dart';
import '../domain/admin_gift_stats.dart';
import '../domain/admin_gift_type.dart';

/// Admin hediye yönetimi — `/api/admin/gifts/*`. Yalnızca site admin.
class AdminGiftRemoteDataSource {
  AdminGiftRemoteDataSource(this._dio);

  final Dio _dio;

  /// Tüm hediyeler (pasifler dahil).
  Future<List<AdminGiftType>> listGifts() async {
    final res = await _dio.safeGet<dynamic>('/api/admin/gifts');
    dynamic raw = res.data;
    if (raw is Map) {
      raw = asJsonMap(raw)['gifts'] ?? asJsonMap(raw)['data'] ?? asJsonMap(raw)['items'];
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
  Future<AdminGiftType?> createGift(Map<String, dynamic> body) async {
    final res = await _dio.safePost<dynamic>('/api/admin/gifts', data: body);
    return _parseOne(res.data);
  }

  /// Hediye güncelle (kısmi). body = UpdateGiftTypeDto alanları.
  Future<AdminGiftType?> updateGift(String id, Map<String, dynamic> body) async {
    final res = await _dio.safePatch<dynamic>('/api/admin/gifts/$id', data: body);
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
  /// kind: 'thumbnail' | 'asset' | 'sound'.
  Future<String?> uploadAsset(File file, {required String kind}) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final contentType = _contentType(fileName);
    final res = await _dio.safePost<dynamic>(
      '/api/admin/gifts/upload-url',
      data: {'fileName': fileName, 'contentType': contentType, 'kind': kind},
    );
    final map = res.data is Map ? asJsonMap(res.data) : <String, dynamic>{};
    final inner = map['data'] is Map ? asJsonMap(map['data']) : map;
    final uploadUrl =
        pick(inner, ['uploadUrl', 'url', 'signedUrl', 'putUrl'])?.toString();
    final cloudPath = pick(
      inner,
      ['cloud_storage_path', 'cloudPath', 'path', 'key', 'objectKey'],
    )?.toString();
    if (uploadUrl == null || uploadUrl.isEmpty) return null;

    final bytes = await file.readAsBytes();
    final putDio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 45),
      sendTimeout: const Duration(seconds: 90),
      receiveTimeout: const Duration(seconds: 45),
    ));
    try {
      final put = await putDio.put<dynamic>(
        uploadUrl,
        data: bytes,
        options: Options(headers: {'Content-Type': contentType}),
      );
      final code = put.statusCode ?? 0;
      if (code < 200 || code >= 300) return null;
    } finally {
      putDio.close(force: true);
    }
    // Sunucu okunabilir URL döndürdüyse onu, yoksa cloud path'i kullan.
    return pick(inner, ['publicUrl', 'readUrl', 'fileUrl'])?.toString() ??
        cloudPath;
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
