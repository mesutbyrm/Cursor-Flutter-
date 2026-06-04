import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'payment_debug_log.dart';

bool isPaymentApiPath(String path) {
  final p = path.toLowerCase();
  return p.contains('/payment/') ||
      p.contains('/jeton/payment') ||
      p.contains('cfc-payment');
}

/// Ödeme uçları için istek/yanıt izleme (debug).
class PaymentRequestInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode && isPaymentApiPath(options.path)) {
      final auth = options.headers['Authorization'];
      final jwtPresent =
          auth is String && auth.startsWith('Bearer ') && auth.length > 14;
      PaymentDebugLog.log('request', {
        'method': options.method,
        'url': '${options.baseUrl}${options.path}',
        'jwtPresent': jwtPresent,
        'jwtLength': jwtPresent ? auth.length - 7 : 0,
        'contentType': options.contentType,
        'timeoutMs': options.receiveTimeout?.inMilliseconds,
      });
      if (options.data != null) {
        PaymentDebugLog.log('requestBody', {'body': options.data.toString()});
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode && isPaymentApiPath(response.requestOptions.path)) {
      PaymentDebugLog.log('response', {
        'status': response.statusCode,
        'url': response.requestOptions.uri.toString(),
        'bodyPreview': _preview(response.data),
      });
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode && isPaymentApiPath(err.requestOptions.path)) {
      PaymentDebugLog.log('error', {
        'type': err.type.name,
        'status': err.response?.statusCode,
        'url': err.requestOptions.uri.toString(),
        'message': err.message,
        'bodyPreview': _preview(err.response?.data),
      });
    }
    handler.next(err);
  }

  static String _preview(dynamic data) {
    if (data == null) return '';
    final s = data.toString();
    return s.length > 280 ? '${s.substring(0, 280)}…' : s;
  }
}
