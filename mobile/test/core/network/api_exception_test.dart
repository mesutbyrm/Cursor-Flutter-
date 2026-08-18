import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/network/models/api_error_code.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _badResponse(int code, dynamic data) => DioException(
      requestOptions: RequestOptions(path: '/api/test'),
      response: Response(
        requestOptions: RequestOptions(path: '/api/test'),
        statusCode: code,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );

void main() {
  group('ApiException.fromDio', () {
    test('maps 403 to forbidden message', () {
      final ex = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/api/admin/gifts'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/admin/gifts'),
            statusCode: 403,
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(ex.statusCode, 403);
      expect(ApiException.userMessage(ex), contains('yetkiniz yok'));
    });

    test('maps timeout to Turkish message', () {
      final ex = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(ApiException.userMessage(ex), contains('zaman aşımı'));
    });

    test('parses nested error object', () {
      final ex = ApiException.fromDio(
        _badResponse(400, {
          'success': false,
          'error': {'code': 'VALIDATION', 'message': 'Geçersiz alan'},
        }),
      );
      expect(ex.message, 'Geçersiz alan');
      expect(ex.errorCode, 'VALIDATION');
    });

    test('maps insufficient_jeton string to ApiErrorCode', () {
      final ex = ApiException.fromDio(
        _badResponse(400, {'error': 'insufficient_jeton'}),
      );
      expect(ex.apiErrorCode, ApiErrorCode.insufficientJetons);
      expect(ex.message, contains('jeton'));
    });

    test('parses flat error string', () {
      final ex = ApiException.fromDio(
        _badResponse(400, {'error': 'Yetersiz jeton. 10 jeton gerekiyor.'}),
      );
      expect(ex.message, contains('jeton'));
    });

    test('maps 429 to rate limit', () {
      final ex = ApiException.fromDio(_badResponse(429, {'error': 'rate_limit'}));
      expect(ex.statusCode, 429);
      expect(ex.apiErrorCode, ApiErrorCode.rateLimited);
    });
  });
}
