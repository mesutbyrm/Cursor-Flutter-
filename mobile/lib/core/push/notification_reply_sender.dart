import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/env.dart';
import '../network/api_endpoints.dart';

/// Bildirimden "Yanıtla" ile yazılan metni mesaj API'sine gönderir.
///
/// Uygulama ön plandayken [foregroundHandler] (Riverpod repository'si) kullanılır;
/// uygulama kapalı/arka plandayken (ayrı isolate) JWT secure storage'dan okunup
/// doğrudan `POST /api/messages/{userId}` çağrılır.
abstract final class NotificationReplySender {
  static Future<void> Function(String peerUserId, String text)?
  foregroundHandler;

  static Future<void> send(String peerUserId, String text) async {
    final peer = peerUserId.trim();
    final body = text.trim();
    if (peer.isEmpty || body.isEmpty) return;
    final handler = foregroundHandler;
    if (handler != null) {
      await handler(peer, body);
      return;
    }
    await sendDirect(peer, body);
  }

  /// Isolate-güvenli gönderim (Riverpod yok).
  static Future<void> sendDirect(
    String peerUserId,
    String text, {
    Dio? dio,
    Future<String?> Function()? readToken,
  }) async {
    final token = await (readToken ?? _readAccessToken)();
    if (token == null || token.isEmpty) {
      throw StateError('Oturum bulunamadı — uygulamayı açıp giriş yapın.');
    }
    final client = dio ??
        Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
          ),
        );
    final res = await client.post<dynamic>(
      ApiEndpoints.messagesWithUser(peerUserId),
      data: {'content': text, 'message': text, 'text': text},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    if (kDebugMode) {
      debugPrint('[NotificationReply] sent status=${res.statusCode}');
    }
  }

  static Future<String?> _readAccessToken() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
    );
    return storage.read(key: 'jwt_access_token');
  }
}
