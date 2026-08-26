import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live/data/datasources/live_fortune_request_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveFortuneRequestDataSource.fetchRequests', () {
    test('returns kılavuz list on success', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          return _jsonResponse(200, {
            'requests': [
              {'id': 'req_1', 'question': 'Soru', 'status': 'pending'},
            ],
          });
        }),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      final items = await ds.fetchRequests('s1');

      expect(items, hasLength(1));
      expect(items.single.id, 'req_1');
      expect(paths, [ApiEndpoints.videoStreamFortuneRequests('s1')]);
    });

    test('falls back then throws last error when both paths fail', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          return _jsonResponse(500, {'error': 'down'});
        }),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      await expectLater(
        ds.fetchRequests('s1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
      expect(paths, [
        ApiEndpoints.videoStreamFortuneRequests('s1'),
        ApiEndpoints.liveFalRequests,
      ]);
    });

    test('uses fallback list when kılavuz path fails', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          if (options.path == ApiEndpoints.videoStreamFortuneRequests('s1')) {
            return _jsonResponse(500, {'error': 'primary'});
          }
          return _jsonResponse(200, [
            {'id': 'req_fb', 'question': 'Yedek', 'status': 'pending'},
          ]);
        }),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      final items = await ds.fetchRequests('s1');

      expect(items.single.id, 'req_fb');
    });
  });

  group('LiveFortuneRequestDataSource.fetchMyStatus', () {
    test('returns body map on success', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          expect(
            options.path,
            ApiEndpoints.videoStreamFortuneMyStatus('s1'),
          );
          return _jsonResponse(200, {'status': 'pending'});
        }),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      final status = await ds.fetchMyStatus('s1');

      expect(status?['status'], 'pending');
    });

    test('treats 404 as no active request', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(404, {'error': 'none'})),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      expect(await ds.fetchMyStatus('s1'), isNull);
    });

    test('throws on 5xx so retry UI can run', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(503, {'error': 'busy'})),
      );
      final ds = LiveFortuneRequestDataSource(dio);

      await expectLater(
        ds.fetchMyStatus('s1'),
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
