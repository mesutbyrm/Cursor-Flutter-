import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live/data/datasources/live_stream_extras_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveStreamExtrasDataSource.fetchPkBattle', () {
    test('returns kılavuz battle on success', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          if (options.path == ApiEndpoints.videoStreamPk) {
            return _jsonResponse(404, {'error': 'none'});
          }
          return _jsonResponse(200, {
            'id': 'pk_1',
            'status': 'pending',
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final battle = await ds.fetchPkBattle('s1');

      expect(battle?['id'], 'pk_1');
      expect(paths, [
        ApiEndpoints.videoStreamPk,
        ApiEndpoints.videoStreamPkBattle('s1'),
      ]);
    });

    test('treats 404 as no active PK', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(404, {'error': 'none'})),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      expect(await ds.fetchPkBattle('s1'), isNull);
    });

    test('throws on 5xx so host retry UI can run', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(503, {'error': 'busy'})),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      await expectLater(
        ds.fetchPkBattle('s1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });

  group('LiveStreamExtrasDataSource.pkAction create', () {
    test('returns kılavuz battle on success', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add('${options.method} ${options.path}');
          return _jsonResponse(200, {
            'id': 'pk_new',
            'status': 'pending',
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final battle = await ds.pkAction(
        streamId: 's1',
        action: 'create',
        targetStreamId: 's2',
      );

      expect(battle?['id'], 'pk_new');
      expect(paths, ['POST ${ApiEndpoints.videoStreamPk}']);
    });

    test('falls back to pk-battle when primary create fails', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          if (options.path == ApiEndpoints.videoStreamPk) {
            return _jsonResponse(500, {'error': 'primary'});
          }
          return _jsonResponse(200, {
            'id': 'pk_fb',
            'status': 'pending',
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final battle = await ds.pkAction(
        streamId: 's1',
        action: 'create',
        targetStreamId: 's2',
      );

      expect(battle?['id'], 'pk_fb');
      expect(paths, [
        ApiEndpoints.videoStreamPk,
        ApiEndpoints.videoStreamPkBattle('s1'),
      ]);
    });

    test('throws on 5xx so host PK create retry can run', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(503, {'error': 'busy'})),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      await expectLater(
        ds.pkAction(
          streamId: 's1',
          action: 'create',
          targetStreamId: 's2',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });
  });
}

Dio _dioWithAdapter(HttpClientAdapter adapter) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://canlifalapi.example.test',
      validateStatus: (status) => status != null && status >= 200 && status < 300,
    ),
  );
  dio.httpClientAdapter = adapter;
  return dio;
}

ResponseBody _jsonResponse(int status, Object body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

typedef _Responder = FutureOr<ResponseBody> Function(
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
  ) async {
    return responder(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
