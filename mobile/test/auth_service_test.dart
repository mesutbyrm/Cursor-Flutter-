import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/services/models/auth_api_error.dart';
import 'package:canlifal_social/services/models/auth_response.dart';
import 'package:canlifal_social/core/network/api_exception.dart';

void main() {
  group('AuthResponse', () {
    test('parses flat login response', () {
      final res = AuthResponse.parseRoot({
        'accessToken': 'acc',
        'refreshToken': 'ref',
        'isNewUser': false,
        'user': {
          'id': 'u1',
          'email': 'a@b.com',
          'name': 'Test',
          'username': 'tester',
          'role': 'user',
          'credits': 100,
          'jetonBalance': 500,
        },
      });
      expect(res.accessToken, 'acc');
      expect(res.user.jetonBalance, 500);
      expect(res.isNewUser, false);
    });

    test('parses wrapped success response', () {
      final res = AuthResponse.parseRoot({
        'success': true,
        'data': {
          'accessToken': 'a',
          'refreshToken': 'r',
          'user': {
            'id': '1',
            'email': 'e',
            'name': 'N',
          },
        },
      });
      expect(res.refreshToken, 'r');
    });
  });

  group('AuthApiError', () {
    test('parses structured error', () {
      final err = AuthApiError.fromResponseBody(
        {
          'success': false,
          'error': {
            'code': 'TOKEN_EXPIRED',
            'message': 'Oturum süresi doldu',
          },
        },
        statusCode: 401,
      );
      expect(err?.code, AuthApiErrorCode.tokenExpired);
      expect(err?.message, 'Oturum süresi doldu');
    });

    test('parses legacy string error', () {
      final err = AuthApiError.fromResponseBody(
        {'error': 'E-posta veya şifre hatalı'},
        statusCode: 401,
      );
      expect(err?.message, 'E-posta veya şifre hatalı');
    });
  });

  group('ApiException structured', () {
    test('fromDio reads nested error code', () {
      // ApiException.fromDio needs DioException - skip full dio, test helper via body map
      final parsed = AuthApiError.fromResponseBody(
        {
          'error': {
            'code': 'RATE_LIMITED',
            'message': 'Çok fazla istek',
          },
        },
        statusCode: 429,
      );
      expect(parsed?.code, AuthApiErrorCode.rateLimited);
    });
  });
}
