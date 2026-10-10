import 'dart:math';

import 'package:dio/dio.dart';

import '../network/api_endpoints.dart';
import '../network/dio_provider.dart';
import '../diagnostics/cf_diag.dart';

/// Site geneli çevrimiçi durumu — kılavuz §9.2 `POST /api/presence`.
class UserPresenceService {
  UserPresenceService(this._dio);

  final Dio _dio;

  /// Sunucu `visitorId` olmadan heartbeat'i 400 ile reddediyordu; mobil kullanıcılar
  /// hiç çevrimiçi görünmüyor, `lastActiveAt` güncellenmiyordu. Süreç başına sabit,
  /// kişisel veri içermeyen rastgele kimlik — leave aynı kaydı siler.
  static final String visitorId = _newVisitorId();

  static String _newVisitorId() {
    final r = Random.secure();
    final hex = List.generate(12, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    return 'mobile-$hex';
  }

  Future<void> heartbeat({String section = 'app'}) async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.userPresence,
        data: {
          'action': 'join',
          'visitorId': visitorId,
          'section': section,
          'platform': 'mobile',
        },
      );
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.network, 'user_presence_service:22');
    }
  }

  Future<void> leave() async {
    try {
      await _dio.safePost<dynamic>(
        ApiEndpoints.userPresence,
        data: {
          'action': 'leave',
          'visitorId': visitorId,
          'platform': 'mobile',
        },
      );
    } catch (err, st) {
      CfDiag.swallowed(err, st, CfCategory.network, 'user_presence_service:34');
    }
  }
}
