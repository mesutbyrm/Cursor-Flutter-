import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/api_response.dart';

void main() {
  group('parseResponse', () {
    test('parses success envelope', () {
      final res = parseResponse<Map<String, dynamic>>(
        Response(
          requestOptions: RequestOptions(path: '/test'),
          data: {
            'success': true,
            'data': {'id': '1', 'name': 'Test'},
            'pagination': {
              'page': 1,
              'limit': 20,
              'total': 42,
              'totalPages': 3,
              'hasNext': true,
              'hasPrev': false,
            },
          },
        ),
        (json) => Map<String, dynamic>.from(json as Map),
      );

      expect(res.success, isTrue);
      expect(res.data?['id'], '1');
      expect(res.pagination?.total, 42);
      expect(res.pagination?.hasNext, isTrue);
    });

    test('parses structured error', () {
      final res = parseResponse<String>(
        Response(
          requestOptions: RequestOptions(path: '/test'),
          data: {
            'success': false,
            'error': {
              'code': 'TOKEN_EXPIRED',
              'message': 'Oturum süresi doldu',
            },
          },
        ),
        (json) => json.toString(),
      );

      expect(res.success, isFalse);
      expect(res.error?.code, 'TOKEN_EXPIRED');
      expect(res.error?.message, 'Oturum süresi doldu');
    });

    test('parses legacy string error', () {
      final res = parseResponse<String>(
        Response(
          requestOptions: RequestOptions(path: '/test'),
          data: {'error': 'E-posta veya şifre hatalı'},
        ),
        (json) => json.toString(),
      );

      expect(res.success, isFalse);
      expect(res.error?.code, 'UNKNOWN');
      expect(res.error?.message, 'E-posta veya şifre hatalı');
    });

    test('parses legacy flat data body', () {
      final res = parseResponse<List<dynamic>>(
        Response(
          requestOptions: RequestOptions(path: '/test'),
          data: {
            'items': [
              {'id': 'a'},
            ],
            'page': 2,
            'limit': 10,
            'total': 25,
          },
        ),
        (json) => [json],
      );

      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.pagination?.page, 2);
      expect(res.pagination?.limit, 10);
    });
  });

  group('apiPageQuery', () {
    test('defaults to page 1 limit 20', () {
      expect(apiPageQuery(), {'page': 1, 'limit': 20});
      expect(apiPageQuery(page: 3, limit: 50), {'page': 3, 'limit': 50});
    });
  });
}
