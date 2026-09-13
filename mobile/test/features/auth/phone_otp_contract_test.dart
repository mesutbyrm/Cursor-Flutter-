import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _Responder = Future<ResponseBody> Function(
  RequestOptions options,
  Stream<Uint8List>? requestStream,
  Future<void>? cancelFuture,
);

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final _Responder responder;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) =>
      responder(options, requestStream, cancelFuture);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('phone OTP request bodies (authentication.md BÖLÜM 17)', () {
    test('send-otp posts only { phone }', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          captured = options;
          await cancelFuture;
          return ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        });

      final remote = AuthRemoteDataSource(dio);
      await remote.postPhoneSendOtp({'phone': '+905551112233'});

      expect(captured?.path, ApiEndpoints.authPhoneSendOtp);
      expect(captured?.method, 'POST');
      expect(captured?.data, {'phone': '+905551112233'});
    });

    test('verify-otp posts { phone, code }', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          captured = options;
          await cancelFuture;
          return ResponseBody.fromString(
            '{"ok":true}',
            200,
            headers: {Headers.contentTypeHeader: ['application/json']},
          );
        });

      final remote = AuthRemoteDataSource(dio);
      await remote.postPhoneVerifyOtp({
        'phone': '+905551112233',
        'code': '123456',
      });

      expect(captured?.path, ApiEndpoints.authPhoneVerifyOtp);
      expect(captured?.data, {
        'phone': '+905551112233',
        'code': '123456',
      });
    });

  });
}
