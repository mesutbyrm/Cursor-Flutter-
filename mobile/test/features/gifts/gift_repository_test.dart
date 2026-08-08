import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/gifts/data/gift_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GiftRepository', () {
    test('fetchCatalogV2 uses the production JSON gift types endpoint', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          captured = options;
          await cancelFuture;
          return ResponseBody.fromString(
            '[{"id":"canlifal_1","name":"CanlıFal","price":1}]',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

      final gifts = await GiftRepository(dio).fetchCatalogV2();

      expect(captured?.path, ApiEndpoints.giftsTypes);
      expect(gifts.single.id, 'canlifal_1');
    });
  });
}

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
  ) {
    return responder(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
