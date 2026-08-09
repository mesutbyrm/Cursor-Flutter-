import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// createVideoStream retry kuralları — LiveRemoteDataSource ile aynı mantık.
bool isRetryableCreateStreamError(Object error) {
  if (error is ApiException) {
    final code = error.statusCode;
    if (code == 429) return true;
    if (code != null && code >= 500) return true;
    final lower = error.message.toLowerCase();
    return lower.contains('zaman aşımı') ||
        lower.contains('timeout') ||
        lower.contains('bağlantı') ||
        lower.contains('yanıt vermedi');
  }
  if (error is DioException) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
  }
  return false;
}

void main() {
  group('createVideoStream retry policy', () {
    test('retries on 503 ApiException', () {
      expect(
        isRetryableCreateStreamError(
          const ApiException('sunucu hatası', statusCode: 503),
        ),
        isTrue,
      );
    });

    test('retries on receive timeout DioException', () {
      expect(
        isRetryableCreateStreamError(
          DioException(
            requestOptions: RequestOptions(path: '/api/video-streams'),
            type: DioExceptionType.receiveTimeout,
          ),
        ),
        isTrue,
      );
    });

    test('does not retry on 403 ApiException', () {
      expect(
        isRetryableCreateStreamError(
          const ApiException('NOT_A_TELLER', statusCode: 403),
        ),
        isFalse,
      );
    });

    test('does not retry on 400 validation', () {
      expect(
        isRetryableCreateStreamError(
          const ApiException('bad request', statusCode: 400),
        ),
        isFalse,
      );
    });
  });
}
