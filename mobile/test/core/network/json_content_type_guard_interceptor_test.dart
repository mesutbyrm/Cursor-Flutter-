import 'package:canlifal_social/core/network/json_content_type_guard_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonContentTypeGuardInterceptor', () {
    test('flags HTML returned from API endpoints', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/api/gifts'),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html; charset=utf-8'],
        }),
        data: '<!DOCTYPE html><html></html>',
      );

      expect(
        JsonContentTypeGuardInterceptor.isUnexpectedHtmlApiResponse(response),
        isTrue,
      );
    });

    test('does not flag JSON API responses', () {
      final response = Response<Map<String, dynamic>>(
        requestOptions: RequestOptions(path: '/api/social/posts'),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['application/json'],
        }),
        data: {'posts': const []},
      );

      expect(
        JsonContentTypeGuardInterceptor.isUnexpectedHtmlApiResponse(response),
        isFalse,
      );
    });

    test('does not flag non-API HTML pages', () {
      final response = Response<String>(
        requestOptions: RequestOptions(path: '/gifts'),
        statusCode: 200,
        headers: Headers.fromMap({
          Headers.contentTypeHeader: ['text/html'],
        }),
        data: '<html></html>',
      );

      expect(
        JsonContentTypeGuardInterceptor.isUnexpectedHtmlApiResponse(response),
        isFalse,
      );
    });
  });
}
