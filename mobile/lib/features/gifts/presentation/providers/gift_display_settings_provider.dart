import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/util/json_util.dart';
import '../../domain/gift_display_settings.dart';

class GiftDisplaySettingsRemoteDataSource {
  GiftDisplaySettingsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<GiftDisplaySettings> fetch() async {
    try {
      final res = await _dio.safeGet<dynamic>(ApiEndpoints.giftsDisplaySettings);
      final body = res.data;
      if (body is Map) {
        final map = asJsonMap(body);
        final inner = map['settings'] ?? map['data'] ?? map;
        if (inner is Map) {
          return GiftDisplaySettings.fromJson(asJsonMap(inner));
        }
        return GiftDisplaySettings.fromJson(map);
      }
    } catch (_) {}
    return const GiftDisplaySettings();
  }
}

final giftDisplaySettingsRemoteProvider =
    Provider<GiftDisplaySettingsRemoteDataSource>((ref) {
  return GiftDisplaySettingsRemoteDataSource(ref.watch(dioProvider));
});

/// Admin ayarları — TTL ile yenilenir (kritik değişikliklerde kısa TTL).
final giftDisplaySettingsProvider =
    FutureProvider.autoDispose<GiftDisplaySettings>((ref) async {
  ref.keepAlive();
  final timer = Timer(const Duration(minutes: 2), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);
  return ref.read(giftDisplaySettingsRemoteProvider).fetch();
});
