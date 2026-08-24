import 'dart:async';

import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_provider.dart';

/// Kılavuz §9.9 — karşılıklı hediye kontrolü.
///
/// Sunucu yanıtındaki mevcut alanları okur (`allowed`, `canSend`, `reciprocal`,
/// `message`, `error`). Response modeli uydurulmaz. 404/405'te sessiz geçilir.
Future<void> assertReciprocalGiftAllowed(
  Dio dio,
  String receiverUserId,
) async {
  final id = receiverUserId.trim();
  if (id.isEmpty) return;
  try {
    final res = await dio
        .safeGet<dynamic>(
          ApiEndpoints.giftsCheckReciprocal,
          query: {'userId': id},
        )
        .timeout(const Duration(seconds: 3));
    var body = res.data;
    if (body is Map && body['data'] is Map) {
      body = body['data'];
    }
    if (body is! Map) return;
    final map = Map<String, dynamic>.from(body);
    final blocked = map['allowed'] == false ||
        map['canSend'] == false ||
        map['reciprocal'] == false;
    if (blocked) {
      throw ApiException(
        map['message']?.toString() ??
            map['error']?.toString() ??
            'Bu kullanıcıya şu anda hediye gönderemezsiniz',
      );
    }
  } on ApiException catch (e) {
    if (e.statusCode == 404 || e.statusCode == 405) return;
    rethrow;
  } on TimeoutException {
    return;
  }
}
