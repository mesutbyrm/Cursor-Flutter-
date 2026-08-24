import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/bana_ozel/data/datasources/bana_ozel_remote_datasource.dart';
import 'package:canlifal_social/features/bana_ozel/domain/entities/bana_ozel_entities.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BanaOzelRemoteDataSource', () {
    test('fetchCatalog uses GET /api/bana-ozel', () async {
      RequestOptions? captured;
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          captured = options;
          await cancelFuture;
          return ResponseBody.fromString(
            '{"items":[],"jetonBalance":0,"streak":{},"todayTasks":[]}',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

      final catalog = await BanaOzelRemoteDataSource(dio).fetchCatalog();

      expect(captured?.method, 'GET');
      expect(captured?.path, ApiEndpoints.banaOzel);
      expect(catalog.items, isEmpty);
    });

    test('openItem posts slug body to /api/bana-ozel/open', () async {
      RequestOptions? captured;
      const item = BanaOzelItemEntity(
        id: '1',
        slug: 'sansli-sayilar',
        nameTr: 'Şanslı Sayılar',
        icon: '🍀',
        jetonCost: 2,
        category: 'fortune',
      );
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter((options, _, cancelFuture) async {
          captured = options;
          await cancelFuture;
          return ResponseBody.fromString(
            '{"content":"7, 14, 21","jetonSpent":2,"jetonBalance":8}',
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          );
        });

      final result = await BanaOzelRemoteDataSource(dio).openItem(item: item);

      expect(captured?.method, 'POST');
      expect(captured?.path, ApiEndpoints.banaOzelOpen);
      expect(captured?.data, {'slug': 'sansli-sayilar'});
      expect(result.content, contains('7'));
      expect(result.jetonBalance, 8);
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
