import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_bootstrap.dart';
import '../onesignal/onesignal_bootstrap.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_provider.dart';
import 'push_notification_service.dart';

/// FCM / OneSignal token'ını sunucuya kaydeder (üretim + yedek uçlar).
class PushRegistrar {
  PushRegistrar(this._dio);

  final Dio _dio;
  String? _lastSentToken;
  bool _registering = false;

  Future<void> registerIfPossible({bool allowTokenRetry = false}) async {
    if (_registering) return;
    _registering = true;
    try {
      await PushNotificationService.instance.init();

      final token = await _resolvePushToken(
        allowRetry: allowTokenRetry,
      );
      if (token == null || token.isEmpty) return;
      if (token == _lastSentToken) return;

      final payload = {
        'token': token,
        'fcmToken': token,
        'deviceToken': token,
        'platform': _platformLabel(),
        if (OneSignalBootstrap.isReady) 'provider': 'onesignal',
      };

      final endpoints = [
        ApiEndpoints.authMobileDeviceToken,
        ApiEndpoints.registerFcmDevice,
        ApiEndpoints.registerUserDeviceToken,
      ];

      for (final path in endpoints) {
        try {
          await _dio.safePost(path, data: payload);
          _lastSentToken = token;
          debugPrint('Push token registered via $path');
          return;
        } on ApiException catch (e) {
          if (e.statusCode == 404 || e.statusCode == 405) continue;
          debugPrint('Push register $path failed: ${e.message}');
        } catch (e) {
          debugPrint('Push register $path failed: $e');
        }
      }
    } finally {
      _registering = false;
    }
  }

  void forgetLastRegistration() {
    _lastSentToken = null;
  }

  Future<String?> _resolvePushToken({required bool allowRetry}) async {
    final delays = allowRetry
        ? const [
            Duration(milliseconds: 400),
            Duration(seconds: 1),
            Duration(seconds: 2),
          ]
        : const <Duration>[];

    for (var attempt = 0; attempt <= delays.length; attempt++) {
      final token = await _resolvePushTokenOnce();
      if (token != null && token.isNotEmpty) return token;
      if (attempt < delays.length) {
        await Future<void>.delayed(delays[attempt]);
      }
    }

    debugPrint('Push token unavailable; registration skipped');
    return null;
  }

  Future<String?> _resolvePushTokenOnce() async {
    if (OneSignalBootstrap.isReady) {
      final osToken = OneSignalBootstrap.pushToken;
      if (osToken != null && osToken.isNotEmpty) return osToken;
    }
    if (!FirebaseBootstrap.isReady) return null;
    return PushNotificationService.instance.currentFcmToken();
  }

  String _platformLabel() {
    if (OneSignalBootstrap.isReady) {
      return 'onesignal_${defaultTargetPlatform.name}';
    }
    return defaultTargetPlatform.name;
  }
}

void bindPushRegistrarTokenRefresh(void Function() register) {
  OneSignalBootstrap.onPushTokenChanged = register;
}

final pushRegistrarProvider = Provider<PushRegistrar>((ref) {
  return PushRegistrar(ref.watch(dioProvider));
});

final pushRegistrarControllerProvider =
    Provider<void Function()>((ref) {
  return () => ref.read(pushRegistrarProvider).registerIfPossible();
});
