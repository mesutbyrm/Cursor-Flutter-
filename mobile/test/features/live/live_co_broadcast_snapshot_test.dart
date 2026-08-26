import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/features/live/data/datasources/live_stream_extras_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveStreamExtrasDataSource.fetchCoBroadcastSnapshot', () {
    test('returns guest list when hosts or requests are present', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          return _jsonResponse(200, {
            'guests': [
              {'userId': 'u1', 'displayName': 'Ali'},
            ],
            'joinRequests': [
              {'userId': 'u2', 'displayName': 'Ayşe'},
            ],
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final snap = await ds.fetchCoBroadcastSnapshot('s1');

      expect(snap.coBroadcasters.single['userId'], 'u1');
      expect(snap.joinRequests.single['userId'], 'u2');
      expect(paths, [ApiEndpoints.liveGuestList]);
    });

    test('falls through to co-broadcast when guest list is empty', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          if (options.path == ApiEndpoints.liveGuestList) {
            return _jsonResponse(200, {'guests': <Object>[]});
          }
          return _jsonResponse(200, {
            'coBroadcasters': [
              {'userId': 'g1', 'displayName': 'Konuk'},
            ],
            'joinRequests': [
              {'userId': 'r1', 'displayName': 'İstek'},
            ],
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final snap = await ds.fetchCoBroadcastSnapshot('s1');

      expect(snap.coBroadcasters.single['userId'], 'g1');
      expect(snap.joinRequests.single['userId'], 'r1');
      expect(paths, [
        ApiEndpoints.liveGuestList,
        ApiEndpoints.videoStreamCoBroadcast('s1'),
      ]);
    });

    test('treats both 404s as empty snapshot', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(404, {'error': 'none'})),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final snap = await ds.fetchCoBroadcastSnapshot('s1');

      expect(snap.coBroadcasters, isEmpty);
      expect(snap.joinRequests, isEmpty);
    });

    test('throws guest-list 5xx when co-broadcast is 404', () async {
      final paths = <String>[];
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          paths.add(options.path);
          if (options.path == ApiEndpoints.liveGuestList) {
            return _jsonResponse(503, {'error': 'busy'});
          }
          return _jsonResponse(404, {'error': 'none'});
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      await expectLater(
        ds.fetchCoBroadcastSnapshot('s1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
      expect(paths, [
        ApiEndpoints.liveGuestList,
        ApiEndpoints.videoStreamCoBroadcast('s1'),
      ]);
    });

    test('throws on 5xx so host guests retry UI can run', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((_, _, _) => _jsonResponse(503, {'error': 'busy'})),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      await expectLater(
        ds.fetchCoBroadcastSnapshot('s1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 503),
        ),
      );
    });

    test('uses co-broadcast when guest list fails with 5xx', () async {
      final dio = _dioWithAdapter(
        _FakeAdapter((options, _, _) {
          if (options.path == ApiEndpoints.liveGuestList) {
            return _jsonResponse(500, {'error': 'primary'});
          }
          return _jsonResponse(200, {
            'guests': [
              {'userId': 'fb1', 'displayName': 'Yedek'},
            ],
          });
        }),
      );
      final ds = LiveStreamExtrasDataSource(dio);

      final snap = await ds.fetchCoBroadcastSnapshot('s1');

      expect(snap.coBroadcasters.single['userId'], 'fb1');
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
