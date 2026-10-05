import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'animation_payload.dart';

/// Merkezi animasyon sistemi istemcisi.
///
/// * `GET /api/animations/resolve?userId&context&category` — kullanıcıya özel
///   tek animasyon (atama > üyelik varsayılanı > eski kozmetik).
/// * `GET /api/animations/manifest` — tüm aktif animasyonlar (önden yükleme).
///
/// Çözümlemeler kısa süre önbelleğe alınır; odaya giren herkes için ağ
/// gecikmesi her olayda tekrarlanmaz.
class AnimationsRepository {
  AnimationsRepository(this._dio);

  final Dio _dio;

  static const _ttl = Duration(seconds: 60);
  final _cache = <String, ({DateTime at, AnimationPayload? payload})>{};
  final _inflight = <String, Future<AnimationPayload?>>{};
  List<AnimationPayload>? _manifest;
  DateTime? _manifestAt;

  /// Kullanıcı + bağlam + kategori için tek animasyon; yoksa `null`.
  Future<AnimationPayload?> resolve({
    required String userId,
    required String category,
    String? context,
  }) {
    final key = '$userId|$category|${context ?? ''}';
    final hit = _cache[key];
    if (hit != null && DateTime.now().difference(hit.at) < _ttl) {
      return Future.value(hit.payload);
    }
    return _inflight[key] ??= _fetch(key, userId, category, context)
        .whenComplete(() => _inflight.remove(key));
  }

  Future<AnimationPayload?> _fetch(
    String key,
    String userId,
    String category,
    String? context,
  ) async {
    try {
      final res = await _dio.get<dynamic>(
        '/api/animations/resolve',
        queryParameters: {
          'userId': userId,
          'category': category,
          if (context != null) 'context': context,
        },
      );
      final data = res.data;
      AnimationPayload? payload;
      if (data is Map && data['animation'] is Map) {
        payload = AnimationPayload.fromJson(
          Map<String, dynamic>.from(data['animation'] as Map),
        );
        if (payload.resolvedAssetUrl.isEmpty) payload = null;
      }
      _cache[key] = (at: DateTime.now(), payload: payload);
      return payload;
    } catch (_) {
      return null;
    }
  }

  /// Manifest (giriş gerektirmez) — 10 dk bellek önbelleği.
  Future<List<AnimationPayload>> manifest({bool force = false}) async {
    final cached = _manifest;
    final at = _manifestAt;
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < const Duration(minutes: 10)) {
      return cached;
    }
    try {
      final res = await _dio.get<dynamic>('/api/animations/manifest');
      final data = res.data;
      final list = <AnimationPayload>[];
      if (data is Map && data['animations'] is List) {
        for (final e in data['animations'] as List) {
          if (e is Map) {
            list.add(AnimationPayload.fromJson(Map<String, dynamic>.from(e)));
          }
        }
      }
      _manifest = list;
      _manifestAt = DateTime.now();
      return list;
    } catch (_) {
      return cached ?? const [];
    }
  }
}

final animationsRepositoryProvider = Provider<AnimationsRepository>(
  (ref) => AnimationsRepository(ref.watch(dioProvider)),
);
