import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
