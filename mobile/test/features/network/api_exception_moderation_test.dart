import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('422 MODERATION_BLOCKED parses GirLive warning message', () {
    final ex = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/messages'),
        response: Response(
          requestOptions: RequestOptions(path: '/messages'),
          statusCode: 422,
          data: {
            'code': 'MODERATION_BLOCKED',
            'message': 'Yasaklı kelime tespit edildi.',
            'moderation': {'severity': 'LOW', 'verdict': 'warn', 'word': 'küfür'},
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );
    expect(ex.errorCode, 'MODERATION_BLOCKED');
    expect(ex.message, contains('Yasaklı'));
  });
}
