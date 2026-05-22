import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_provider.dart';
import 'push_notification_service.dart';

/// FCM token'ını sunucuya kaydeder (uç yoksa sessizce atlanır).
class PushRegistrar {
  PushRegistrar(this._dio);

  final Dio _dio;
  String? _lastSentToken;

  Future<void> registerIfPossible() async {
    if (!FirebaseBootstrap.isReady) return;

    await PushNotificationService.instance.init();
    final token = await PushNotificationService.instance.currentFcmToken();
    if (token == null || token.isEmpty) return;
    if (token == _lastSentToken) return;

    try {
      await _dio.safePost(
        ApiEndpoints.registerFcmDevice,
        data: {
          'token': token,
          'fcmToken': token,
          'platform': defaultTargetPlatform.name,
        },
      );
      _lastSentToken = token;
      debugPrint('FCM token registered');
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        debugPrint('FCM register endpoint not deployed yet');
        return;
      }
      debugPrint('FCM register failed: ${e.message}');
    } catch (e) {
      debugPrint('FCM register failed: $e');
    }
  }
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(ref.watch(dioProvider));
});

final pushRegistrarControllerProvider =
    Provider<void Function()>((ref) {
  return () => ref.read(pushRegistrarProvider).registerIfPossible();
});
